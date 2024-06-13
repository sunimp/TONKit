import Foundation
import TonAPI
import TonSwift

extension Account {
    init(account: Components.Schemas.Account) throws {
        address = try Address.parse(account.address)
        balance = account.balance
        status = account.status
        name = account.name
        icon = account.icon
        isSuspended = account.is_suspended
        isWallet = account.is_wallet
    }
}
