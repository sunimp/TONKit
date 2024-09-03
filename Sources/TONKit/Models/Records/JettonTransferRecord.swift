//
//  JettonTransferRecord.swift
//
//  Created by Sun on 2024/6/20.
//

import Foundation

import BigInt
import GRDB
import TonSwift

// MARK: - JettonTransferRecord

class JettonTransferRecord: Record {
    // MARK: Nested Types

    enum Columns: String, ColumnExpression {
        case eventID
        case index
        case lt
        case senderUid
        case recipientUid
        case senderAddressUid
        case recipientAddressUid
        case amount
        case jettonAddressUid
        case comment
    }

    // MARK: Overridden Properties

    override class var databaseTableName: String {
        return "jetton_transfer"
    }

    // MARK: Properties

    let eventID: String
    let index: Int
    let lt: Int64
    let senderUid: String?
    let recipientUid: String?
    let senderAddressUid: String
    let recipientAddressUid: String
    let amount: BigUInt
    let jettonAddressUid: String
    let comment: String?

    // MARK: Lifecycle

    init(
        eventID: String,
        index: Int,
        lt: Int64,
        senderUid: String?,
        recipientUid: String?,
        senderAddressUid: String,
        recipientAddressUid: String,
        amount: BigUInt,
        jettonAddressUid: String,
        comment: String?
    ) {
        self.eventID = eventID
        self.index = index
        self.lt = lt
        self.senderUid = senderUid
        self.recipientUid = recipientUid
        self.senderAddressUid = senderAddressUid
        self.recipientAddressUid = recipientAddressUid
        self.amount = amount
        self.jettonAddressUid = jettonAddressUid
        self.comment = comment

        super.init()
    }

    required init(row: Row) throws {
        eventID = row[Columns.eventID]
        index = row[Columns.index]
        lt = row[Columns.lt]
        senderUid = row[Columns.senderUid]
        recipientUid = row[Columns.recipientUid]
        senderAddressUid = row[Columns.senderAddressUid]
        recipientAddressUid = row[Columns.recipientAddressUid]
        let amount: String = row[Columns.amount]
        guard let amountBigUInt = BigUInt(amount, radix: 10) else {
            throw Kit.KitError.parsingError
        }
        self.amount = amountBigUInt

        jettonAddressUid = row[Columns.jettonAddressUid]
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
        container[Columns.senderAddressUid] = senderAddressUid
        container[Columns.recipientAddressUid] = recipientAddressUid
        container[Columns.amount] = amount.description
        container[Columns.jettonAddressUid] = jettonAddressUid
        container[Columns.comment] = comment
    }
}

extension JettonTransferRecord {
    func jettonTransfer(sender: WalletAccount?, recipient: WalletAccount?) -> JettonTransfer? {
        guard
            let senderAddress = try? Address.parse(raw: senderAddressUid),
            let recipientAddress = try? Address.parse(raw: recipientAddressUid),
            let jettonAddress = try? Address.parse(raw: jettonAddressUid)
        else {
            return nil
        }
        
        return .init(
            eventID: eventID,
            index: index,
            sender: sender,
            recipient: recipient,
            senderAddress: senderAddress,
            recipientAddress: recipientAddress,
            amount: amount,
            jettonAddress: jettonAddress,
            comment: comment
        )
    }

    static func record(index: Int, lt: Int64, _ from: JettonTransfer) -> JettonTransferRecord {
        .init(
            eventID: from.eventID,
            index: index,
            lt: lt,
            senderUid: from.sender?.address.toRaw(),
            recipientUid: from.recipient?.address.toRaw(),
            senderAddressUid: from.senderAddress.toRaw(),
            recipientAddressUid: from.recipientAddress.toRaw(),
            amount: from.amount,
            jettonAddressUid: from.jettonAddress.toRaw(),
            comment: from.comment
        )
    }
}
