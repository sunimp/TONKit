//
//  DecorationManager.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import BigInt
import TonSwift

// MARK: - DecorationManager

class DecorationManager {
    // MARK: Properties

    private let userAddress: Address
    private var transactionDecorators = [ITransactionDecorator]()

    // MARK: Lifecycle

    init(userAddress: Address) {
        self.userAddress = userAddress
    }

    // MARK: Functions

    private func decoration(event: AccountEvent) -> TransactionDecoration {
        for decorator in transactionDecorators {
            if let decoration = decorator.decoration(actions: event.actions) {
                return decoration
            }
        }

        return UnknownTransactionDecoration(actions: event.actions)
    }
}

extension DecorationManager {
    func add(transactionDecorator: ITransactionDecorator) {
        transactionDecorators.append(transactionDecorator)
    }

    func decorate(events: [AccountEvent]) -> [FullTransaction] {
        return events.map { event in
            let decoration = decoration(event: event)

            return FullTransaction(event: event, decoration: decoration)
        }
    }
}
