//
//  FullTransaction.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

public class FullTransaction {
    // MARK: Properties

    public let event: AccountEvent
    public let decoration: TransactionDecoration

    // MARK: Lifecycle

    init(event: AccountEvent, decoration: TransactionDecoration) {
        self.event = event
        self.decoration = decoration
    }
}
