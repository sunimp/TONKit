//
//  TonTransfer.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import TonAPI
import TonSwift

extension TonTransfer {
    
    convenience init(eventId: String, index: Int, action: TonTransferAction) throws {
        let sender = try WalletAccount(accountAddress: action.sender)
        let recipient = try WalletAccount(accountAddress: action.recipient)
        let amount = action.amount
        let comment = action.comment

        self.init(
            eventId: eventId,
            index: index,
            sender: sender,
            recipient: recipient,
            amount: amount,
            comment: comment
        )
    }
}
