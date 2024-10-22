//
//  Action.swift
//  TONKit
//
//  Created by Sun on 2024/10/22.
//

import BigInt
import TONSwift

// MARK: - Action

public struct Action: Codable {
    public let type: Type
    public let status: Status
}

extension Action {
    public enum `Type`: Codable {
        case tonTransfer(action: TonTransfer)
        case jettonTransfer(action: JettonTransfer)
        case jettonBurn(action: JettonBurn)
        case jettonMint(action: JettonMint)
        case contractDeploy(action: ContractDeploy)
        case jettonSwap(action: JettonSwap)
        case smartContract(action: SmartContract)
        case unknown(rawType: String)
    }

    public enum Status: String, Codable {
        case ok
        case failed
        case unknown
    }
}

extension Action {
    public struct TonTransfer: Codable {
        public let sender: AccountAddress
        public let recipient: AccountAddress
        public let amount: BigUInt
        public let comment: String?
    }

    public struct JettonTransfer: Codable {
        public let sender: AccountAddress?
        public let recipient: AccountAddress?
        public let sendersWallet: Address
        public let recipientsWallet: Address
        public let amount: BigUInt
        public let comment: String?
        public let jetton: Jetton
    }

    public struct JettonBurn: Codable {
        public let sender: AccountAddress
        public let sendersWallet: Address
        public let amount: BigUInt
        public let jetton: Jetton
    }

    public struct JettonMint: Codable {
        public let recipient: AccountAddress
        public let recipientsWallet: Address
        public let amount: BigUInt
        public let jetton: Jetton
    }

    public struct ContractDeploy: Codable {
        public let address: Address
        public let interfaces: [String]
    }

    public struct JettonSwap: Codable {
        public let dex: String
        public let amountIn: BigUInt
        public let amountOut: BigUInt
        public let tonIn: BigUInt?
        public let tonOut: BigUInt?
        public let userWallet: AccountAddress
        public let router: AccountAddress
        public let jettonMasterIn: Jetton?
        public let jettonMasterOut: Jetton?
    }

    public struct SmartContract: Codable {
        public let contract: AccountAddress
        public let tonAttached: BigUInt
        public let operation: String
        public let payload: String?
    }
}
