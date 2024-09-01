//
//  AccountEventStatus.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import GRDB

enum AccountEventStatus: Codable, DatabaseValueConvertible {
    case ok
    case failed
    case unknown(String)

    var rawValue: String? {
        switch self {
        case .ok: return nil
        case .failed: return "Failed"
        case .unknown(let value):
            return value
        }
    }

    init(rawValue: String) {
        switch rawValue {
        case "ok": self = .ok
        case "failed": self = .failed
        default: self = .unknown(rawValue)
        }
    }

    var isOk: Bool {
        switch self {
        case .ok: return true
        default: return false
        }
    }
}
