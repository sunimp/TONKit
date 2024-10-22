//
//  AccountAddress.swift
//  TONKit
//
//  Created by Sun on 2024/10/22.
//

import TONSwift

public struct AccountAddress: Codable {
    public var address: Address
    public var name: String?
    public var isScam: Bool
    public var isWallet: Bool
}
