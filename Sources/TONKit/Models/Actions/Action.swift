//
//  Action.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import BigInt
import GRDB
import TonSwift

// MARK: - IActionRecord

protocol IActionRecord {
    func save(db: Database, index: Int, lt: Int64) throws
}

// MARK: - Action

public class Action: Codable {
    // MARK: Properties

    public let eventID: String
    public let index: Int

    // MARK: Lifecycle

    public init(eventID: String, index: Int) {
        self.eventID = eventID
        self.index = index
    }
}

// MARK: Comparable

extension Action: Comparable {
    public static func < (lhs: Action, rhs: Action) -> Bool {
        lhs.index < rhs.index
    }

    public static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.index == rhs.index && lhs.eventID == rhs.eventID
    }
}
