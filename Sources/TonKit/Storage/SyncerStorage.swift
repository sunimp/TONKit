import Foundation
import GRDB

class SyncerStorage {
    private let dbPool: DatabasePool

    init(databaseDirectoryUrl: URL, databaseFileName: String) {
        let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try! migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("create Initial Sync Completed") { db in
            try db.create(table: InitialSyncCompleted.databaseTableName) { t in
                t.column(InitialSyncCompleted.Columns.api.name, .text).primaryKey(onConflict: .replace)
                t.column(InitialSyncCompleted.Columns.completed.name, .boolean).notNull()
            }
        }

        return migrator
    }
}

extension SyncerStorage {
    func initialSyncCompleted(api: String) -> Bool? {
        try? dbPool.read { db in
            try InitialSyncCompleted.filter(InitialSyncCompleted.Columns.api == api).fetchOne(db)?.completed
        }
    }

    func save(api: String, initialSyncCompleted: Bool) {
        _ = try! dbPool.write { db in
            let record = InitialSyncCompleted(api: api, completed: initialSyncCompleted)
            try record.insert(db)
        }
    }
}
