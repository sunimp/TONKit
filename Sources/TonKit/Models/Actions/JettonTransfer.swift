//
//  JettonTransfer.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import BigInt
import GRDB
import TonSwift

// MARK: - JettonTransfer

public class JettonTransfer: Action {
    let sender: WalletAccount?
    let recipient: WalletAccount?
    let senderAddress: Address
    let recipientAddress: Address
    let amount: BigUInt
    let jettonAddress: Address
    let comment: String?

    init(
        eventId: String,
        index: Int,
        sender: WalletAccount?,
        recipient: WalletAccount?,
        senderAddress: Address,
        recipientAddress: Address,
        amount: BigUInt,
        jettonAddress: Address,
        comment: String?
    ) {
        self.sender = sender
        self.recipient = recipient
        self.senderAddress = senderAddress
        self.recipientAddress = recipientAddress
        self.amount = amount
        self.jettonAddress = jettonAddress
        self.comment = comment

        super.init(eventId: eventId, index: index)
    }

    enum CodingKeys: String, CodingKey {
        case sender
        case recipient
        case senderAddress
        case recipientAddress
        case amount
        case jettonAddress
        case comment
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sender = try? container.decode(WalletAccount.self, forKey: .sender)
        recipient = try? container.decode(WalletAccount.self, forKey: .recipient)
        senderAddress = try container.decode(Address.self, forKey: .senderAddress)
        recipientAddress = try container.decode(Address.self, forKey: .recipientAddress)
        amount = try container.decode(BigUInt.self, forKey: .amount)
        jettonAddress = try container.decode(Address.self, forKey: .jettonAddress)
        comment = try? container.decode(String.self, forKey: .comment)

        try super.init(from: decoder)
    }
}

// MARK: IActionRecord

extension JettonTransfer: IActionRecord {
    func save(db: Database, index: Int, lt: Int64) throws {
        try JettonTransferRecord.record(index: index, lt: lt, self).save(db)
        if let recipient {
            try WalletAccountRecord.record(recipient).save(db)
        }
        if let sender {
            try WalletAccountRecord.record(sender).save(db)
        }
    }
}
