//
//  Account+API.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import TonAPI
import TonSwift

extension Account {
    
    init(account: TonAPI.Account) throws {
        address = try Address.parse(account.address)
        balance = account.balance
        status = account.status.rawValue
        name = account.name
        icon = account.icon
        isSuspended = account.isSuspended
        isWallet = account.isWallet
    }
}
