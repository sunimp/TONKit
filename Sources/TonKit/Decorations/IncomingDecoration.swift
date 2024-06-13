import BigInt
import TonSwift

public class IncomingDecoration: TransactionDecoration {
    public let from: Address
    public let value: BigUInt
    public let comment: String?

    init(from: Address, value: BigUInt, comment: String?) {
        self.from = from
        self.value = value
        self.comment = comment
    }

    override public func tags(userAddress _: Address) -> [TransactionTag] {
        [
            TransactionTag(type: .incoming, protocol: .native, addresses: [from.toRaw()]),
        ]
    }
}

extension IncomingDecoration: CustomStringConvertible {
    public var description: String {
        [
            "Incoming",
            value.description,
            comment,
        ].compactMap { $0 }.joined(separator: "|")
    }
}
