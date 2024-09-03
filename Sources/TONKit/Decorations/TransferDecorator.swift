//
//  TransferDecorator.swift
//
//  Created by Sun on 2024/6/20.
//

import Foundation

import BigInt
import TonSwift

// MARK: - TransferDecorator

class TransferDecorator {
    // MARK: Properties

    var decorations = [TransactionDecoration.Type]()

    private let address: Address

    // MARK: Lifecycle

    init(address: Address) {
        self.address = address
    }
}

// MARK: ITransactionDecorator

extension TransferDecorator: ITransactionDecorator {
    public func decoration(actions: [Action]) -> TransactionDecoration? {
        for decoration in decorations {
            if let transfer = decoration.init(address: address, actions: actions) {
                return transfer
            }
        }
        return nil
    }
}
