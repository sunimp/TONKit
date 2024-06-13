import BigInt
import TonSwift

class TonTransferDecorator {
    private let address: Address

    init(address: Address) {
        self.address = address
    }
}

extension TonTransferDecorator: ITransactionDecorator {
    public func decoration(actions: [Action]) -> TransactionDecoration? {
        let tonTransfers = actions.compactMap { $0 as? TonTransfer }
        guard tonTransfers.count == actions.count, !tonTransfers.isEmpty else { return nil }
        guard let first = tonTransfers.first else { return nil }

        var amount = BigUInt(0)
        for transfer in tonTransfers {
            amount += BigUInt(transfer.amount)
        }

        if first.sender.address == address {
            return OutgoingDecoration(
                address: address,
                to: first.recipient.address,
                value: amount,
                comment: first.comment,
                sentToSelf: first.recipient.address == address
            )
        } else {
            return IncomingDecoration(
                from: first.sender.address,
                value: amount,
                comment: first.comment
            )
        }
    }
}
