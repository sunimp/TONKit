import BigInt
import Combine
import Foundation
import HdWalletKit
import HsCryptoKit
import HsToolKit
import TonAPI
import TonStreamingAPI
import TonSwift

public class Kit {
    var cancellables = Set<AnyCancellable>()
    
    private let syncer: Syncer
    private let accountInfoManager: AccountInfoManager
    private let transactionManager: TransactionManager
    private let transactionSender: TransactionSender?

    public let address: Address
    public let network: Network
    public let uniqueId: String
    public let logger: Logger
    
    @Published public var updateState: String  = "idle"

    init(address: Address, network: Network, uniqueId: String,
         syncer: Syncer,
         accountInfoManager: AccountInfoManager,
         transactionManager: TransactionManager,
         transactionSender: TransactionSender?,
         logger: Logger)
    {
        self.address = address
        self.network = network
        self.uniqueId = uniqueId
        self.syncer = syncer
        self.accountInfoManager = accountInfoManager
        self.transactionManager = transactionManager
        self.transactionSender = transactionSender
        self.logger = logger
        
        syncer.$updateState.sink { [weak self] state in
            self?.updateState = state
        }.store(in: &cancellables)
    }
}

// Public API Extension

public extension Kit {
    var watchOnly: Bool {
        transactionSender == nil
    }

    var syncState: SyncState {
        syncer.state
    }

    var balance: BigUInt {
        accountInfoManager.tonBalance
    }

    var receiveAddress: Address {
        address
    }

    var syncStatePublisher: AnyPublisher<SyncState, Never> {
        syncer.$state.eraseToAnyPublisher()
    }

    var tonBalancePublisher: AnyPublisher<BigUInt, Never> {
        accountInfoManager.tonBalancePublisher
    }

    func transactionsPublisher(tagQueries: [TransactionTagQuery]) -> AnyPublisher<[FullTransaction], Never> {
        transactionManager.fullTransactionsPublisher(tagQueries: tagQueries)
    }

    func transactions(tagQueries: [TransactionTagQuery], beforeLt: Int64? = nil, limit: Int? = nil) -> [FullTransaction] {
        transactionManager.fullTransactions(tagQueries: tagQueries, beforeLt: beforeLt, limit: limit)
    }

    func estimateFee(recipient: String, amount: Decimal, comment: String?) async throws -> Decimal {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }
        let address = try FriendlyAddress(string: recipient)
        let value = BigUInt(amount.description) ?? 0
        let amount = Amount(value: value, isMax: value == balance)

        return try await transactionSender.estimatedFee(recipient: address, amount: amount, comment: comment)
    }

    func send(recipient: String, amount: Decimal, comment: String?) async throws {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }

        let address = try FriendlyAddress(string: recipient)
        let value = BigUInt(amount.description) ?? 0
        
        let amount = Amount(value: value, isMax: value == balance)

        return try await transactionSender.sendTransaction(recipient: address, amount: amount, comment: comment)
    }

    func start() {
        syncer.start()
    }

    func stop() {
        syncer.stop()
    }

    func refresh() {
        syncer.refresh()
    }

    func fetchTransaction(eventId _: String) async throws -> FullTransaction {
        throw SyncError.notStarted
    }
    
    static func validate(address: String) throws {
        _ = try FriendlyAddress(string: address)
    }
}

extension Kit {
    public static func clear(exceptFor excludedFiles: [String]) throws {
        let fileManager = FileManager.default
        let fileUrls = try fileManager.contentsOfDirectory(at: dataDirectoryUrl(), includingPropertiesForKeys: nil)

        for filename in fileUrls {
            if !excludedFiles.contains(where: { filename.lastPathComponent.contains($0) }) {
                try fileManager.removeItem(at: filename)
            }
        }
    }

    public static func instance(type: WalletType, network: Network, walletId: String, apiKey _: String?, minLogLevel: Logger.Level = .error) throws -> Kit {
        let logger = Logger(minLogLevel: minLogLevel)
        let uniqueId = "\(walletId)-\(network.rawValue)"

        let reachabilityManager = ReachabilityManager()
        let databaseDirectoryUrl = try dataDirectoryUrl()
        let syncerStorage = SyncerStorage(databaseDirectoryUrl: databaseDirectoryUrl, databaseFileName: "syncer-state-storage-\(uniqueId)")
        let accountInfoStorage = AccountInfoStorage(databaseDirectoryUrl: databaseDirectoryUrl, databaseFileName: "account-info-storage-\(uniqueId)")
        let transactionStorage = AccountEventStorage(databaseDirectoryUrl: databaseDirectoryUrl, databaseFileName: "account-events-storage-\(uniqueId)")

        let address = try type.address()
        let decorationManager = DecorationManager(userAddress: address)

        let serverUrl = URL(string: "https://tonapi.io")!
        var transport = TonTransport()
        let apiClient = TonAPI.Client(serverURL: serverUrl, transport: transport.transport, middlewares: [])
        let urlSession = URLSession(configuration: transport.urlSessionConfiguration)
        let api = TonApi(tonAPIClient: apiClient, urlSession: urlSession, url: serverUrl)

        let accountInfoManager = AccountInfoManager(storage: accountInfoStorage)
        let transactionManager = TransactionManager(
            userAddress: address,
            storage: transactionStorage,
            decorationManager: decorationManager
        )

        let streamingTonAPIClient = TonStreamingAPI.Client(serverURL: serverUrl, transport: transport.streamingTransport, middlewares: [])
        let backgroundUpdateStore = BackgroundUpdateStore(streamingAPI: streamingTonAPIClient)

        let syncer = Syncer(
            accountInfoManager: accountInfoManager,
            transactionManager: transactionManager,
            reachabilityManager: reachabilityManager,
            api: api,
            backgroundUpdateStore: backgroundUpdateStore,
            storage: syncerStorage,
            address: address,
            logger: logger
        )

        let transactionSender = try type.keyPair.map { keyPair in
            let wallet = WalletV4R2(publicKey: keyPair.publicKey.data)
            let address = try wallet.address()

            return TransactionSender(api: api, contract: wallet, sender: address, secretKey: keyPair.privateKey.data)
        }

        let kit = Kit(
            address: address, network: network, uniqueId: uniqueId,
            syncer: syncer,
            accountInfoManager: accountInfoManager,
            transactionManager: transactionManager,
            transactionSender: transactionSender,
            logger: logger
        )

        decorationManager.add(transactionDecorator: TonTransferDecorator(address: address))

        return kit
    }

    private static func dataDirectoryUrl() throws -> URL {
        let fileManager = FileManager.default

        let url = try fileManager
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ton-api-kit", isDirectory: true)

        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        return url
    }

    private static func providerUrl(network: Network) -> String {
        switch network {
        case .mainNet: return "https://tonapi.io/"
        case .testNet: return "https://testnet.tonapi.io/"
        }
    }
}

public extension Kit {
    enum WalletType {
        case full(KeyPair)
        case watch(Address)

        func address() throws -> Address {
            switch self {
            case let .watch(address): return address
            case let .full(keyPair):
                let wallet = WalletV4R2(publicKey: keyPair.publicKey.data)
                return try wallet.address()
            }
        }

        var keyPair: KeyPair? {
            switch self {
            case let .full(keyPair): return keyPair
            case .watch: return nil
            }
        }
    }

    enum SyncError: Error {
        case notStarted
        case noNetworkConnection
    }

    enum KitError: Error {
        case custom(String)
    }

    enum WalletError: Error {
        case watchOnly
    }
}
