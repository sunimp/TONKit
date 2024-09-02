//
//  TonTransferRecord.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import GRDB
import TonSwift

// MARK: - TonTransferRecord

class TonTransferRecord: Record {
    // MARK: Nested Types

    enum Columns: String, ColumnExpression {
        case eventID
        case index
        case lt
        case senderUid
        case recipientUid
        case amount
        case comment
    }

    // MARK: Overridden Properties

    override class var databaseTableName: String {
        return "ton_transfer"
    }

    // MARK: Properties

    let eventID: String
    let index: Int
    let lt: Int64
    let senderUid: String
    let recipientUid: String
    let amount: Int64
    let comment: String?

    // MARK: Lifecycle

    init(
        eventID: String,
        index: Int,
        lt: Int64,
        senderUid: String,
        recipientUid: String,
        amount: Int64,
        comment: String?
    ) {
        self.eventID = eventID
        self.index = index
        self.lt = lt
        self.senderUid = senderUid
        self.recipientUid = recipientUid
        self.amount = amount
        self.comment = comment

        super.init()
    }

    required init(row: Row) throws {
        eventID = row[Columns.eventID]
        index = row[Columns.index]
        lt = row[Columns.lt]
        senderUid = row[Columns.senderUid]
        recipientUid = row[Columns.recipientUid]
        amount = row[Columns.amount]
        comment = row[Columns.comment]

        try super.init(row: row)
    }

    // MARK: Overridden Functions

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.eventID] = eventID
        container[Columns.index] = index
        container[Columns.lt] = lt
        container[Columns.senderUid] = senderUid
        container[Columns.recipientUid] = recipientUid
        container[Columns.amount] = amount
        container[Columns.comment] = comment
    }
}

extension TonTransferRecord {
    func tonTransfer(sender: WalletAccount, recipient: WalletAccount) -> TonTransfer {
        .init(
            eventID: eventID,
            index: index,
            sender: sender,
            recipient: recipient,
            amount: amount,
            comment: comment
        )
    }

    static func record(index: Int, lt: Int64, _ from: TonTransfer) -> TonTransferRecord {
        .init(
            eventID: from.eventID,
            index: index,
            lt: lt,
            senderUid: from.sender.address.toRaw(),
            recipientUid: from.recipient.address.toRaw(),
            amount: from.amount,
            comment: from.comment
        )
    }
}
