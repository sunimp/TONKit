//
//  Kit.swift
//
//  Created by Sun on 2024/6/13.
//

import Combine
import Foundation

import BigInt
import Foundation
import HDWalletKit
import TonAPI
import TonStreamingAPI
import TonSwift
import WWCryptoKit
import WWToolKit

// MARK: - Kit

public class Kit {
    // MARK: Static Properties

    static let tonID = "TON"

    // MARK: Properties

    public let address: Address
    public let network: Network
    public let uniqueID: String
    public let logger: Logger?
    
    @Published
    public var updateState = "idle"

    var cancellables = Set<AnyCancellable>()

    private let syncer: Syncer
    private let accountInfoManager: AccountInfoManager
    private let transactionManager: TransactionManager
    private let transactionSender: TransactionSender?

    // MARK: Lifecycle

    init(
        address: Address,
        network: Network,
        uniqueID: String,
        syncer: Syncer,
        accountInfoManager: AccountInfoManager,
        transactionManager: TransactionManager,
        transactionSender: TransactionSender?,
        logger: Logger?
    ) {
        self.address = address
        self.network = network
        self.uniqueID = uniqueID
        self.syncer = syncer
        self.accountInfoManager = accountInfoManager
        self.transactionManager = transactionManager
        self.transactionSender = transactionSender
        self.logger = logger
        
        syncer.$updateState.sink { [weak self] state in
            self?.updateState = state
        }.store(in: &cancellables)
    }

    // MARK: Static Functions

    static func jettonID(address: String) -> String { "TON/\(address)" }
    static func address(jettonID: String) -> String { String(jettonID.dropFirst(4)) }
}

// Public API Extension

extension Kit {
    public var watchOnly: Bool {
        transactionSender == nil
    }

    public var syncState: SyncState {
        syncer.state
    }

    public var balance: BigUInt {
        accountInfoManager.tonBalance
    }

    public func jettonBalance(address: Address) -> BigUInt {
        accountInfoManager.jettonBalance(address: address)
    }

    public func jettonBalancePublisher(address: Address) -> AnyPublisher<BigUInt, Never> {
        accountInfoManager.jettonBalancePublisher(address: address)
    }

    public var receiveAddress: Address {
        address
    }
    
    public var jettons: [Jetton] {
        accountInfoManager.jettons
    }

    public var syncStatePublisher: AnyPublisher<SyncState, Never> {
        syncer.$state.eraseToAnyPublisher()
    }

    public var tonBalancePublisher: AnyPublisher<BigUInt, Never> {
        accountInfoManager.tonBalancePublisher
    }

    public func transactionsPublisher(tagQueries: [TransactionTagQuery]?) -> AnyPublisher<[FullTransaction], Never> {
        transactionManager.fullTransactionsPublisher(tagQueries: tagQueries)
    }

    public func transactions(
        tagQueries: [TransactionTagQuery],
        beforeLt: Int64? = nil,
        limit: Int? = nil
    )
        -> [FullTransaction] {
        transactionManager.fullTransactions(tagQueries: tagQueries, beforeLt: beforeLt, limit: limit)
    }

    public func estimateFee(
        recipient: String,
        jetton: Jetton? = nil,
        amount: BigUInt,
        comment: String?
    ) async throws
        -> Decimal {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }
        let address = try FriendlyAddress(string: recipient)
        let amount = Amount(value: amount, isMax: amount == balance)

        return try await transactionSender.estimatedFee(
            recipient: address,
            jetton: jetton,
            amount: amount,
            comment: comment
        )
    }

    public func send(recipient: String, jetton: Jetton? = nil, amount: BigUInt, comment: String?) async throws {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }

        let address = try FriendlyAddress(string: recipient)
        let amount = Amount(value: amount, isMax: amount == balance)

        return try await transactionSender.sendTransaction(
            recipient: address,
            jetton: jetton,
            amount: amount,
            comment: comment
        )
    }

    public func start() {
        syncer.start()
    }

    public func stop() {
        syncer.stop()
    }

    public func refresh() {
        syncer.refresh()
    }

    public func fetchTransaction(eventID _: String) async throws -> FullTransaction {
        throw SyncError.notStarted
    }
    
    public static func validate(address: String) throws {
        _ = try FriendlyAddress(string: address)
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
        network: Network,
        walletID: String,
        apiKey _: String?,
        logger: Logger?
    ) throws
        -> Kit {
        let uniqueID = "\(walletID)-\(network.rawValue)"

        let reachabilityManager = ReachabilityManager()
        let databaseDirectoryURL = try dataDirectoryURL()
        let syncerStorage = SyncerStorage(
            databaseDirectoryURL: databaseDirectoryURL,
            databaseFileName: "syncer-state-storage-\(uniqueID)"
        )
        let accountInfoStorage = AccountInfoStorage(
            databaseDirectoryURL: databaseDirectoryURL,
            databaseFileName: "account-info-storage-\(uniqueID)"
        )
        let transactionStorage = AccountEventStorage(
            databaseDirectoryURL: databaseDirectoryURL,
            databaseFileName: "account-events-storage-\(uniqueID)"
        )

        let address = try type.address()
        let decorationManager = DecorationManager(userAddress: address)

        let serverURL = URL(string: "https://tonapi.io")!
        var transport = TonTransport()
        
        let urlSession = URLSession(configuration: transport.urlSessionConfiguration)
        let api = TonApi(urlSession: urlSession, url: serverURL)

        let accountInfoManager = AccountInfoManager(storage: accountInfoStorage)
        let transactionManager = TransactionManager(
            userAddress: address,
            storage: transactionStorage,
            decorationManager: decorationManager
        )

        let streamingTonAPIClient = TonStreamingAPI.Client(
            serverURL: serverURL,
            transport: transport.streamingTransport,
            middlewares: []
        )
        let backgroundUpdateStore = BackgroundUpdateStore(streamingAPI: streamingTonAPIClient, logger: logger)

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
            address: address, network: network, uniqueID: uniqueID,
            syncer: syncer,
            accountInfoManager: accountInfoManager,
            transactionManager: transactionManager,
            transactionSender: transactionSender,
            logger: logger
        )

        let transferDecorator = TransferDecorator(address: address)
        transferDecorator.decorations.append(IncomingDecoration.self)
        transferDecorator.decorations.append(OutgoingDecoration.self)
        transferDecorator.decorations.append(IncomingJettonDecoration.self)
        transferDecorator.decorations.append(OutgoingJettonDecoration.self)

        decorationManager.add(transactionDecorator: transferDecorator)

        return kit
    }

    private static func dataDirectoryURL() throws -> URL {
        let fileManager = FileManager.default

        let url = try fileManager
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ton-api-kit", isDirectory: true)

        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        return url
    }

    private static func providerURL(network: Network) -> String {
        switch network {
        case .mainNet: return "https://tonapi.io/"
        case .testNet: return "https://testnet.tonapi.io/"
        }
    }
}

extension Kit {
    public enum WalletType {
        case full(KeyPair)
        case watch(Address)

        // MARK: Computed Properties

        var keyPair: KeyPair? {
            switch self {
            case let .full(keyPair): return keyPair
            case .watch: return nil
            }
        }

        // MARK: Functions

        func address() throws -> Address {
            switch self {
            case let .watch(address): return address
            case let .full(keyPair):
                let wallet = WalletV4R2(publicKey: keyPair.publicKey.data)
                return try wallet.address()
            }
        }
    }

    public enum SyncError: Error {
        case notStarted
        case noNetworkConnection
        case disconnected
    }

    public enum KitError: Error {
        case parsingError
        case custom(String)
    }

    public enum WalletError: Error {
        case watchOnly
    }
}
