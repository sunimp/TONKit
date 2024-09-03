//
//  SyncState.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

// MARK: - SyncState

public enum SyncState {
    case synced
    case syncing(progress: Double?)
    case notSynced(error: Error)

    // MARK: Computed Properties

    public var notSynced: Bool {
        if case .notSynced = self {
            return true
        } else {
            return false
        }
    }

    public var syncing: Bool {
        if case .syncing = self {
            return true
        } else {
            return false
        }
    }

    public var synced: Bool {
        self == .synced
    }
}

// MARK: Equatable

extension SyncState: Equatable {
    public static func == (lhs: SyncState, rhs: SyncState) -> Bool {
        switch (lhs, rhs) {
        case (.synced, .synced): return true
        case let (.syncing(lhsProgress), .syncing(rhsProgress)): return lhsProgress == rhsProgress
        case let (.notSynced(lhsError), .notSynced(rhsError)): return "\(lhsError)" == "\(rhsError)"
        default: return false
        }
    }
}

// MARK: CustomStringConvertible

extension SyncState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .synced: return "synced"
        case let .syncing(progress): return "syncing \(progress ?? 0)"
        case let .notSynced(error): return "not synced: \(error)"
        }
    }
}
