//
//  AccountStorage.swift
//  TONKit
//
//  Created by Sun on 2024/10/22.
//

import Foundation
import GRDB
import TONSwift

// MARK: - AccountStorage

class AccountStorage {
    // MARK: Properties

    private let dbPool: DatabasePool
    
    // MARK: Computed Properties

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("Create account") { db in
            try db.create(table: "account", body: { t in
                t.primaryKey(Account.Columns.address.name, .text, onConflict: .replace)
                t.column(Account.Columns.balance.name, .text).notNull()
                t.column(Account.Columns.status.name, .text).notNull()
            })
        }
        
        return migrator
    }

    // MARK: Lifecycle

    init(dbPool: DatabasePool) throws {
        self.dbPool = dbPool
        
        try migrator.migrate(dbPool)
    }
}

extension AccountStorage {
    func account(address: Address) throws -> Account? {
        try dbPool.read { db in
            try Account.filter(Account.Columns.address == address).fetchOne(db)
        }
    }
    
    func save(account: Account) throws {
        _ = try dbPool.write { db in
            try account.insert(db)
        }
    }
}
