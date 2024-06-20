import BigInt
import TonSwift

class TransferDecorator {
    private let address: Address
    var decorations = [TransactionDecoration.Type]()

    init(address: Address) {
        self.address = address
    }
}

extension TransferDecorator: ITransactionDecorator {
    public func decoration(actions: [Action]) -> TransactionDecoration? {
        for decoration in decorations {
            if let transfer = decoration.init(address: address, actions: actions) {
                return transfer
            }
        }
        return nil
    }
}
