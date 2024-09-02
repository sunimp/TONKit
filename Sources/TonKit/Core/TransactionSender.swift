//
//  TransactionSender.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import BigInt
import TonSwift

// MARK: - TransactionSender

class TransactionSender {
    // MARK: Properties

    private let api: TonApi
    private let contract: WalletContract
    private let sender: Address
    private let secretKey: Data

    // MARK: Lifecycle

    init(api: TonApi, contract: WalletContract, sender: Address, secretKey: Data) {
        self.api = api
        self.contract = contract
        self.sender = sender
        self.secretKey = secretKey
    }
}

// MARK: - Amount

public struct Amount {
    // MARK: Properties

    let value: BigUInt
    let isMax: Bool

    // MARK: Lifecycle

    public init(value: BigUInt, isMax: Bool) {
        self.value = value
        self.isMax = isMax
    }
}

extension TransactionSender {
    func estimatedFee(
        recipient: FriendlyAddress,
        jetton: Jetton? = nil,
        amount: Amount,
        comment: String?
    ) async throws
        -> Decimal {
        do {
            let seqno = try await api.getSeqno(address: sender)
            let timeout = await api.timeoutSafely()
            let data = TransferData(
                contract: contract,
                sender: sender,
                seqno: UInt64(seqno),
                amount: amount.value,
                isMax: amount.isMax,
                recipient: recipient.address,
                isBounceable: recipient.isBounceable,
                comment: comment,
                timeout: timeout
            ) { transfer in
                try transfer.signMessage(signer: WalletTransferEmptyKeySigner())
            }

            let boc: String =
                if let jetton {
                    try await JettonTransferBoc(jetton: jetton.walletAddress, transferData: data).create()
                } else {
                    try await TonTransferBoc(transferData: data).create()
                }
            
            let transactionInfo = try await api.emulateMessageWallet(boc: boc)

            // for nfts transactionInfo.event can contains extra
            return Decimal(transactionInfo.trace.transaction.totalFees)
        } catch {
            print(error)
            return 0
        }
    }

    func sendTransaction(
        recipient: FriendlyAddress,
        jetton: Jetton? = nil,
        amount: Amount,
        comment: String?
    ) async throws {
        let seqno = try await api.getSeqno(address: sender)
        let timeout = await api.timeoutSafely()
        let secretKey = secretKey

        let data = TransferData(
            contract: contract,
            sender: sender,
            seqno: UInt64(seqno),
            amount: amount.value,
            isMax: amount.isMax,
            recipient: recipient.address,
            isBounceable: recipient.isBounceable,
            comment: comment,
            timeout: timeout
        ) { transfer in
            try transfer.signMessage(signer: WalletTransferSecretKeySigner(secretKey: secretKey))
        }

        let boc: String =
            if let jetton {
                try await JettonTransferBoc(jetton: jetton.walletAddress, transferData: data).create()
            } else {
                try await TonTransferBoc(transferData: data).create()
            }

        try await api.sendTransaction(boc: boc)
    }
}
