//
//  JettonInfo.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import TonSwift

public struct JettonInfo: Codable, Equatable, Hashable {
    // MARK: Nested Types

    public enum Verification: Codable {
        case none
        case unknown
        case whitelist
        case blacklist
    }

    // MARK: Properties

    public let address: TonSwift.Address
    public let fractionDigits: Int
    public let name: String
    public let symbol: String?
    public let verification: Verification
    public let imageURL: URL?

    // MARK: Static Functions

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.address == rhs.address
    }

    // MARK: Functions

    public func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }
}
