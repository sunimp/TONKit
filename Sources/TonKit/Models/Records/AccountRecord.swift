//
//  AccountRecord.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import GRDB
import TonAPI
import TonSwift

// MARK: - AccountRecord

class AccountRecord: Record {
    // MARK: Nested Types

    enum Columns: String, ColumnExpression {
        case uid
        case balance
        case status
        case name
        case icon
        case isSuspended
        case isWallet
    }

    // MARK: Overridden Properties

    override public class var databaseTableName: String {
        "account"
    }

    // MARK: Properties

    let uid: Data
    let balance: Int64
    let status: String
    let name: String?
    let icon: String?
    let isSuspended: Bool?
    let isWallet: Bool

    // MARK: Lifecycle

    init(uid: Data, balance: Int64, status: String, name: String?, icon: String?, isSuspended: Bool?, isWallet: Bool) {
        self.uid = uid
        self.balance = balance
        self.status = status
        self.name = name
        self.icon = icon
        self.isSuspended = isSuspended
        self.isWallet = isWallet

        super.init()
    }

    required init(row: Row) throws {
        uid = row[Columns.uid]
        balance = row[Columns.balance]
        status = row[Columns.status]
        name = row[Columns.name]
        icon = row[Columns.icon]
        isSuspended = row[Columns.isSuspended]
        isWallet = row[Columns.isWallet]

        try super.init(row: row)
    }

    // MARK: Overridden Functions

    override public func encode(to container: inout PersistenceContainer) {
        container[Columns.uid] = uid
        container[Columns.balance] = balance
        container[Columns.status] = status
        container[Columns.name] = name
        container[Columns.icon] = icon
        container[Columns.isSuspended] = isSuspended
        container[Columns.isWallet] = isWallet
    }
}

extension AccountRecord {
    var account: Account? {
        Address.from(uid).map {
            .init(
                address: $0,
                balance: balance,
                status: status,
                name: name,
                icon: icon,
                isSuspended: isSuspended,
                isWallet: isWallet
            )
        }
    }

    static func record(_ from: Account) -> AccountRecord {
        .init(
            uid: from.address.toData,
            balance: from.balance,
            status: from.status,
            name: from.name,
            icon: from.icon,
            isSuspended: from.isSuspended,
            isWallet: from.isWallet
        )
    }
}
