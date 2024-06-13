import GRDB

class InitialSyncCompleted: Record {
    let api: String
    let completed: Bool

    init(api: String, completed: Bool) {
        self.api = api
        self.completed = completed

        super.init()
    }

    override public class var databaseTableName: String {
        "initial_sync_completed"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case api
        case completed
    }

    required init(row: Row) throws {
        api = row[Columns.api]
        completed = row[Columns.completed]

        try super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) {
        container[Columns.api] = api
        container[Columns.completed] = completed
    }
}
