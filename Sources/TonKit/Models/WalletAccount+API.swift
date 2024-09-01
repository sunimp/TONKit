//
//  WalletAccount.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import TonAPI
import TonSwift

extension WalletAccount {
    
    init(accountAddress: TonAPI.AccountAddress) throws {
        let address = try TonSwift.Address.parse(accountAddress.address)
        self.init(
            address: address,
            name: accountAddress.name,
            isScam: accountAddress.isScam,
            isWallet: accountAddress.isWallet
        )
    }
}
