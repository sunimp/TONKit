//
//  AccountEventStatus.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import GRDB

enum AccountEventStatus: Codable, DatabaseValueConvertible {
    case ok
    case failed
    case unknown(String)

    // MARK: Computed Properties

    var rawValue: String? {
        switch self {
        case .ok: return nil
        case .failed: return "Failed"
        case let .unknown(value):
            return value
        }
    }

    var isOk: Bool {
        switch self {
        case .ok: return true
        default: return false
        }
    }

    // MARK: Lifecycle

    init(rawValue: String) {
        switch rawValue {
        case "ok": self = .ok
        case "failed": self = .failed
        default: self = .unknown(rawValue)
        }
    }
}
