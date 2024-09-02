//
//  TransactionStorage.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import GRDB

// MARK: - AccountEventStorage

class AccountEventStorage {
    // MARK: Properties

    private let dbPool: DatabasePool

    // MARK: Computed Properties

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("create Account") { db in
            try db.create(table: AccountRecord.databaseTableName) { t in
                t.column(AccountRecord.Columns.uid.name, .blob).notNull().primaryKey(onConflict: .replace)
                t.column(AccountRecord.Columns.balance.name, .integer).notNull().indexed()
                t.column(AccountRecord.Columns.status.name, .text).notNull()
                t.column(AccountRecord.Columns.name.name, .text)
                t.column(AccountRecord.Columns.icon.name, .text)
                t.column(AccountRecord.Columns.isSuspended.name, .boolean)
                t.column(AccountRecord.Columns.isWallet.name, .boolean).notNull()
            }
        }

        migrator.registerMigration("create Wallet Account") { db in
            try db.create(table: WalletAccountRecord.databaseTableName) { t in
                t.column(WalletAccountRecord.Columns.uid.name, .blob).notNull().primaryKey(onConflict: .replace)
                t.column(WalletAccountRecord.Columns.name.name, .text)
                t.column(WalletAccountRecord.Columns.isScam.name, .boolean)
                t.column(WalletAccountRecord.Columns.isWallet.name, .boolean).notNull()
            }
        }

        migrator.registerMigration("Create AccountEvent") { db in
            try db.create(table: AccountEventRecord.databaseTableName) { t in
                t.column(AccountEventRecord.Columns.eventID.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(AccountEventRecord.Columns.timestamp.name, .integer).notNull()
                t.column(AccountEventRecord.Columns.accountUid.name, .blob).notNull()
                t.column(AccountEventRecord.Columns.isScam.name, .boolean).notNull()
                t.column(AccountEventRecord.Columns.isInProgress.name, .boolean).notNull()
                t.column(AccountEventRecord.Columns.fee.name, .integer).notNull()
                t.column(AccountEventRecord.Columns.lt.name, .integer).notNull()

                t.foreignKey(
                    [AccountEventRecord.Columns.accountUid.name],
                    references: WalletAccountRecord.databaseTableName,
                    columns: [AccountRecord.Columns.uid.name],
                    onDelete: .cascade,
                    onUpdate: .cascade,
                    deferred: true
                )
            }
        }

        migrator.registerMigration("create TonTransfer") { db in
            try db.create(table: TonTransferRecord.databaseTableName) { t in
                t.column(TonTransferRecord.Columns.eventID.name, .text).notNull()
                t.column(TonTransferRecord.Columns.index.name, .integer).notNull()
                t.column(TonTransferRecord.Columns.lt.name, .integer).notNull()
                t.column(TonTransferRecord.Columns.senderUid.name, .text).notNull()
                t.column(TonTransferRecord.Columns.recipientUid.name, .text).notNull()
                t.column(TonTransferRecord.Columns.amount.name, .integer).notNull()
                t.column(TonTransferRecord.Columns.comment.name, .text)

                t.primaryKey(
                    [TonTransferRecord.Columns.eventID.name, TonTransferRecord.Columns.index.name],
                    onConflict: .replace
                )
            }
        }

        migrator.registerMigration("create TransactionTagRecord") { db in
            try db.create(table: TransactionTagRecord.databaseTableName) { t in
                t.column(TransactionTagRecord.Columns.eventID.name, .blob).notNull().indexed()
                t.column(TransactionTagRecord.Columns.type.name, .text).notNull()
                t.column(TransactionTagRecord.Columns.protocol.name, .text)
                t.column(TransactionTagRecord.Columns.jettonAddress.name, .blob)
                t.column(TransactionTagRecord.Columns.addresses.name, .text).notNull()

                t.foreignKey(
                    [TransactionTagRecord.Columns.eventID.name],
                    references: AccountEventRecord.databaseTableName,
                    columns: [AccountEventRecord.Columns.eventID.name],
                    onDelete: .cascade,
                    onUpdate: .cascade,
                    deferred: true
                )
            }
        }

        migrator.registerMigration("create JettonTransfer") { db in
            try db.create(table: JettonTransferRecord.databaseTableName) { t in
                t.column(JettonTransferRecord.Columns.eventID.name, .text).notNull()
                t.column(JettonTransferRecord.Columns.index.name, .integer).notNull()
                t.column(JettonTransferRecord.Columns.lt.name, .integer).notNull()
                t.column(JettonTransferRecord.Columns.senderUid.name, .text)
                t.column(JettonTransferRecord.Columns.recipientUid.name, .text)
                t.column(JettonTransferRecord.Columns.senderAddressUid.name, .text).notNull()
                t.column(JettonTransferRecord.Columns.recipientAddressUid.name, .text).notNull()
                t.column(JettonTransferRecord.Columns.amount.name, .text).notNull()
                t.column(JettonTransferRecord.Columns.jettonAddressUid.name, .text).notNull()
                t.column(JettonTransferRecord.Columns.comment.name, .text)

                t.primaryKey(
                    [JettonTransferRecord.Columns.eventID.name, JettonTransferRecord.Columns.index.name],
                    onConflict: .replace
                )
            }
        }

        return migrator
    }

    // MARK: Lifecycle

    init(databaseDirectoryURL: URL, databaseFileName: String) {
        let databaseURL = databaseDirectoryURL.appendingPathComponent("\(databaseFileName).sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try! migrator.migrate(dbPool)
    }
}

extension AccountEventStorage {
    func event(eventID: String) -> AccountEvent? {
        try! dbPool.read { db in
            guard let record = try AccountEventRecord.filter(AccountEventRecord.Columns.eventID == eventID).fetchOne(db)
            else {
                return nil
            }
            return try [record].events(db: db).first
        }
    }

    func eventsBefore(tagQueries: [TransactionTagQuery], lt: Int64?, limit: Int?) -> [AccountEvent] {
        try! dbPool.read { db in
            var arguments = [DatabaseValueConvertible]()
            var whereConditions = [String]()
            let queries = tagQueries.filter { !$0.isEmpty }
            var joinClause = ""

            if !queries.isEmpty {
                let tagConditions = queries
                    .map { (tagQuery: TransactionTagQuery) -> String in
                        var statements = [String]()

                        if let type = tagQuery.type {
                            statements
                                .append(
                                    "\(TransactionTagRecord.databaseTableName).'\(TransactionTagRecord.Columns.type.name)' = ?"
                                )
                            arguments.append(type)
                        }
                        if let `protocol` = tagQuery.protocol {
                            statements
                                .append(
                                    "\(TransactionTagRecord.databaseTableName).'\(TransactionTagRecord.Columns.protocol.name)' = ?"
                                )
                            arguments.append(`protocol`)
                        }
                        if let jettonAddress = tagQuery.jettonAddress {
                            statements
                                .append(
                                    "\(TransactionTagRecord.databaseTableName).'\(TransactionTagRecord.Columns.jettonAddress.name)' = ?"
                                )
                            arguments.append(jettonAddress)
                        }
                        if let address = tagQuery.address {
                            statements
                                .append(
                                    "LOWER(\(TransactionTagRecord.databaseTableName).'\(TransactionTagRecord.Columns.addresses.name)') LIKE ?"
                                )
                            arguments.append("%" + address + "%")
                        }

                        return "(\(statements.joined(separator: " AND ")))"
                    }
                    .joined(separator: " OR ")

                whereConditions.append(tagConditions)
                joinClause =
                    "INNER JOIN \(TransactionTagRecord.databaseTableName) ON \(AccountEventRecord.databaseTableName).\(AccountEventRecord.Columns.eventID.name) = \(TransactionTagRecord.databaseTableName).\(TransactionTagRecord.Columns.eventID.name)"
            }

            if
                let lt,
                let fromTransaction = try AccountEventRecord.filter(AccountEventRecord.Columns.lt == lt).fetchOne(db) {
                let fromCondition = """
                    (
                     \(AccountEventRecord.Columns.lt.name) < ? OR
                         (
                             \(AccountEventRecord.databaseTableName).\(AccountEventRecord.Columns.lt.name) = ? AND
                             \(AccountEventRecord.databaseTableName).\(AccountEventRecord.Columns.eventID.name) < ?
                         )
                    )
                    """

                arguments.append(fromTransaction.lt)
                arguments.append(fromTransaction.lt)
                arguments.append(fromTransaction.eventID)

                whereConditions.append(fromCondition)
            }

            var limitClause = ""
            if let limit {
                limitClause += "LIMIT \(limit)"
            }

            let orderClause = """
                ORDER BY \(AccountEventRecord.databaseTableName).\(AccountEventRecord.Columns.lt.name) DESC,
                \(AccountEventRecord.databaseTableName).\(AccountEventRecord.Columns.eventID.name) DESC
                """

            let whereClause = whereConditions.count > 0 ? "WHERE \(whereConditions.joined(separator: " AND "))" : ""

            let sql = """
                SELECT DISTINCT \(AccountEventRecord.databaseTableName).*
                FROM \(AccountEventRecord.databaseTableName)
                \(joinClause)
                \(whereClause)
                \(orderClause)
                \(limitClause)
                """

            let rows = try Row.fetchAll(db.makeStatement(sql: sql), arguments: StatementArguments(arguments))

            let records = try rows.map { row -> AccountEventRecord in
                try AccountEventRecord(row: row)
            }

            return try records.events(db: db)
        }
    }

    func lastEventRecord(newest: Bool, jettonAddressUid: String?) -> AccountEventRecord? {
        try! dbPool.read { db in
            if let jettonAddressUid {
                guard
                    let record = try JettonTransferRecord
                        .filter(JettonTransferRecord.Columns.jettonAddressUid == jettonAddressUid)
                        .order(newest ? JettonTransferRecord.Columns.lt.desc : JettonTransferRecord.Columns.lt.asc)
                        .fetchOne(db)
                else {
                    return nil
                }
                return try AccountEventRecord
                    .filter(AccountEventRecord.Columns.eventID == record.eventID)
                    .fetchOne(db)
            }
            guard
                let record = try TonTransferRecord
                    .order(newest ? TonTransferRecord.Columns.lt.desc : TonTransferRecord.Columns.lt.asc)
                    .fetchOne(db)
            else {
                return nil
            }
            return try AccountEventRecord
                .filter(AccountEventRecord.Columns.eventID == record.eventID)
                .fetchOne(db)
        }
    }

    static func save(db: Database, lt: Int64, actions: [Action]) throws {
        for (index, action) in actions.enumerated() {
            if let action = action as? IActionRecord {
                try action.save(db: db, index: index, lt: lt)
            }
        }
    }

    func save(events: [AccountEvent], replaceOnConflict: Bool) {
        try! dbPool.write { db in
            for event in events {
                let record = AccountEventRecord.record(event)
                if !replaceOnConflict, try record.exists(db) {
                    continue
                }

                try record.save(db)
                try WalletAccountRecord.record(event.account).save(db)
                try AccountEventStorage.save(db: db, lt: event.lt, actions: event.actions)
            }
        }
    }

    func save(tags: [TransactionTagRecord]) {
        try! dbPool.write { db in
            for tag in tags {
                try tag.save(db)
            }
        }
    }
}
