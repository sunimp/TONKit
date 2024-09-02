//
//  TonTransfer+API.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import TonAPI
import TonSwift

extension TonTransfer {
    convenience init(eventID: String, index: Int, action: TonTransferAction) throws {
        let sender = try WalletAccount(accountAddress: action.sender)
        let recipient = try WalletAccount(accountAddress: action.recipient)
        let amount = action.amount
        let comment = action.comment

        self.init(
            eventID: eventID,
            index: index,
            sender: sender,
            recipient: recipient,
            amount: amount,
            comment: comment
        )
    }
}
