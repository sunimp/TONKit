import Foundation
import TonAPI
import TonSwift

extension TonTransfer {
    convenience init(eventId: String, index: Int, action: Components.Schemas.TonTransferAction) throws {
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
