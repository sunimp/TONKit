//
//  WalletAccountRecord.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import GRDB
import TonAPI
import TonSwift

// MARK: - WalletAccountRecord

class WalletAccountRecord: Record {
    let uid: String
    let name: String?
    let isScam: Bool
    let isWallet: Bool

    init(uid: String, name: String?, isScam: Bool, isWallet: Bool) {
        self.uid = uid
        self.name = name
        self.isScam = isScam
        self.isWallet = isWallet

        super.init()
    }

    override public class var databaseTableName: String {
        "wallet_account"
    }

    enum Columns: String, ColumnExpression {
        case uid
        case name
        case isScam
        case isWallet
    }

    required init(row: Row) throws {
        uid = row[Columns.uid]
        name = row[Columns.name]
        isScam = row[Columns.isScam]
        isWallet = row[Columns.isWallet]

        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.uid] = uid
        container[Columns.name] = name
        container[Columns.isScam] = isScam
        container[Columns.isWallet] = isWallet
    }
}

extension WalletAccountRecord {
    static func accounts(db: Database, uids: [String]) throws -> [String: WalletAccount] {
        let records = try WalletAccountRecord.filter(uids.contains(WalletAccountRecord.Columns.uid)).fetchAll(db)
        let accounts = records.compactMap { $0.walletAccount }
        return Dictionary(uniqueKeysWithValues: accounts.compactMap { ($0.address.toRaw(), $0) })
    }
}

extension WalletAccountRecord {
    var walletAccount: WalletAccount? {
        let address = try? Address.parse(raw: uid)
        return address.map {
            WalletAccount(
                address: $0,
                name: name,
                isScam: isScam,
                isWallet: isWallet
            )
        }
    }

    static func record(_ from: WalletAccount) -> WalletAccountRecord {
        .init(
            uid: from.address.toRaw(),
            name: from.name,
            isScam: from.isScam,
            isWallet: from.isWallet
        )
    }
}
