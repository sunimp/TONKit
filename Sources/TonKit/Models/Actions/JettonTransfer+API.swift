//
//  JettonTransfer+API.swift
//
//  Created by Sun on 2024/6/20.
//

import Foundation

import BigInt
import TonAPI
import TonSwift

extension JettonTransfer {
    convenience init(eventID: String, index: Int, action: JettonTransferAction) throws {
        let sender = try? action.sender.map { try WalletAccount(accountAddress: $0) }
        let recipient = try? action.recipient.map { try WalletAccount(accountAddress: $0) }
        let senderAddress = try Address.parse(action.sendersWallet)
        let recipientAddress = try Address.parse(action.recipientsWallet)
        let jettonAddress = try Address.parse(action.jetton.address)
        guard let amount = BigUInt(action.amount, radix: 10) else {
            throw Kit.KitError.parsingError
        }
        let comment = action.comment

        self.init(
            eventID: eventID,
            index: index,
            sender: sender,
            recipient: recipient,
            senderAddress: senderAddress,
            recipientAddress: recipientAddress,
            amount: amount,
            jettonAddress: jettonAddress,
            comment: comment
        )
    }
}
