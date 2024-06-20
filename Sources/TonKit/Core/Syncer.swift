import Foundation
import HsExtensions
import TonSwift
import HsToolKit
import Combine

class Syncer {
    private static let avoidDoubleSyncInterval: TimeInterval = 3
    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()
    private static let limitCount = 100

    private let accountInfoManager: AccountInfoManager
    private let transactionManager: TransactionManager
    private let reachabilityManager: ReachabilityManager

    private let api: TonApi

    private var backgroundUpdateStoreObservationToken: ObservationToken?
    private let backgroundUpdateStore: BackgroundUpdateStore

    private let storage: SyncerStorage
    private let address: Address

    private var logger: Logger?
    
    private var lastSynced: TimeInterval = 0
    private var syncing: Bool = false

    
    @Published public var updateState: String = "Idle"

    @DistinctPublished private(set) var state: SyncState = .notSynced(error: Kit.SyncError.notStarted)

    deinit {
        backgroundUpdateStoreObservationToken?.cancel()
        Task {
            await stopBackgroundUpdate()
        }
    }

    init(accountInfoManager: AccountInfoManager,
         transactionManager: TransactionManager,
         reachabilityManager: ReachabilityManager,
         api: TonApi,
         backgroundUpdateStore: BackgroundUpdateStore,
         storage: SyncerStorage,
         address: Address,
         logger: Logger?) {
        self.accountInfoManager = accountInfoManager
        self.transactionManager = transactionManager
        self.reachabilityManager = reachabilityManager
        self.api = api
        self.backgroundUpdateStore = backgroundUpdateStore
        self.storage = storage
        self.address = address
        self.logger = logger
        
        reachabilityManager.$isReachable
            .sink { [weak self] isReachable in
                self?.handle(isReachable: isReachable)
            }
            .store(in: &cancellables)
    }
    
    private func handle(isReachable: Bool) {
        logger?.log(level: .debug, message: "Handle reachable \(isReachable)")
        if isReachable {
            Task { [weak self] in
               await self?.startBackgroundUpdate()
            }
        }
    }

    private func set(state: SyncState) {
        self.state = state
 
        switch state {
        case .syncing: syncing = true
        case .notSynced: syncing = false
        case .synced:
            syncing = false
            lastSynced = Date().timeIntervalSince1970
        }
    }
}

extension Syncer {
    private func subscribeUpdates() async {
        _ = await backgroundUpdateStore.addEventObserver(self) { [weak self] observer, state in
            switch state {
            case let .didUpdateState(backgroundUpdateState):
                switch backgroundUpdateState {
                case .connected:
                    Task { [weak self] in
                        self?.logger?.log(level: .debug, message: "Try Update from connected background Update")
                        await observer.update(forced: false)
                    }
                case .noConnection:
                    Task { [weak self] in
                        self?.logger?.log(level: .error, message: "Stream has no connection")
                        self?.set(state: .notSynced(error: Kit.SyncError.noNetworkConnection))
                    }
                case .disconnected:
                    Task { [weak self] in
                        self?.logger?.log(level: .error, message: "Strean has disconnected")
                        self?.set(state: .notSynced(error: Kit.SyncError.disconnected))
                    }
                default: break
                }
            case let .didReceiveUpdateEvent(backgroundUpdateEvent):
                Task { [weak self] in
                    guard backgroundUpdateEvent.accountAddress == self?.address else { return }
                    self?.logger?.log(level: .debug, message: "Try Update from event background Update")
                    await observer.update(forced: true)
                }
            }
        }
        await startBackgroundUpdate()
    }

    public func update(forced: Bool) async {
        // avoid double syncing when background streaming connected to api
        if !forced, Date().timeIntervalSince1970 < lastSynced + Self.avoidDoubleSyncInterval {
            logger?.log(level: .debug, message: "Avoid Connected state (too often)")
            return
        }

        logger?.log(level: .debug, message: "Sync from background update!")
        sync()
    }

    public func startBackgroundUpdate() async {
        await backgroundUpdateStore.start(addresses: [address])
    }

    public func stopBackgroundUpdate() async {
        Task { [weak self] in
            await self?.backgroundUpdateStore.stop()
        }
    }
}

extension Syncer {
    func start() {
        Task {
            await subscribeUpdates()
        }
        sync()
    }

    func stop() {
        Task {
            await stopBackgroundUpdate()
        }
    }

    func refresh() {
        // avoid double too often refreshing
        if Date().timeIntervalSince1970 < lastSynced + Self.avoidDoubleSyncInterval {
            return
        }

        sync()
    }
}

extension Syncer: ISyncTimerDelegate {
    private func checkNewTransactions(before: AccountEventRecord, jettonInfo: JettonInfo? = nil) async throws {
        var completed = false

        var startTime = Int64(before.timestamp)
        repeat {
            let newActions: AccountEvents
            if let jettonInfo {
                newActions = try await api.getAccountJettonEvents(address: address, jettonInfo: jettonInfo, beforeLt: nil, limit: Syncer.limitCount, start: startTime + 1)
            } else {
                newActions = try await api.getAccountEvents(address: address, beforeLt: nil, limit: Syncer.limitCount, start: startTime + 1)
            }
            
            logger?.log(level: .debug, message: "==> Get new actions: \(newActions.events.count)")
            logger?.log(level: .debug, message: "From = \(newActions.startFrom)")

            guard let last = newActions.events.first else {
                completed = true
                logger?.log(level: .debug, message: "=> NO ONE new TX")
                continue
            }

            if transactionManager.event(address: address, eventId: last.eventId) != nil {
                // fetched already existed transactions
                completed = true
                logger?.log(level: .debug, message: "=> parsed already exist txs")
                continue
            }
            
            transactionManager.handle(events: newActions.events)
            startTime = Int64(last.timestamp)
        } while !completed
    }

    func didUpdate(state: SyncTimer.State) {
        switch state {
        case .ready:
            set(state: .syncing(progress: nil))
            sync()
        case let .notReady(error):
            tasks = Set()
            set(state: .notSynced(error: error))
        }
    }
    
    private func events(jettonInfo: JettonInfo?, beforeLt: Int64?, limit: Int) async throws -> AccountEvents {
        guard let jettonInfo else {
            return try await api.getAccountEvents(address: address, beforeLt: beforeLt, limit: limit)
        }
        
        return try await api.getAccountJettonEvents(address: address, jettonInfo: jettonInfo, beforeLt: beforeLt, limit: limit)
    }

    private func getTransactions(jettonInfo: JettonInfo? = nil) async throws {
        logger?.log(level: .debug, message: "==> Get History for: \(jettonInfo?.address.toRaw() ?? "TON")")

        if let newest = transactionManager.newestEvent(jettonAddressUid: jettonInfo?.address.toRaw()) { // todo: implement related on jettonAddress or tonAddress
            logger?.log(level: .debug, message: "=> has newest: lt = \(newest.lt) | timestamp = \(newest.timestamp.description)")
//             2. If we has last -> get all new transaction from now to last timestamp.
            logger?.log(level: .debug, message: "=> Try to check new txs:")
            try await checkNewTransactions(before: newest, jettonInfo: jettonInfo)
            logger?.log(level: .debug, message: "successful checked")
        }
        
        // 3. Check if api was already parse all transaction from history

        if let initialSyncCompleted = storage.initialSyncCompleted(api: api.url.absoluteString), initialSyncCompleted {
            logger?.log(level: .debug, message: "-> Initial sync was completed. Nothing to sync")
            set(state: .synced)
            return
        }

        // 4. Get all history step by step from oldest tx.
        // 4.1 get oldest transaction

        logger?.log(level: .debug, message: "-> Initial sync not completed")
        let oldest = transactionManager.oldestEvent(jettonAddressUid: jettonInfo?.address.toRaw())
        var beforeLt = oldest?.lt
        var completed = false

        // 4.2 Get list of history and save. Repeat before last list have less than limit transactions.
        repeat {
            logger?.log(level: .debug, message: "==> Ask new for: \(beforeLt ?? -1)")

            var fetchResult: AccountEvents
            if let jettonInfo {
                fetchResult = try await api.getAccountJettonEvents(address: address, jettonInfo: jettonInfo, beforeLt: beforeLt, limit: Syncer.limitCount)
            } else {
                fetchResult = try await api.getAccountEvents(address: address, beforeLt: beforeLt, limit: Syncer.limitCount)
            }
            

            logger?.log(level: .debug, message: "==> Get new actions: \(fetchResult.events.count)")
//            for event in fetchResult.events {
//                logger?.log(level: .debug, message: "==> ==> Event: \(event.eventId) | \(event.lt) actions: \(event.actions.count)")
//            }
            logger?.log(level: .debug, message: "From = \(fetchResult.startFrom) : to = \(fetchResult.nextFrom)")
            transactionManager.handle(events: fetchResult.events)

            beforeLt = fetchResult.nextFrom

            if fetchResult.events.count == 0 {
                let id = jettonInfo.map { Kit.jettonId(address: $0.address.toRaw()) } ?? Kit.tonId
                storage.save(api: api.url.absoluteString, id: id, initialSyncCompleted: true)
                logger?.log(level: .debug, message: "Full sync Completed")
                completed = true
            }
        } while !completed
    }

    func sync() {
        logger?.log(level: .debug, message: "=> TRY SYNC")
        guard !syncing else {
            logger?.log(level: .debug, message: "=> Already syncing")
            return
        }

        set(state: .syncing(progress: nil))

        Task { [weak self, api, address, accountInfoManager] in
            do {

                // 0. Get balance
                self?.logger?.log(level: .debug, message: "-> Try get balance")
                let account = try await api.getAccountInfo(address: address)
                self?.logger?.log(level: .debug, message: "-> Got Balance : \(account.balance.description)")
                accountInfoManager.handle(account: account)
                
                // 0.1. Get jettons balances
                self?.logger?.log(level: .debug, message: "-> Try get jettons balances")
                let balances = try await api.getAccountJettonsBalances(address: address, currencies: ["ton"])
                self?.logger?.log(level: .debug, message: "-> Got Jetton Balances :")
                for balance in balances {
                    self?.logger?.log(level: .debug, message: "-> \(balance.item.jettonInfo.address.toRaw()) : \(balance.quantity.description)")
                }
                accountInfoManager.handle(jettonBalances: balances)
                
                // 1. Get ton transactions
                try await self?.getTransactions()
//                // 1.1. Get jettons transactions
//                let infos = balances.map { $0.item.jettonInfo }
//                for jettonInfo in infos {
//                    try await self?.getTransactions(jettonInfo: jettonInfo)
//                }
                self?.set(state: .synced)
            } catch {
                self?.logger?.log(level: .error, message: "REQUEST ERROR: \(error)")
                self?.set(state: .notSynced(error: error))
            }
        }.store(in: &tasks)
    }
    
}
