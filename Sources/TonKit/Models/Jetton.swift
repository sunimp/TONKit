//
//  Jetton.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import TonSwift

public struct Jetton {
    public let address: Address
    public let walletAddress: Address
    
    init(address: Address, walletAddress: Address) {
        self.address = address
        self.walletAddress = walletAddress
    }
    
    init?(balance: Balance) {
        let raw = Kit.address(jettonId: balance.id)
        guard let address = try? Address.parse(raw: raw) else { return nil }
        guard
            let walletRaw = balance.wallet,
            let walletAddress = try? Address.parse(raw: walletRaw)
        else { return nil }
        
        self.address = address
        self.walletAddress = walletAddress
    }
}
