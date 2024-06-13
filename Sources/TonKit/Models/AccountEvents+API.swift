import BigInt
import Foundation
import TonAPI
import TonSwift

extension AccountEvent {
    init(accountEvent: Components.Schemas.AccountEvent) throws {
        let account = try WalletAccount(accountAddress: accountEvent.account)
        let actions = Action.from(eventId: accountEvent.event_id, actions: accountEvent.actions)
        guard !actions.isEmpty else {
            throw Action.MapError.unsupported
        }
        self.init(
            eventId: accountEvent.event_id,
            timestamp: TimeInterval(accountEvent.timestamp),
            account: account,
            isScam: accountEvent.is_scam,
            isInProgress: accountEvent.in_progress,
            fee: accountEvent.extra,
            lt: accountEvent.lt,
            actions: actions
        )
    }
}

// extension AccountEventAction.JettonTransfer {
//    init(jettonTransfer: Components.Schemas.JettonTransferAction) throws {
//        var sender: WalletAccount?
//        var recipient: WalletAccount?
//        if let senderAccountAddress = jettonTransfer.sender {
//            sender = try? WalletAccount(accountAddress: senderAccountAddress)
//        }
//        if let recipientAccountAddress = jettonTransfer.recipient {
//            recipient = try? WalletAccount(accountAddress: recipientAccountAddress)
//        }
//
//        self.sender = sender
//        self.recipient = recipient
//        senderAddress = try TonSwift.Address.parse(jettonTransfer.senders_wallet)
//        recipientAddress = try TonSwift.Address.parse(jettonTransfer.recipients_wallet)
//        amount = BigUInt(stringLiteral: jettonTransfer.amount)
//        jettonInfo = try JettonInfo(jettonPreview: jettonTransfer.jetton)
//        comment = jettonTransfer.comment
//    }
// }
//
// extension AccountEventAction.ContractDeploy {
//    init(contractDeploy: Components.Schemas.ContractDeployAction) throws {
//        address = try TonSwift.Address.parse(contractDeploy.address)
//    }
// }
//
// extension AccountEventAction.NFTItemTransfer {
//    init(nftItemTransfer: Components.Schemas.NftItemTransferAction) throws {
//        var sender: WalletAccount?
//        var recipient: WalletAccount?
//        if let senderAccountAddress = nftItemTransfer.sender {
//            sender = try? WalletAccount(accountAddress: senderAccountAddress)
//        }
//        if let recipientAccountAddress = nftItemTransfer.recipient {
//            recipient = try? WalletAccount(accountAddress: recipientAccountAddress)
//        }
//
//        self.sender = sender
//        self.recipient = recipient
//        nftAddress = try TonSwift.Address.parse(nftItemTransfer.nft)
//        comment = nftItemTransfer.comment
//        payload = nftItemTransfer.payload
//    }
// }
//
// extension AccountEventAction.Subscription {
//    init(subscription: Components.Schemas.SubscriptionAction) throws {
//        subscriber = try WalletAccount(accountAddress: subscription.subscriber)
//        subscriptionAddress = try TonSwift.Address.parse(subscription.subscription)
//        beneficiary = try WalletAccount(accountAddress: subscription.beneficiary)
//        amount = subscription.amount
//        isInitial = subscription.initial
//    }
// }
//
// extension AccountEventAction.Unsubscription {
//    init(unsubscription: Components.Schemas.UnSubscriptionAction) throws {
//        subscriber = try WalletAccount(accountAddress: unsubscription.subscriber)
//        subscriptionAddress = try TonSwift.Address.parse(unsubscription.subscription)
//        beneficiary = try WalletAccount(accountAddress: unsubscription.beneficiary)
//    }
// }
//
// extension AccountEventAction.AuctionBid {
//    init(auctionBid: Components.Schemas.AuctionBidAction) throws {
//        auctionType = auctionBid.auction_type
//        price = AccountEventAction.Price(price: auctionBid.amount)
//        bidder = try WalletAccount(accountAddress: auctionBid.bidder)
//        auction = try WalletAccount(accountAddress: auctionBid.auction)
//
//        var nft: Nft?
//        if let auctionBidNft = auctionBid.nft {
//            nft = try Nft(nftItem: auctionBidNft)
//        }
//        self.nft = nft
//    }
// }
//
// extension AccountEventAction.NFTPurchase {
//    init(nftPurchase: Components.Schemas.NftPurchaseAction) throws {
//        auctionType = nftPurchase.auction_type
//        nft = try Nft(nftItem: nftPurchase.nft)
//        seller = try WalletAccount(accountAddress: nftPurchase.seller)
//        buyer = try WalletAccount(accountAddress: nftPurchase.buyer)
//        price = BigUInt(stringLiteral: nftPurchase.amount.value)
//    }
// }
//
// extension AccountEventAction.DepositStake {
//    init(depositStake: Components.Schemas.DepositStakeAction) throws {
//        amount = depositStake.amount
//        staker = try WalletAccount(accountAddress: depositStake.staker)
//        pool = try WalletAccount(accountAddress: depositStake.pool)
//    }
// }
//
// extension AccountEventAction.WithdrawStake {
//    init(withdrawStake: Components.Schemas.WithdrawStakeAction) throws {
//        amount = withdrawStake.amount
//        staker = try WalletAccount(accountAddress: withdrawStake.staker)
//        pool = try WalletAccount(accountAddress: withdrawStake.pool)
//    }
// }
//
// extension AccountEventAction.WithdrawStakeRequest {
//    init(withdrawStakeRequest: Components.Schemas.WithdrawStakeRequestAction) throws {
//        amount = withdrawStakeRequest.amount
//        staker = try WalletAccount(accountAddress: withdrawStakeRequest.staker)
//        pool = try WalletAccount(accountAddress: withdrawStakeRequest.pool)
//    }
// }
//
// extension AccountEventAction.RecoverStake {
//    init(recoverStake: Components.Schemas.ElectionsRecoverStakeAction) throws {
//        amount = recoverStake.amount
//        staker = try WalletAccount(accountAddress: recoverStake.staker)
//    }
// }
//
// extension AccountEventAction.JettonSwap {
//    init(jettonSwap: Components.Schemas.JettonSwapAction) throws {
//        dex = jettonSwap.dex
//        amountIn = BigUInt(stringLiteral: jettonSwap.amount_in)
//        amountOut = BigUInt(stringLiteral: jettonSwap.amount_out)
//        tonIn = jettonSwap.ton_in
//        tonOut = jettonSwap.ton_out
//        user = try WalletAccount(accountAddress: jettonSwap.user_wallet)
//        router = try WalletAccount(accountAddress: jettonSwap.router)
//        if let jettonMasterIn = jettonSwap.jetton_master_in {
//            jettonInfoIn = try JettonInfo(jettonPreview: jettonMasterIn)
//        } else {
//            jettonInfoIn = nil
//        }
//        if let jettonMasterOut = jettonSwap.jetton_master_out {
//            jettonInfoOut = try JettonInfo(jettonPreview: jettonMasterOut)
//        } else {
//            jettonInfoOut = nil
//        }
//    }
// }
//
// extension AccountEventAction.JettonMint {
//    init(jettonMint: Components.Schemas.JettonMintAction) throws {
//        recipient = try WalletAccount(accountAddress: jettonMint.recipient)
//        recipientsWallet = try TonSwift.Address.parse(jettonMint.recipients_wallet)
//        amount = BigUInt(stringLiteral: jettonMint.amount)
//        jettonInfo = try JettonInfo(jettonPreview: jettonMint.jetton)
//    }
// }
//
// extension AccountEventAction.JettonBurn {
//    init(jettonBurn: Components.Schemas.JettonBurnAction) throws {
//        sender = try WalletAccount(accountAddress: jettonBurn.sender)
//        senderWallet = try TonSwift.Address.parse(jettonBurn.senders_wallet)
//        amount = BigUInt(stringLiteral: jettonBurn.amount)
//        jettonInfo = try JettonInfo(jettonPreview: jettonBurn.jetton)
//    }
// }
//
// extension AccountEventAction.SmartContractExec {
//    init(smartContractExec: Components.Schemas.SmartContractAction) throws {
//        executor = try WalletAccount(accountAddress: smartContractExec.executor)
//        contract = try WalletAccount(accountAddress: smartContractExec.contract)
//        tonAttached = smartContractExec.ton_attached
//        operation = smartContractExec.operation
//        payload = smartContractExec.payload
//    }
// }
//
// extension AccountEventAction.DomainRenew {
//    init(domainRenew: Components.Schemas.DomainRenewAction) throws {
//        domain = domainRenew.domain
//        contractAddress = domainRenew.contract_address
//        renewer = try WalletAccount(accountAddress: domainRenew.renewer)
//    }
// }
//
// extension AccountEventAction.Price {
//    init(price: Components.Schemas.Price) {
//        amount = BigUInt(stringLiteral: price.value)
//        tokenName = price.token_name
//    }
// }
