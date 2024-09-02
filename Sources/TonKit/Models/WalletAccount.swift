//
//  WalletAccount.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import GRDB
import TonAPI
import TonSwift

public struct WalletAccount: Codable {
    // MARK: Properties

    public let address: Address
    public let name: String?
    public let isScam: Bool
    public let isWallet: Bool

    // MARK: Lifecycle

    public init(address: Address, name: String?, isScam: Bool, isWallet: Bool) {
        self.address = address
        self.name = name
        self.isScam = isScam
        self.isWallet = isWallet
    }
}
