//
//  TransactionSender.swift
//  TONKit
//
//  Created by Sun on 2024/6/13.
//

import BigInt
import Foundation
import TONSwift

// MARK: - TransactionSender

class TransactionSender {
    // MARK: Properties

    private let api: IApi
    private let contract: WalletContract

    // MARK: Lifecycle

    init(api: IApi, contract: WalletContract) {
        self.api = api
        self.contract = contract
    }

    // MARK: Functions

    private func safeTimeout(TTL: UInt64 = 5 * 60) async -> UInt64 {
        do {
            let rawTime = try await api.getRawTime()
            return UInt64(rawTime) + TTL
        } catch {
            return UInt64(Date().timeIntervalSince1970) + TTL
        }
    }

    private func boc(transferData: TransferData, signer: WalletTransferSigner) async throws -> String {
        let seqno = try await api.getAccountSeqno(address: transferData.sender)
        let timeout = await safeTimeout()

        return try ExternalMessageTransferBuilder.externalMessageTransfer(
            contract: contract,
            sender: transferData.sender,
            sendMode: transferData.sendMode,
            seqno: UInt64(seqno),
            internalMessages: transferData.internalMessages,
            timeout: timeout,
            signer: signer
        )
    }
}

extension TransactionSender {
    func emulate(transferData: TransferData) async throws -> EmulateResult {
        let boc = try await boc(transferData: transferData, signer: WalletTransferEmptyKeySigner())
        return try await api.emulate(boc: boc)
    }

    func boc(transferData: TransferData, secretKey: Data) async throws -> String {
        try await boc(transferData: transferData, signer: WalletTransferSecretKeySigner(secretKey: secretKey))
    }

    func send(boc: String) async throws {
        return try await api.send(boc: boc)
    }
}
