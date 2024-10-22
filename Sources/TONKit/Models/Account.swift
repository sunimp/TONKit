//
//  Account.swift
//  TONKit
//
//  Created by Sun on 2024/6/13.
//

import BigInt
import Foundation
import GRDB
import TONSwift

// MARK: - Account

public struct Account: Codable, Equatable {
    public let address: Address
    public let balance: BigUInt
    public let status: Status
}

// MARK: FetchableRecord, PersistableRecord

extension Account: FetchableRecord, PersistableRecord {
    enum Columns {
        static let address = Column(CodingKeys.address)
        static let balance = Column(CodingKeys.balance)
        static let status = Column(CodingKeys.status)
    }
}

// MARK: Account.Status

extension Account {
    public enum Status: String, Codable {
        case nonexist
        case uninit
        case active
        case frozen
        case unknown
    }
}
