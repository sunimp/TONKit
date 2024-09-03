//
//  UnknownTransactionDecoration.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import BigInt
import TonSwift

open class UnknownTransactionDecoration: TransactionDecoration {
    // MARK: Properties

    public let actions: [Action]

    // MARK: Lifecycle

    public required init?(address: Address, actions: [Action]) {
        self.actions = actions
        super.init(address: address, actions: actions)
    }

    init(actions: [Action]) {
        self.actions = actions
        super.init()
    }

    // MARK: Overridden Functions

    override public func tags(userAddress: Address) -> [TransactionTag] {
        Array(Set(tagsFromActions(userAddress: userAddress)))
    }

    // MARK: Functions

    private func tagsFromActions(userAddress _: Address) -> [TransactionTag] {
        []
    }
}
