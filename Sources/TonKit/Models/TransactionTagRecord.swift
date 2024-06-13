import Foundation
import GRDB

class TransactionTagRecord: Record {
    let eventId: String
    let tag: TransactionTag

    init(eventId: String, tag: TransactionTag) {
        self.eventId = eventId
        self.tag = tag

        super.init()
    }

    override class var databaseTableName: String {
        "transaction_tag"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case eventId
        case type
        case `protocol`
        case jettonAddress
        case addresses
    }

    required init(row: Row) throws {
        eventId = row[Columns.eventId]
        tag = TransactionTag(
            type: row[Columns.type],
            protocol: row[Columns.protocol],
            jettonAddress: row[Columns.jettonAddress],
            addresses: Self.split(row[Columns.addresses])
        )

        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.eventId] = eventId
        container[Columns.type] = tag.type
        container[Columns.protocol] = tag.protocol
        container[Columns.jettonAddress] = tag.jettonAddress
        container[Columns.addresses] = Self.join(tag.addresses)
    }
}

extension TransactionTagRecord {
    static func split(_ value: String) -> [String] {
        value.split(separator: "|").compactMap { .init(String($0)) }
    }

    static func join(_ values: [String]) -> String {
        values.joined(separator: "|")
    }
}
