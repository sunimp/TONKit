//
//  Jetton.swift
//  TONKit
//
//  Created by Sun on 2024/6/20.
//

import Foundation
import TONSwift

// MARK: - Jetton

public struct Jetton: Codable, Equatable, Hashable {
    public let address: Address
    public let name: String
    public let symbol: String
    public let decimals: Int
    public let image: String?
    public let verification: VerificationType
}

// MARK: Jetton.VerificationType

extension Jetton {
    public enum VerificationType: String, Codable {
        case whitelist
        case blacklist
        case none
        case unknown
    }
}
