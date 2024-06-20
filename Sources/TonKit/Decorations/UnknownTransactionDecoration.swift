import BigInt
import Foundation
import TonSwift

open class UnknownTransactionDecoration: TransactionDecoration {
    public let actions: [Action]

    init(actions: [Action]) {
        self.actions = actions
        super.init()
    }
    
    required public init?(address: Address, actions: [Action]) {
        self.actions = actions
        super.init(address: address, actions: actions)
    }
    
    override public func tags(userAddress: Address) -> [TransactionTag] {
        Array(Set(tagsFromActions(userAddress: userAddress)))
    }

    private func tagsFromActions(userAddress _: Address) -> [TransactionTag] {
        []
    }
}
