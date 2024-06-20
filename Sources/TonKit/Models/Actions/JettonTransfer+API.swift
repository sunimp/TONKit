import Foundation
import TonAPI
import TonSwift
import BigInt

extension JettonTransfer {
    convenience init(eventId: String, index: Int, action: Components.Schemas.JettonTransferAction) throws {
        let sender = try? action.sender.map { try WalletAccount(accountAddress: $0) }
        let recipient = try? action.recipient.map { try WalletAccount(accountAddress: $0) }
        let senderAddress = try Address.parse(action.senders_wallet)
        let recipientAddress = try Address.parse(action.recipients_wallet)
        let jettonAddress = try Address.parse(action.jetton.address)
        guard let amount = BigUInt(action.amount, radix: 10) else {
            throw Kit.KitError.parsingError
        }
        let comment = action.comment

        self.init(
            eventId: eventId,
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
