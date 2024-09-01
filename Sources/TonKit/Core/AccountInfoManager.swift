//
//  AccountInfoManager.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import BigInt
import Combine
import TonSwift
import WWExtensions

// MARK: - AccountInfoManager

class AccountInfoManager {
    private let storage: AccountInfoStorage

    init(storage: AccountInfoStorage) {
        self.storage = storage
    }

    private let tonBalanceSubject = PassthroughSubject<BigUInt, Never>()
    private let jettonBalanceSubject = PassthroughSubject<(Address, BigUInt), Never>()

    var tonBalance: BigUInt {
        storage.tonBalance ?? 0
    }
}

extension AccountInfoManager {
    var tonBalancePublisher: AnyPublisher<BigUInt, Never> {
        tonBalanceSubject.eraseToAnyPublisher()
    }

    func jettonBalance(address: Address) -> BigUInt {
        storage.jettonBalance(address: address.toRaw()) ?? 0
    }

    func jettonBalancePublisher(address: Address) -> AnyPublisher<BigUInt, Never> {
        jettonBalanceSubject.filter { $0.0 == address }.map { $0.1 }.eraseToAnyPublisher()
    }
    
    var jettons: [Jetton] {
        storage.jettons
    }

    func handle(account: Account) {
        let tonBalance = BigUInt(account.balance)
        storage.save(tonBalance: tonBalance)
        tonBalanceSubject.send(tonBalance)
    }
    
    func handle(jettonBalances: [JettonBalance]) {
        storage.clearJettonBalances()
        storage.save(jettonBalances: jettonBalances)
        for balance in jettonBalances {
            jettonBalanceSubject.send((balance.item.jettonInfo.address, balance.quantity))
        }
    }
}
