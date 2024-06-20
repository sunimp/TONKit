import BigInt
import TonSwift

public class OutgoingDecoration: TransactionDecoration {
    public let address: Address
    public let to: Address
    public let value: BigUInt
    public let comment: String?
    public let sentToSelf: Bool

    init(address: Address, to: Address, value: BigUInt, comment: String?, sentToSelf: Bool) {
        self.address = address
        self.to = to
        self.value = value
        self.comment = comment
        self.sentToSelf = sentToSelf

        super.init()
    }

    required init?(address: Address, actions: [Action]) {
        // Maybe we need to make array of decorations (one decoraction for each different recipient address)
        let transfers = actions.compactMap { $0 as? TonTransfer }

        let amount = IncomingDecoration.incomingAmount(address: address, transfers: transfers)
        guard amount <= 0 else { return nil }

        guard let first = transfers.first(where: { $0.sender.address == address }) else { return nil }

        self.address = address
        self.to = first.recipient.address
        self.value = BigUInt(abs(amount))
        self.comment = first.comment
        self.sentToSelf = first.recipient.address == address
        
        super.init(address: address, actions: actions)
    }

    override public func tags(userAddress _: Address) -> [TransactionTag] {
        var tags = [
            TransactionTag(type: .outgoing, protocol: .native, jettonAddress: nil, addresses: [to.toRaw()]),
        ]

        if sentToSelf {
            tags.append(TransactionTag(type: .incoming, protocol: .native))
        }

        return tags
    }
}

extension OutgoingDecoration: CustomStringConvertible {
    public var description: String {
        [
            "Outgoing",
            value.description,
            to.toRaw(),
            comment,
        ].compactMap { $0 }.joined(separator: "|")
    }
}
