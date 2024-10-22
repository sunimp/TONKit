//
//  JettonBalance.swift
//  TONKit
//
//  Created by Sun on 2024/10/22.
//

import BigInt
import Foundation
import GRDB
import TONSwift

// MARK: - JettonBalance

public struct JettonBalance: Codable, Equatable, Hashable {
    // MARK: Properties

    public let jettonAddress: Address
    public let jetton: Jetton
    public let balance: BigUInt
    public let walletAddress: Address

    // MARK: Lifecycle

    init(jetton: Jetton, balance: BigUInt, walletAddress: Address) {
        jettonAddress = jetton.address
        self.jetton = jetton
        self.balance = balance
        self.walletAddress = walletAddress
    }
}

// MARK: FetchableRecord, PersistableRecord

extension JettonBalance: FetchableRecord, PersistableRecord {
    enum Columns {
        static let jettonAddress = Column(CodingKeys.jettonAddress)
        static let jetton = Column(CodingKeys.jetton)
        static let balance = Column(CodingKeys.balance)
        static let walletAddress = Column(CodingKeys.walletAddress)
    }
}
