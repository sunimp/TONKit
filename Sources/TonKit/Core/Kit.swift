//
//  Kit.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
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
    static let tonId = "TON"

    static func jettonId(address: String) -> String { "TON/\(address)" }
    static func address(jettonId: String) -> String { String(jettonId.dropFirst(4)) }

    var cancellables = Set<AnyCancellable>()
    
    private let syncer: Syncer
    private let accountInfoManager: AccountInfoManager
    private let transactionManager: TransactionManager
    private let transactionSender: TransactionSender?

    public let address: Address
    public let network: Network
    public let uniqueId: String
    public let logger: Logger?
    
    @Published
    public var updateState = "idle"

    init(
        address: Address,
        network: Network,
        uniqueId: String,
        syncer: Syncer,
        accountInfoManager: AccountInfoManager,
        transactionManager: TransactionManager,
        transactionSender: TransactionSender?,
        logger: Logger?
    ) {
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

    public func transactions(tagQueries: [TransactionTagQuery], beforeLt: Int64? = nil, limit: Int? = nil) -> [FullTransaction] {
        transactionManager.fullTransactions(tagQueries: tagQueries, beforeLt: beforeLt, limit: limit)
    }

    public func estimateFee(recipient: String, jetton: Jetton? = nil, amount: BigUInt, comment: String?) async throws -> Decimal {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }
        let address = try FriendlyAddress(string: recipient)
        let amount = Amount(value: amount, isMax: amount == balance)

        return try await transactionSender.estimatedFee(recipient: address, jetton: jetton, amount: amount, comment: comment)
    }

    public func send(recipient: String, jetton: Jetton? = nil, amount: BigUInt, comment: String?) async throws {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }

        let address = try FriendlyAddress(string: recipient)
        let amount = Amount(value: amount, isMax: amount == balance)

        return try await transactionSender.sendTransaction(recipient: address, jetton: jetton, amount: amount, comment: comment)
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

    public func fetchTransaction(eventId _: String) async throws -> FullTransaction {
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
        walletId: String,
        apiKey _: String?,
        logger: Logger?
    ) throws -> Kit {
        let uniqueId = "\(walletId)-\(network.rawValue)"

        let reachabilityManager = ReachabilityManager()
        let databaseDirectoryURL = try dataDirectoryURL()
        let syncerStorage = SyncerStorage(
            databaseDirectoryURL: databaseDirectoryURL,
            databaseFileName: "syncer-state-storage-\(uniqueId)"
        )
        let accountInfoStorage = AccountInfoStorage(
            databaseDirectoryURL: databaseDirectoryURL,
            databaseFileName: "account-info-storage-\(uniqueId)"
        )
        let transactionStorage = AccountEventStorage(
            databaseDirectoryURL: databaseDirectoryURL,
            databaseFileName: "account-events-storage-\(uniqueId)"
        )

        let address = try type.address()
        let decorationManager = DecorationManager(userAddress: address)

        let serverURL = URL(string: "https://tonapi.io")!
        var transport = TonTransport()
        let apiClient = Client(serverURL: serverURL, transport: transport.transport, middlewares: [])
        let urlSession = URLSession(configuration: transport.urlSessionConfiguration)
        let api = TonApi(tonAPIClient: apiClient, urlSession: urlSession, url: serverURL)

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
            address: address, network: network, uniqueId: uniqueId,
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

        func address() throws -> Address {
            switch self {
            case .watch(let address): return address
            case .full(let keyPair):
                let wallet = WalletV4R2(publicKey: keyPair.publicKey.data)
                return try wallet.address()
            }
        }

        var keyPair: KeyPair? {
            switch self {
            case .full(let keyPair): return keyPair
            case .watch: return nil
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
