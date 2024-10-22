//
//  Extensions.swift
//  TONKit-Example
//
//  Created by Sun on 2024/10/22.
//

import BigInt
import Foundation
import TONSwift
import TONKit

#if compiler(>=6)
extension String: @retroactive Identifiable { }
#else
extension String: Identifiable { }
#endif

extension String {
    public typealias ID = Int
    public var id: Int {
        return hash
    }
}

extension BigUInt {
    var tonDecimalValue: Decimal? {
        guard let significand = Decimal(string: description) else {
            return nil
        }

        return Decimal(sign: .plus, exponent: -9, significand: significand)
    }

    func decimalValue(decimals: Int) -> Decimal? {
        guard let significand = Decimal(string: description) else {
            return nil
        }

        return Decimal(sign: .plus, exponent: -decimals, significand: significand)
    }
}

extension Address {
    var toFriendlyWallet: String {
        toFriendly(testOnly: Configuration.isTestNet(), bounceable: false).toString()
    }

    var toFriendlyContract: String {
        toFriendly(testOnly: Configuration.isTestNet(), bounceable: true).toString()
    }
}

extension AccountAddress {
    var toFriendly: String {
        isWallet ? address.toFriendlyWallet : address.toFriendlyContract
    }   
}
