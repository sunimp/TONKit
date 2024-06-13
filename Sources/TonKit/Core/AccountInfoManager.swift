import BigInt
import Combine
import HsExtensions
import TonSwift

class AccountInfoManager {
    private let storage: AccountInfoStorage

    init(storage: AccountInfoStorage) {
        self.storage = storage
    }

    private let tonBalanceSubject = PassthroughSubject<BigUInt, Never>()
    private let jettonBalanceSubject = PassthroughSubject<(Address, BigUInt), Never>()

    var tonBalance: BigUInt {
        storage.tonBalance ?? 0
    }
}

extension AccountInfoManager {
    var tonBalancePublisher: AnyPublisher<BigUInt, Never> {
        tonBalanceSubject.eraseToAnyPublisher()
    }

    func jettonBalance(address: Address) -> BigUInt {
        storage.jettonBalance(address: address.toRaw()) ?? 0
    }

    func jettonBalancePublisher(contractAddress: Address) -> AnyPublisher<BigUInt, Never> {
        jettonBalanceSubject.filter { $0.0 == contractAddress }.map { $0.1 }.eraseToAnyPublisher()
    }

    func handle(account: Account) {
        let tonBalance = BigUInt(account.balance)
        storage.save(tonBalance: tonBalance)
        tonBalanceSubject.send(tonBalance)

//        storage.clearTrc20Balances()
//        for (address, value) in accountInfoResponse.jetton {
//            storage.save(jettonBalance: value, address: address.base58)
//            jettonBalanceSubject.send((address, value))
//        }
    }
}
