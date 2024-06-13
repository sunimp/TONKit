import BigInt
import Foundation
import TonSwift

open class UnknownTransactionDecoration: TransactionDecoration {
    public let actions: [Action]

    init(actions: [Action]) {
        self.actions = actions
    }

    override public func tags(userAddress: Address) -> [TransactionTag] {
        Array(Set(tagsFromActions(userAddress: userAddress)))
    }

    private func tagsFromActions(userAddress _: Address) -> [TransactionTag] {
        []
//        let value = value ?? 0
//        let incomingInternalTransactions = internalTransactions.filter { $0.to == userAddress }
//
//        var outgoingValue: Int = 0
//        if fromAddress == userAddress {
//            outgoingValue = value
//        }
//        var incomingValue: Int = 0
//        if toAddress == userAddress {
//            incomingValue = value
//        }
//        incomingInternalTransactions.forEach {
//            incomingValue += $0.value
//        }
//
//        // if has value or has internalTxs must add Evm tag
//        if outgoingValue == 0 && incomingValue == 0 {
//            return []
//        }
//
//        var tags = [TransactionTag]()
//
//        var addresses = [fromAddress, toAddress]
//            .compactMap { $0 }
//            .filter { $0 != userAddress }
//            .map { $0.hex }
//
//        if incomingValue > outgoingValue {
//            tags.append(TransactionTag(type: .incoming, protocol: .native, addresses: addresses))
//        } else if outgoingValue > incomingValue {
//            tags.append(TransactionTag(type: .outgoing, protocol: .native, addresses: addresses))
//        }

//        return tags
    }
}
