//
//  AccountEventAction.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import BigInt
import GRDB
import TonSwift

public class AccountEventAction: Codable {
    let action: Action
    let status: AccountEventStatus

    init(action: Action, status: AccountEventStatus) {
        self.action = action
        self.status = status
    }

    struct ContractDeploy: Codable {
        let address: TonSwift.Address
    }

    struct JettonTransfer: Codable {
        let sender: WalletAccount?
        let recipient: WalletAccount?
        let senderAddress: TonSwift.Address
        let recipientAddress: TonSwift.Address
        let amount: BigUInt
        let jettonInfo: JettonInfo
        let comment: String?
    }

    struct NFTItemTransfer: Codable {
        let sender: WalletAccount?
        let recipient: WalletAccount?
        let nftAddress: TonSwift.Address
        let comment: String?
        let payload: String?
    }

    struct Subscription: Codable {
        let subscriber: WalletAccount
        let subscriptionAddress: TonSwift.Address
        let beneficiary: WalletAccount
        let amount: Int64
        let isInitial: Bool
    }

    struct Unsubscription: Codable {
        let subscriber: WalletAccount
        let subscriptionAddress: TonSwift.Address
        let beneficiary: WalletAccount
    }

    ///    struct AuctionBid: Codable {
    ///        let auctionType: String
    ///        let price: Price
    ///        let nft: Nft?
    ///        let bidder: WalletAccount
    ///        let auction: WalletAccount
    ///    }
    ///
    ///    struct NFTPurchase: Codable {
    ///        let auctionType: String
    ///        let nft: Nft
    ///        let seller: WalletAccount
    ///        let buyer: WalletAccount
    ///        let price: BigUInt
    ///    }
    ///
    struct DepositStake: Codable {
        let amount: Int64
        let staker: WalletAccount
        let pool: WalletAccount
    }

    struct WithdrawStake: Codable {
        let amount: Int64
        let staker: WalletAccount
        let pool: WalletAccount
    }

    struct WithdrawStakeRequest: Codable {
        let amount: Int64?
        let staker: WalletAccount
        let pool: WalletAccount
    }

    struct RecoverStake: Codable {
        let amount: Int64
        let staker: WalletAccount
    }

    struct JettonSwap: Codable {
        let dex: String
        let amountIn: BigUInt
        let amountOut: BigUInt
        let tonIn: Int64?
        let tonOut: Int64?
        let user: WalletAccount
        let router: WalletAccount
        let jettonInfoIn: JettonInfo?
        let jettonInfoOut: JettonInfo?
    }

    struct JettonMint: Codable {
        let recipient: WalletAccount
        let recipientsWallet: TonSwift.Address
        let amount: BigUInt
        let jettonInfo: JettonInfo
    }

    struct JettonBurn: Codable {
        let sender: WalletAccount
        let senderWallet: TonSwift.Address
        let amount: BigUInt
        let jettonInfo: JettonInfo
    }

    struct SmartContractExec: Codable {
        let executor: WalletAccount
        let contract: WalletAccount
        let tonAttached: Int64
        let operation: String
        let payload: String?
    }

    struct DomainRenew: Codable {
        let domain: String
        let contractAddress: String
        let renewer: WalletAccount
    }

    struct Price: Codable {
        let amount: BigUInt
        let tokenName: String
    }
}
