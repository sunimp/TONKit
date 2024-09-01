//
//  Action.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
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
    public let eventId: String
    public let index: Int

    public init(eventId: String, index: Int) {
        self.eventId = eventId
        self.index = index
    }
}

// MARK: Comparable

extension Action: Comparable {
    public static func < (lhs: Action, rhs: Action) -> Bool {
        lhs.index < rhs.index
    }

    public static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.index == rhs.index && lhs.eventId == rhs.eventId
    }
}
