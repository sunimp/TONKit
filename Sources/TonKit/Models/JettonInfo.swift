//
//  JettonInfo.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import TonSwift

public struct JettonInfo: Codable, Equatable, Hashable {
    
    public enum Verification: Codable {
        case none
        case unknown
        case whitelist
        case blacklist
    }

    public let address: TonSwift.Address
    public let fractionDigits: Int
    public let name: String
    public let symbol: String?
    public let verification: Verification
    public let imageURL: URL?

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.address == rhs.address
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }
}
