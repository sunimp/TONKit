//
//  Account+API.swift
//
//  Created by Sun on 2024/6/13.
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
