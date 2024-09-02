//
//  TransactionDecoration.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import TonSwift

open class TransactionDecoration {
    // MARK: Lifecycle

    public init() { }
    public required init?(address _: Address, actions _: [Action]) { }

    // MARK: Functions

    open func tags(userAddress _: Address) -> [TransactionTag] {
        []
    }
}
