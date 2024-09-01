//
//  AccountInfoStorage.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import BigInt
import GRDB
import TonSwift

// MARK: - AccountInfoStorage

class AccountInfoStorage {
    
    private let dbPool: DatabasePool

    init(databaseDirectoryURL: URL, databaseFileName: String) {
        let databaseURL = databaseDirectoryURL.appendingPathComponent("\(databaseFileName).sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try! migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createBalances") { db in
            try db.create(table: Balance.databaseTableName, body: { t in
                t.column(Balance.Columns.id.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(Balance.Columns.wallet.name, .text)
                t.column(Balance.Columns.balance.name, .text).notNull()
            })
        }

        return migrator
    }
}

extension AccountInfoStorage {
    var tonBalance: BigUInt? {
        try! dbPool.read { db in
            try Balance.filter(Balance.Columns.id == Kit.tonId).fetchOne(db)?.balance
        }
    }
    
    var jettons: [Jetton] {
        try! dbPool.read { db in
            try Balance
                .filter(Balance.Columns.id != Kit.tonId)
                .fetchAll(db)
                .compactMap { Jetton(balance: $0) }
        }
    }

    func jettonBalance(address: String) -> BigUInt? {
        try! dbPool.read { db in
            try Balance.filter(Balance.Columns.id == Kit.jettonId(address: address)).fetchOne(db)?.balance
        }
    }

    func save(tonBalance: BigUInt) {
        _ = try! dbPool.write { db in
            let balance = Balance(id: Kit.tonId, wallet: nil, balance: tonBalance)
            try balance.insert(db)
        }
    }

    func save(jettonBalances: [JettonBalance]) {
        _ = try! dbPool.write { db in
            for balance in jettonBalances {
                let balance = Balance(
                    id: Kit.jettonId(address: balance.item.jettonInfo.address.toRaw()),
                    wallet: balance.item.walletAddress.toRaw(),
                    balance: balance.quantity
                )
                try balance.insert(db)
            }
        }
    }

    func clearJettonBalances() {
        _ = try! dbPool.write { db in
            try Balance.filter(Balance.Columns.id != Kit.tonId).deleteAll(db)
        }
    }
}
