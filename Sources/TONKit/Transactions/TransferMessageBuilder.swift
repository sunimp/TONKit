//
//  TransferMessageBuilder.swift
//  TONKit
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import BigInt
import TONSwift

// MARK: - TONTransferMessageBuilder

public struct TONTransferMessageBuilder {
    // MARK: Lifecycle

    private init() { }
    
    // MARK: Static Functions

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
        signClosure: (WalletTransfer) throws -> Data
    ) throws
        -> String {
        return try ExternalMessageTransferBuilder.externalMessageTransfer(
            contract: contract,
            sender: sender,
            sendMode: isMax ? .sendMaxTon() : .walletDefault(),
            seqno: seqno,
            internalMessages: { _ in
                let internalMessage: MessageRelaxed =
                    if let comment {
                        try MessageRelaxed.internal(
                            to: recipientAddress,
                            value: value.magnitude,
                            bounce: isBounceable,
                            textPayload: comment
                        )
                    } else {
                        MessageRelaxed.internal(
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

// MARK: - TokenTransferMessageBuilder

public struct TokenTransferMessageBuilder {
    // MARK: Lifecycle

    private init() { }
    
    // MARK: Static Functions

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
        signClosure: (WalletTransfer) throws -> Data
    ) throws
        -> String {
        return try ExternalMessageTransferBuilder.externalMessageTransfer(
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

// MARK: - ExternalMessageTransferBuilder

public struct ExternalMessageTransferBuilder {
    // MARK: Lifecycle

    private init() { }
    
    // MARK: Static Functions

    public static func externalMessageTransfer(
        contract: WalletContract,
        sender: Address,
        sendMode: SendMode = .walletDefault(),
        seqno: UInt64,
        internalMessages: (_ sender: Address) throws -> [MessageRelaxed],
        timeout: UInt64?,
        signClosure: (WalletTransfer) throws -> Data
    ) throws
        -> String {
        let internalMessages = try internalMessages(sender)
        
        let transferData = WalletTransferData(
            seqno: seqno,
            messages: internalMessages,
            sendMode: sendMode,
            timeout: timeout
        )
        
        let transfer = try contract.createTransfer(args: transferData, messageType: .ext)
        let signedTransfer = try signClosure(transfer)
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
