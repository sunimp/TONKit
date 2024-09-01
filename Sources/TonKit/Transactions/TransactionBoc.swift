//
//  TransactionBoc.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
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
    let data: TransferData

    init(transferData: TransferData) {
        data = transferData
    }
}

// MARK: - TonTransferBoc

class TonTransferBoc: TransferBoc {
    override init(transferData: TransferData) {
        super.init(transferData: transferData)
    }

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
    let jetton: Address

    init(jetton: Address, transferData: TransferData) {
        self.jetton = jetton
        super.init(transferData: transferData)
    }

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
