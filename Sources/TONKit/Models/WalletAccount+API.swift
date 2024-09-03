//
//  WalletAccount+API.swift
//
//  Created by Sun on 2024/6/13.
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
