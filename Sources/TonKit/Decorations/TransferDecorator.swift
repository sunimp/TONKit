//
//  TransferDecorator.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import BigInt
import TonSwift

// MARK: - TransferDecorator

class TransferDecorator {
    private let address: Address
    var decorations = [TransactionDecoration.Type]()

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
