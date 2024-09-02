//
//  TransactionTagRecord.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import GRDB

// MARK: - TransactionTagRecord

class TransactionTagRecord: Record {
    // MARK: Nested Types

    enum Columns: String, ColumnExpression, CaseIterable {
        case eventID
        case type
        case `protocol`
        case jettonAddress
        case addresses
    }

    // MARK: Overridden Properties

    override class var databaseTableName: String {
        "transaction_tag"
    }

    // MARK: Properties

    let eventID: String
    let tag: TransactionTag

    // MARK: Lifecycle

    init(eventID: String, tag: TransactionTag) {
        self.eventID = eventID
        self.tag = tag

        super.init()
    }

    required init(row: Row) throws {
        eventID = row[Columns.eventID]
        tag = TransactionTag(
            type: row[Columns.type],
            protocol: row[Columns.protocol],
            jettonAddress: row[Columns.jettonAddress],
            addresses: Self.split(row[Columns.addresses])
        )

        try super.init(row: row)
    }

    // MARK: Overridden Functions

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.eventID] = eventID
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
