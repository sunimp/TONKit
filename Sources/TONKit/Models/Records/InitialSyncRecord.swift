//
//  InitialSyncRecord.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import GRDB

class InitialSyncCompleted: Record {
    // MARK: Nested Types

    enum Columns: String, ColumnExpression, CaseIterable {
        case api
        case id
        case completed
    }

    // MARK: Overridden Properties

    override public class var databaseTableName: String {
        "initial_sync_completed"
    }

    // MARK: Properties

    let api: String
    let id: String
    let completed: Bool

    // MARK: Lifecycle

    init(api: String, id: String, completed: Bool) {
        self.api = api
        self.id = id
        self.completed = completed

        super.init()
    }

    required init(row: Row) throws {
        api = row[Columns.api]
        id = row[Columns.id]
        completed = row[Columns.completed]

        try super.init(row: row)
    }

    // MARK: Overridden Functions

    override public func encode(to container: inout PersistenceContainer) {
        container[Columns.api] = api
        container[Columns.id] = id
        container[Columns.completed] = completed
    }
}
