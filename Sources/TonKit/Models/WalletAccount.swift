//
//  WalletAccount.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import GRDB
import TonAPI
import TonSwift

public struct WalletAccount: Codable {
    public let address: Address
    public let name: String?
    public let isScam: Bool
    public let isWallet: Bool

    public init(address: Address, name: String?, isScam: Bool, isWallet: Bool) {
        self.address = address
        self.name = name
        self.isScam = isScam
        self.isWallet = isWallet
    }
}
