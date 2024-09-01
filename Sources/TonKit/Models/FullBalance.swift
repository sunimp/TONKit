//
//  FullBalance.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import BigInt
import TonAPI
import TonSwift

// MARK: - FullBalance

public struct FullBalance: Codable {
    public let tonBalance: TonBalance
    public let jettonsBalance: [JettonBalance]
}

extension FullBalance {
    public var isEmpty: Bool {
        tonBalance.amount == 0 && jettonsBalance.isEmpty
    }
}

// MARK: - TonBalance

public struct TonBalance: Codable {
    public let amount: Int64
}

// MARK: - JettonBalance

public struct JettonBalance: Codable {
    public let item: JettonItem
    public let quantity: BigUInt
}

// MARK: - JettonItem

public struct JettonItem: Codable, Equatable {
    public let jettonInfo: JettonInfo
    public let walletAddress: TonSwift.Address
}

// MARK: - TonInfo

public struct TonInfo {
    public static let name = "Toncoin"
    public static let symbol = "TON"
    public static let fractionDigits = 9
    private init() { }
}
