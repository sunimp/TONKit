//
//  TonTransfer.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import GRDB
import TonSwift

// MARK: - TonTransfer

public class TonTransfer: Action {
    public let sender: WalletAccount
    public let recipient: WalletAccount
    public let amount: Int64
    public let comment: String?

    init(eventId: String, index: Int, sender: WalletAccount, recipient: WalletAccount, amount: Int64, comment: String?) {
        self.sender = sender
        self.recipient = recipient
        self.amount = amount
        self.comment = comment

        super.init(eventId: eventId, index: index)
    }

    enum CodingKeys: String, CodingKey {
        case sender
        case recipient
        case amount
        case comment
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sender = try container.decode(WalletAccount.self, forKey: .sender)
        recipient = try container.decode(WalletAccount.self, forKey: .recipient)
        amount = try container.decode(Int64.self, forKey: .amount)
        comment = try? container.decode(String.self, forKey: .comment)

        try super.init(from: decoder)
    }
}

// MARK: IActionRecord

extension TonTransfer: IActionRecord {
    func save(db: Database, index: Int, lt: Int64) throws {
        try TonTransferRecord.record(index: index, lt: lt, self).save(db)
        try WalletAccountRecord.record(recipient).save(db)
        try WalletAccountRecord.record(sender).save(db)
    }
}
