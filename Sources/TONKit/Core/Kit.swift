//
//  Kit.swift
//  TONKit
//
//  Created by Sun on 2024/6/13.
//

import BigInt
import Combine
import Foundation
import GRDB
import SWCryptoKit
import SWExtensions
import SWToolKit
import TonAPI
import TonStreamingAPI
import TONSwift

// MARK: - Kit

public class Kit {
    // MARK: Properties

    private let address: Address
    
    private let apiListener: IApiListener
    private let accountManager: AccountManager
    private let jettonManager: JettonManager
    private let eventManager: EventManager
    private let transactionSender: TransactionSender?
    private let logger: Logger?
    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()
    
    // MARK: Lifecycle

    init(
        address: Address,
        apiListener: IApiListener,
        accountManager: AccountManager,
        jettonManager: JettonManager,
        eventManager: EventManager,
        transactionSender: TransactionSender?,
        logger: Logger?
    ) {
        self.address = address
        self.apiListener = apiListener
        self.accountManager = accountManager
        self.jettonManager = jettonManager
        self.eventManager = eventManager
        self.transactionSender = transactionSender
        self.logger = logger
        
        apiListener.transactionPublisher
            .sink { [weak self] in self?.handleNewEvent(id: $0) }
            .store(in: &cancellables)
    }
    
    // MARK: Functions

    private func handleNewEvent(id: String) {
        Task { [weak self] in
            for attempt in 1 ... 3 {
                try await Task.sleep(nanoseconds: 5000000000)
                
                if let existingEvent = self?.eventManager.event(id: id), !existingEvent.inProgress {
                    break
                }
                
                self?.logger?.debug("Event sync attempt \(attempt): \(id)")
                
                self?.sync()
            }
        }
        .store(in: &tasks)
    }
}

// Public API Extension

extension Kit {
    public var watchOnly: Bool {
        transactionSender == nil
    }
    
    public var syncState: SyncState {
        accountManager.syncState
    }
    
    public var syncStatePublisher: AnyPublisher<SyncState, Never> {
        accountManager.$syncState.eraseToAnyPublisher()
    }
    
    public var jettonSyncState: SyncState {
        jettonManager.syncState
    }
    
    public var jettonSyncStatePublisher: AnyPublisher<SyncState, Never> {
        jettonManager.$syncState.eraseToAnyPublisher()
    }
    
    public var eventSyncState: SyncState {
        eventManager.syncState
    }
    
    public var eventSyncStatePublisher: AnyPublisher<SyncState, Never> {
        eventManager.$syncState.eraseToAnyPublisher()
    }
    
    public var account: Account? {
        accountManager.account
    }
    
    public var accountPublisher: AnyPublisher<Account?, Never> {
        accountManager.$account.eraseToAnyPublisher()
    }
    
    public var jettonBalanceMap: [Address: JettonBalance] {
        jettonManager.jettonBalanceMap
    }
    
    public var jettonBalanceMapPublisher: AnyPublisher<[Address: JettonBalance], Never> {
        jettonManager.$jettonBalanceMap.eraseToAnyPublisher()
    }
    
    public var receiveAddress: Address {
        address
    }
    
    public func events(tagQuery: TagQuery, beforeLt: Int64? = nil, limit: Int? = nil) -> [Event] {
        eventManager.events(tagQuery: tagQuery, beforeLt: beforeLt, limit: limit)
    }
    
    public func eventPublisher(tagQuery: TagQuery) -> AnyPublisher<EventInfo, Never> {
        eventManager.eventPublisher(tagQuery: tagQuery)
    }
    
    public func tagTokens() -> [TagToken] {
        eventManager.tagTokens()
    }
    
    public func estimateFee(recipient: FriendlyAddress, amount: SendAmount, comment: String?) async throws -> BigUInt {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }
        
        return try await transactionSender.estimateFee(recipient: recipient, amount: amount, comment: comment)
    }
    
    public func estimateFee(
        jettonWallet: Address,
        recipient: FriendlyAddress,
        amount: BigUInt,
        comment: String?
    ) async throws
        -> BigUInt {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }
        
        return try await transactionSender.estimateFee(
            jettonWallet: jettonWallet,
            recipient: recipient,
            amount: amount,
            comment: comment
        )
    }
    
    public func send(recipient: FriendlyAddress, amount: SendAmount, comment: String?) async throws {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }
        
        return try await transactionSender.send(recipient: recipient, amount: amount, comment: comment)
    }
    
    public func send(
        jettonWallet: Address,
        recipient: FriendlyAddress,
        amount: BigUInt,
        comment: String?
    ) async throws {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }
        
        return try await transactionSender.send(
            jettonWallet: jettonWallet,
            recipient: recipient,
            amount: amount,
            comment: comment
        )
    }
    
    public func startListener() {
        apiListener.start(address: address)
    }
    
    public func stopListener() {
        apiListener.stop()
    }
    
    public func sync() {
        accountManager.sync()
        jettonManager.sync()
        eventManager.sync()
    }
    
    public static func validate(address: String) throws {
        _ = try Address.parse(address)
    }
}

extension Kit {
    public static func clear(exceptFor excludedFiles: [String]) throws {
        let fileManager = FileManager.default
        let fileURLs = try fileManager.contentsOfDirectory(at: dataDirectoryURL(), includingPropertiesForKeys: nil)
        
        for filename in fileURLs {
            if !excludedFiles.contains(where: { filename.lastPathComponent.contains($0) }) {
                try fileManager.removeItem(at: filename)
            }
        }
    }
    
    public static func instance(
        type: WalletType,
        walletVersion: WalletVersion = .v4,
        network: Network = .mainNet,
        walletID: String,
        minLogLevel: Logger.Level = .error
    ) throws
        -> Kit {
        let logger = Logger(minLogLevel: minLogLevel)
        let uniqueID = "\(walletID)-\(network.rawValue)"
        
        // let reachabilityManager = ReachabilityManager()
        let databaseURL = try dataDirectoryURL().appendingPathComponent("ton-\(uniqueID).sqlite")
        
        let dbPool = try DatabasePool(path: databaseURL.path)
        
        let api = api(network: network)
        
        let address: Address
        var transactionSender: TransactionSender?
        
        switch type {
        case let .full(keyPair):
            let walletContract: WalletContract
            
            switch walletVersion {
            case .v3:
                fatalError() // todo
            case .v4:
                walletContract = WalletV4R2(publicKey: keyPair.publicKey.data)
            case .v5:
                fatalError() // todo
            }
            
            address = try walletContract.address()
            transactionSender = TransactionSender(
                api: api,
                contract: walletContract,
                sender: address,
                secretKey: keyPair.privateKey.data
            )

        case let .watch(_address):
            address = _address
        }
        
        let apiListener: IApiListener = TonApiListener(network: network, logger: logger)
        
        let accountStorage = try AccountStorage(dbPool: dbPool)
        let accountManager = AccountManager(address: address, api: api, storage: accountStorage, logger: logger)
        
        let jettonStorage = try JettonStorage(dbPool: dbPool)
        let jettontManager = JettonManager(address: address, api: api, storage: jettonStorage, logger: logger)
        
        let eventStorage = try EventStorage(dbPool: dbPool)
        let eventManager = EventManager(address: address, api: api, storage: eventStorage, logger: logger)
        
        return Kit(
            address: address,
            apiListener: apiListener,
            accountManager: accountManager,
            jettonManager: jettontManager,
            eventManager: eventManager,
            transactionSender: transactionSender,
            logger: logger
        )
    }
    
    public static func jetton(network: Network = .mainNet, address: Address) async throws -> Jetton {
        try await api(network: network).getJettonInfo(address: address)
    }
    
    private static func api(network: Network) -> IApi {
        TonApi(network: network)
    }
    
    private static func dataDirectoryURL() throws -> URL {
        let fileManager = FileManager.default
        
        let url = try fileManager
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ton-kit", isDirectory: true)
        
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        
        return url
    }
}

extension Kit {
    public enum WalletType {
        case full(KeyPair)
        case watch(Address)
    }
    
    public enum WalletVersion {
        case v3
        case v4
        case v5
    }
    
    public enum SyncError: Error {
        case notStarted
    }
    
    public enum WalletError: Error {
        case watchOnly
    }
    
    public enum SendAmount {
        case amount(value: BigUInt)
        case max
    }
}
