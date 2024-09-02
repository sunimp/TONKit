//
//  Jetton.swift
//
//  Created by Sun on 2024/6/20.
//

import Foundation

import TonSwift

public struct Jetton {
    // MARK: Properties

    public let address: Address
    public let walletAddress: Address

    // MARK: Lifecycle

    init(address: Address, walletAddress: Address) {
        self.address = address
        self.walletAddress = walletAddress
    }
    
    init?(balance: Balance) {
        let raw = Kit.address(jettonID: balance.id)
        guard let address = try? Address.parse(raw: raw) else {
            return nil
        }
        guard
            let walletRaw = balance.wallet,
            let walletAddress = try? Address.parse(raw: walletRaw)
        else {
            return nil
        }
        
        self.address = address
        self.walletAddress = walletAddress
    }
}
