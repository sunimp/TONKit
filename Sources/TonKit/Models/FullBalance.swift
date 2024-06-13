import BigInt
import Foundation
import TonAPI
import TonSwift

public struct FullBalance: Codable {
    public let tonBalance: TonBalance
    public let jettonsBalance: [JettonBalance]
}

public extension FullBalance {
    var isEmpty: Bool {
        tonBalance.amount == 0 && jettonsBalance.isEmpty
    }
}

public struct TonBalance: Codable {
    public let amount: Int64
}

public struct JettonBalance: Codable {
    public let item: JettonItem
    public let quantity: BigUInt
}

public struct JettonItem: Codable, Equatable {
    public let jettonInfo: JettonInfo
    public let walletAddress: TonSwift.Address
}

public struct TonInfo {
    public static let name = "Toncoin"
    public static let symbol = "TON"
    public static let fractionDigits = 9
    private init() {}
}
