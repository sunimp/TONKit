//
//  Balance.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import BigInt
import GRDB

// MARK: - Balance

class Balance: Record {
    // MARK: Nested Types

    enum Columns: String, ColumnExpression {
        case id
        case wallet
        case balance
    }

    // MARK: Overridden Properties

    override class var databaseTableName: String {
        return "balances"
    }

    // MARK: Properties

    let id: String
    let wallet: String?
    var balance: BigUInt

    // MARK: Lifecycle

    init(id: String, wallet: String?, balance: BigUInt) {
        self.id = id
        self.wallet = wallet
        self.balance = balance

        super.init()
    }

    required init(row: Row) throws {
        id = row[Columns.id]
        wallet = row[Columns.wallet]
        balance = row[Columns.balance]

        try super.init(row: row)
    }

    // MARK: Overridden Functions

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.wallet] = wallet
        container[Columns.balance] = balance
    }
}

// MARK: - BigUInt + DatabaseValueConvertible

extension BigUInt: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        description.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> BigUInt? {
        if case let DatabaseValue.Storage.string(value) = dbValue.storage {
            return BigUInt(value)
        }

        return nil
    }
}
