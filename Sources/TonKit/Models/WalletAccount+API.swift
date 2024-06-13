import Foundation
import TonAPI
import TonSwift

extension WalletAccount {
    init(accountAddress: Components.Schemas.AccountAddress) throws {
        let address = try TonSwift.Address.parse(accountAddress.address)
        self.init(
            address: address,
            name: accountAddress.name,
            isScam: accountAddress.is_scam,
            isWallet: accountAddress.is_wallet
        )
    }
}
