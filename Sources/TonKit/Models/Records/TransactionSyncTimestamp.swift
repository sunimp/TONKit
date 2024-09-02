//
//  TransactionSyncTimestamp.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import GRDB

class TransactionSyncTimestamp: Record {
    // MARK: Nested Types

    enum Columns: String, ColumnExpression, CaseIterable {
        case apiPath
        case lastTransactionTimestamp
    }

    // MARK: Overridden Properties

    override public class var databaseTableName: String {
        "transaction_sync_timestamps"
    }

    // MARK: Properties

    let apiPath: String
    let lastTransactionTimestamp: Int

    // MARK: Lifecycle

    init(apiPath: String, lastTransactionTimestamp: Int) {
        self.apiPath = apiPath
        self.lastTransactionTimestamp = lastTransactionTimestamp

        super.init()
    }

    required init(row: Row) throws {
        apiPath = row[Columns.apiPath]
        lastTransactionTimestamp = row[Columns.lastTransactionTimestamp]

        try super.init(row: row)
    }

    // MARK: Overridden Functions

    override public func encode(to container: inout PersistenceContainer) {
        container[Columns.apiPath] = apiPath
        container[Columns.lastTransactionTimestamp] = lastTransactionTimestamp
    }
}
