//
//  Balance.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import BigInt
import GRDB

// MARK: - Balance

class Balance: Record {
    let id: String
    let wallet: String?
    var balance: BigUInt

    init(id: String, wallet: String?, balance: BigUInt) {
        self.id = id
        self.wallet = wallet
        self.balance = balance

        super.init()
    }

    override class var databaseTableName: String {
        return "balances"
    }

    enum Columns: String, ColumnExpression {
        case id
        case wallet
        case balance
    }

    required init(row: Row) throws {
        id = row[Columns.id]
        wallet = row[Columns.wallet]
        balance = row[Columns.balance]

        try super.init(row: row)
    }

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
        if case DatabaseValue.Storage.string(let value) = dbValue.storage {
            return BigUInt(value)
        }

        return nil
    }
}
