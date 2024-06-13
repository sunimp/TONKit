import BigInt
import Foundation
import GRDB

class AccountInfoStorage {
    private let dbPool: DatabasePool

    init(databaseDirectoryUrl: URL, databaseFileName: String) {
        let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try! migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createBalances") { db in
            try db.create(table: Balance.databaseTableName, body: { t in
                t.column(Balance.Columns.id.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(Balance.Columns.balance.name, .text).notNull()
            })
        }

        return migrator
    }

    private var tonId = "TON"
    private func jettonId(address: String) -> String { "TON/\(address)" }
}

extension AccountInfoStorage {
    var tonBalance: BigUInt? {
        try! dbPool.read { db in
            try Balance.filter(Balance.Columns.id == tonId).fetchOne(db)?.balance
        }
    }

    func jettonBalance(address: String) -> BigUInt? {
        try! dbPool.read { db in
            try Balance.filter(Balance.Columns.id == jettonId(address: address)).fetchOne(db)?.balance
        }
    }

    func save(tonBalance: BigUInt) {
        _ = try! dbPool.write { db in
            let balance = Balance(id: tonId, balance: tonBalance)
            try balance.insert(db)
        }
    }

    func save(jettonBalance: BigUInt, address: String) {
        _ = try! dbPool.write { db in
            let balance = Balance(id: jettonId(address: address), balance: jettonBalance)
            try balance.insert(db)
        }
    }

    func clearJettonBalances() {
        _ = try! dbPool.write { db in
            try Balance.filter(Balance.Columns.id != tonId).deleteAll(db)
        }
    }
}
