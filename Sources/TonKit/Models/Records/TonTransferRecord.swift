import Foundation
import GRDB
import TonSwift

class TonTransferRecord: Record {
    let eventId: String
    let index: Int
    let lt: Int64
    let senderUid: String
    let recipientUid: String
    let amount: Int64
    let comment: String?

    init(eventId: String, index: Int, lt: Int64, senderUid: String, recipientUid: String, amount: Int64, comment: String?) {
        self.eventId = eventId
        self.index = index
        self.lt = lt
        self.senderUid = senderUid
        self.recipientUid = recipientUid
        self.amount = amount
        self.comment = comment

        super.init()
    }

    override class var databaseTableName: String {
        return "ton_transfer"
    }

    enum Columns: String, ColumnExpression {
        case eventId
        case index
        case lt
        case senderUid
        case recipientUid
        case amount
        case comment
    }

    required init(row: Row) throws {
        eventId = row[Columns.eventId]
        index = row[Columns.index]
        lt = row[Columns.lt]
        senderUid = row[Columns.senderUid]
        recipientUid = row[Columns.recipientUid]
        amount = row[Columns.amount]
        comment = row[Columns.comment]

        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.eventId] = eventId
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
            eventId: eventId,
            index: index,
            sender: sender,
            recipient: recipient,
            amount: amount,
            comment: comment
        )
    }

    static func record(index: Int, lt: Int64, _ from: TonTransfer) -> TonTransferRecord {
        .init(
            eventId: from.eventId,
            index: index,
            lt: lt,
            senderUid: from.sender.address.toRaw(),
            recipientUid: from.recipient.address.toRaw(),
            amount: from.amount,
            comment: from.comment
        )
    }
}
