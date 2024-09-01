//
//  TransactionDecoration.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import TonSwift

open class TransactionDecoration {
    public init() { }
    public required init?(address _: Address, actions _: [Action]) { }

    open func tags(userAddress _: Address) -> [TransactionTag] {
        []
    }
}
