//
//  TransactionBoc.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import BigInt
import TonSwift

// MARK: - TransactionBoc

class TransactionBoc {
    func create() async throws -> String {
        fatalError("must be implemented by childs")
    }
}

// MARK: - TransferData

struct TransferData {
    let contract: WalletContract
    let sender: Address
    let seqno: UInt64
    let amount: BigUInt
    let isMax: Bool
    let recipient: Address
    let isBounceable: Bool
    let comment: String?
    let timeout: UInt64?
    let signClosure: (WalletTransfer) async throws -> Data
}

// MARK: - TransferBoc

class TransferBoc: TransactionBoc {
    // MARK: Properties

    let data: TransferData

    // MARK: Lifecycle

    init(transferData: TransferData) {
        data = transferData
    }
}

// MARK: - TonTransferBoc

class TonTransferBoc: TransferBoc {
    // MARK: Lifecycle

    override init(transferData: TransferData) {
        super.init(transferData: transferData)
    }

    // MARK: Overridden Functions

    override func create() async throws -> String {
        return try await TonTransferMessageBuilder.sendTonTransfer(
            contract: data.contract,
            sender: data.sender,
            seqno: data.seqno,
            value: data.amount,
            isMax: data.isMax,
            recipientAddress: data.recipient,
            isBounceable: data.isBounceable,
            comment: data.comment,
            timeout: data.timeout,
            signClosure: data.signClosure
        )
    }
}

// MARK: - JettonTransferBoc

class JettonTransferBoc: TransferBoc {
    // MARK: Properties

    let jetton: Address

    // MARK: Lifecycle

    init(jetton: Address, transferData: TransferData) {
        self.jetton = jetton
        super.init(transferData: transferData)
    }

    // MARK: Overridden Functions

    override func create() async throws -> String {
        return try await TokenTransferMessageBuilder.sendTokenTransfer(
            contract: data.contract,
            sender: data.sender,
            seqno: data.seqno,
            tokenAddress: jetton,
            value: data.amount,
            recipientAddress: data.recipient,
            isBounceable: data.isBounceable,
            comment: data.comment,
            timeout: data.timeout,
            signClosure: data.signClosure
        )
    }
}
