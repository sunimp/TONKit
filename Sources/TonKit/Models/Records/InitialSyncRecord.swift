//
//  InitialSyncCompleted.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import GRDB

class InitialSyncCompleted: Record {
    let api: String
    let id: String
    let completed: Bool

    init(api: String, id: String, completed: Bool) {
        self.api = api
        self.id = id
        self.completed = completed

        super.init()
    }

    override public class var databaseTableName: String {
        "initial_sync_completed"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case api
        case id
        case completed
    }

    required init(row: Row) throws {
        api = row[Columns.api]
        id = row[Columns.id]
        completed = row[Columns.completed]

        try super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) {
        container[Columns.api] = api
        container[Columns.id] = id
        container[Columns.completed] = completed
    }
}
