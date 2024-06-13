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
            comment,
        ].compactMap { $0 }.joined(separator: "|")
    }
}
