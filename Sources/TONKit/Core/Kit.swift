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
        logger: Logger?
    ) {
        self.address = address
        self.apiListener = apiListener
        self.accountManager = accountManager
        self.jettonManager = jettonManager
        self.eventManager = eventManager
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

    public func transferData(recipient: FriendlyAddress, amount: SendAmount, comment: String?) throws -> TransferData {
        let value: BigUInt
        let isMax: Bool

        switch amount {
        case let .amount(_value):
            value = _value
            isMax = false

        case .max:
            value = 0
            isMax = true
        }

        let internalMessage: MessageRelaxed =
            if let comment {
                try MessageRelaxed.internal(
                    to: recipient.address,
                    value: value.magnitude,
                    bounce: recipient.isBounceable,
                    textPayload: comment
                )
            } else {
                MessageRelaxed.internal(
                    to: recipient.address,
                    value: value.magnitude,
                    bounce: recipient.isBounceable
                )
            }

        return TransferData(
            sender: address,
            sendMode: isMax ? .sendMaxTon() : .walletDefault(),
            internalMessages: [internalMessage]
        )
    }

    public func transferData(
        jettonAddress: Address,
        recipient: FriendlyAddress,
        amount: BigUInt,
        comment: String?
    ) throws
        -> TransferData {
        guard let jettonBalance = jettonBalanceMap[jettonAddress] else {
            throw WalletError.noJettonWallet
        }

        let internalMessage = try JettonTransferMessage.internalMessage(
            jettonAddress: jettonBalance.walletAddress,
            amount: BigInt(amount),
            bounce: recipient.isBounceable,
            to: recipient.address,
            from: address,
            comment: comment
        )

        return TransferData(
            sender: address,
            sendMode: .walletDefault(),
            internalMessages: [internalMessage]
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
        address: Address,
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
            logger: logger
        )
    }

    public static func jetton(network: Network = .mainNet, address: Address) async throws -> Jetton {
        try await api(network: network).getJettonInfo(address: address)
    }

    public static func transferData(sender: Address, payloads: [Payload]) throws -> TransferData {
        let internalMessages = try payloads.map { payload in
            var stateInit: TONSwift.StateInit?

            if let stateInitString = payload.stateInit {
                stateInit = try StateInit.loadFrom(slice: Cell.fromBase64(src: stateInitString).toSlice())
            }

            var body: Cell = .empty

            if let messagePayload = payload.payload {
                body = try Cell.fromBase64(src: messagePayload)
            }

            return MessageRelaxed.internal(
                to: payload.recipientAddress,
                value: payload.value.magnitude,
                bounce: false,
                stateInit: stateInit,
                body: body
            )
        }

        return TransferData(
            sender: sender,
            sendMode: .walletDefault(),
            internalMessages: internalMessages
        )
    }

    public static func emulate(
        transferData: TransferData,
        contract: WalletContract,
        network: Network
    ) async throws
        -> EmulateResult {
        let transactionSender = TransactionSender(api: api(network: network), contract: contract)
        return try await transactionSender.emulate(transferData: transferData)
    }

    public static func boc(
        transferData: TransferData,
        contract: WalletContract,
        secretKey: Data,
        network: Network
    ) async throws
        -> String {
        let transactionSender = TransactionSender(api: api(network: network), contract: contract)
        return try await transactionSender.boc(transferData: transferData, secretKey: secretKey)
    }

    public static func send(boc: String, contract: WalletContract, network: Network) async throws {
        let transactionSender = TransactionSender(api: api(network: network), contract: contract)
        try await transactionSender.send(boc: boc)
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
    public enum SyncError: Error {
        case notStarted
    }

    public enum WalletError: Error {
        case noJettonWallet
    }

    public enum SendAmount {
        case amount(value: BigUInt)
        case max
    }

    public struct Payload {
        // MARK: Properties

        let value: BigInt
        let recipientAddress: Address
        let stateInit: String?
        let payload: String?

        // MARK: Lifecycle

        public init(value: BigInt, recipientAddress: Address, stateInit: String?, payload: String?) {
            self.value = value
            self.recipientAddress = recipientAddress
            self.stateInit = stateInit
            self.payload = payload
        }
    }
}
