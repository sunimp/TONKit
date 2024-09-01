//
//  FullTransaction.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

public class FullTransaction {
    public let event: AccountEvent
    public let decoration: TransactionDecoration

    init(event: AccountEvent, decoration: TransactionDecoration) {
        self.event = event
        self.decoration = decoration
    }
}
