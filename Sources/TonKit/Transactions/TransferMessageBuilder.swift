//
//  TonTransferMessageBuilder.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import BigInt
import TonSwift

// MARK: - TonTransferMessageBuilder

public struct TonTransferMessageBuilder {
    private init() { }
    public static func sendTonTransfer(
        contract: WalletContract,
        sender: Address,
        seqno: UInt64,
        value: BigUInt,
        isMax: Bool,
        recipientAddress: Address,
        isBounceable: Bool = true,
        comment: String?,
        timeout: UInt64?,
        signClosure: (WalletTransfer) async throws -> Data
    ) async throws -> String {
        return try await ExternalMessageTransferBuilder.externalMessageTransfer(
            contract: contract,
            sender: sender,
            sendMode: isMax ? .sendMaxTon() : .walletDefault(),
            seqno: seqno,
            internalMessages: { _ in
                let internalMessage: MessageRelaxed
                if let comment = comment {
                    internalMessage = try MessageRelaxed.internal(
                        to: recipientAddress,
                        value: value.magnitude,
                        bounce: isBounceable,
                        textPayload: comment
                    )
                } else {
                    internalMessage = MessageRelaxed.internal(
                        to: recipientAddress,
                        value: value.magnitude,
                        bounce: isBounceable
                    )
                }
                return [internalMessage]
            },
            timeout: timeout,
            signClosure: signClosure
        )
    }
}

// MARK: - TonConnectTransferMessageBuilder

public struct TonConnectTransferMessageBuilder {
    private init() { }

    public struct Payload {
        let value: BigInt
        let recipientAddress: Address
        let stateInit: String?
        let payload: String?

        public init(
            value: BigInt,
            recipientAddress: Address,
            stateInit: String?,
            payload: String?
        ) {
            self.value = value
            self.recipientAddress = recipientAddress
            self.stateInit = stateInit
            self.payload = payload
        }
    }

    public static func sendTonConnectTransfer(
        contract: WalletContract,
        sender: Address,
        seqno: UInt64,
        payloads: [Payload],
        timeout: UInt64?,
        signClosure: (WalletTransfer) async throws -> Data
    ) async throws -> String {
        let messages = try payloads.map { payload in
            var stateInit: StateInit?
            if let stateInitString = payload.stateInit {
                stateInit = try StateInit.loadFrom(
                    slice: Cell
                        .fromBase64(src: stateInitString)
                        .toSlice()
                )
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
        return try await ExternalMessageTransferBuilder
            .externalMessageTransfer(
                contract: contract,
                sender: sender,
                seqno: seqno,
                internalMessages: { _ in
                    messages
                },
                timeout: timeout,
                signClosure: signClosure
            )
    }
}

// MARK: - TokenTransferMessageBuilder

public struct TokenTransferMessageBuilder {
    private init() { }
    public static func sendTokenTransfer(
        contract: WalletContract,
        sender: Address,
        seqno: UInt64,
        tokenAddress: Address,
        value: BigUInt,
        recipientAddress: Address,
        isBounceable: Bool = true,
        comment: String?,
        timeout: UInt64?,
        signClosure: (WalletTransfer) async throws -> Data
    ) async throws -> String {
        return try await ExternalMessageTransferBuilder
            .externalMessageTransfer(
                contract: contract,
                sender: sender,
                seqno: seqno,
                internalMessages: { sender in
                    let internalMessage = try JettonTransferMessage.internalMessage(
                        jettonAddress: tokenAddress,
                        amount: BigInt(value),
                        bounce: isBounceable,
                        to: recipientAddress,
                        from: sender,
                        comment: comment
                    )
                    return [internalMessage]
                },
                timeout: timeout,
                signClosure: signClosure
            )
    }
}

// MARK: - NFTTransferMessageBuilder

public struct NFTTransferMessageBuilder {
    private init() { }
    public static func sendNFTTransfer(
        contract: WalletContract,
        sender: Address,
        seqno: UInt64,
        nftAddress: Address,
        recipientAddress: Address,
        isBounceable: Bool = true,
        transferAmount: BigUInt,
        timeout: UInt64?,
        signClosure: (WalletTransfer) async throws -> Data
    ) async throws -> String {
        return try await ExternalMessageTransferBuilder
            .externalMessageTransfer(
                contract: contract,
                sender: sender,
                seqno: seqno,
                internalMessages: { sender in
                    let internalMessage = try NFTTransferMessage.internalMessage(
                        nftAddress: nftAddress,
                        nftTransferAmount: transferAmount,
                        bounce: isBounceable,
                        to: recipientAddress,
                        from: sender,
                        forwardPayload: nil
                    )
                    return [internalMessage]
                },
                timeout: timeout,
                signClosure: signClosure
            )
    }
}

// MARK: - ExternalMessageTransferBuilder

public struct ExternalMessageTransferBuilder {
    
    private init() { }
    
    public static func externalMessageTransfer(
        contract: WalletContract,
        sender: Address,
        sendMode: SendMode = .walletDefault(),
        seqno: UInt64,
        internalMessages: (_ sender: Address) throws -> [MessageRelaxed],
        timeout: UInt64?,
        signClosure: (WalletTransfer) async throws -> Data
    ) async throws -> String {
        let internalMessages = try internalMessages(sender)
        let transferData = WalletTransferData(
            seqno: seqno,
            messages: internalMessages,
            sendMode: sendMode,
            timeout: timeout
        )

        let transfer = try contract.createTransfer(args: transferData, messageType: .ext)
        let signedTransfer = try await signClosure(transfer)
        let body = Builder()
        try body.store(data: signedTransfer)
        try body.store(transfer.signingMessage)
        let transferCell = try body.endCell()

        let externalMessage = Message.external(
            to: sender,
            stateInit: contract.stateInit,
            body: transferCell
        )
        let cell = try Builder().store(externalMessage).endCell()
        return try cell.toBoc().base64EncodedString()
    }
}
