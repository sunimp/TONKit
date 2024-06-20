import TonSwift

open class TransactionDecoration {
    public init() {}
    required public init?(address: Address, actions: [Action]) {}

    open func tags(userAddress _: Address) -> [TransactionTag] {
        []
    }
}
