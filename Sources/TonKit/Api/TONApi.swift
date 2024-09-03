//
//  TONApi.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import BigInt
import OpenAPIRuntime
import TonAPI
import TonStreamingAPI
import TonSwift

// MARK: - TONApi

struct TONApi {
    // MARK: Properties

    let url: URL

    private let urlSession: URLSession

    // MARK: Lifecycle

    init(urlSession: URLSession, url: URL) {
        self.urlSession = urlSession
        self.url = url
    }
}

// MARK: - Account

extension TONApi {
    func getAccountInfo(address: Address) async throws -> Account {
        let response = try await AccountsAPI.getAccount(accountId: address.toRaw())
        return try Account(account: response)
    }

    func getAccountJettonsBalances(address: Address, currencies: [String]) async throws -> [JettonBalance] {
        let response = try await AccountsAPI.getAccountJettonsBalances(
            accountId: address.toRaw(),
            currencies: currencies
        )
        return response.balances
            .compactMap { jetton in
                do {
                    let quantity = BigUInt(stringLiteral: jetton.balance)
                    let walletAddress = try Address.parse(jetton.walletAddress.address)
                    let jettonInfo = try JettonInfo(jettonPreview: jetton.jetton)
                    let jettonItem = JettonItem(jettonInfo: jettonInfo, walletAddress: walletAddress)
                    return JettonBalance(item: jettonItem, quantity: quantity)
                } catch {
                    return nil
                }
            }
    }
}

//// MARK: - Events

extension TONApi {
    func getAccountEvents(
        address: Address,
        beforeLt: Int64?,
        limit: Int,
        start: Int64? = nil,
        end: Int64? = nil
    ) async throws
        -> AccountEvents {
        let response = try await AccountsAPI.getAccountEvents(
            accountId: address.toRaw(),
            limit: limit,
            beforeLt: beforeLt,
            startDate: start,
            endDate: end
        )
        let events: [AccountEvent] = response.events.compactMap {
            guard let activityEvent = try? AccountEvent(accountEvent: $0) else {
                return nil
            }
            return activityEvent
        }
        return AccountEvents(
            address: address,
            events: events,
            startFrom: beforeLt ?? 0,
            nextFrom: response.nextFrom
        )
    }

    func getAccountJettonEvents(
        address: Address,
        jettonInfo: JettonInfo,
        beforeLt: Int64?,
        limit: Int,
        start: Int64? = nil,
        end: Int64? = nil
    ) async throws
        -> AccountEvents {
        let response = try await AccountsAPI.getAccountJettonHistoryByID(
            accountId: address.toRaw(),
            jettonId: jettonInfo.address.toRaw(),
            limit: limit,
            beforeLt: beforeLt,
            startDate: start,
            endDate: end
        )
        let events: [AccountEvent] = response.events.compactMap {
            guard let activityEvent = try? AccountEvent(accountEvent: $0) else {
                return nil
            }
            return activityEvent
        }
        return AccountEvents(
            address: address,
            events: events,
            startFrom: beforeLt ?? 0,
            nextFrom: response.nextFrom
        )
    }

    func getEvent(
        address: Address,
        eventID: String
    ) async throws
        -> AccountEvent {
        let response = try await AccountsAPI.getAccountEvent(
            accountId: address.toRaw(),
            eventId: eventID
        )
        return try AccountEvent(accountEvent: response)
    }
}

// MARK: - Wallet

extension TONApi {
    func getSeqno(address: Address) async throws -> Int {
        try await WalletAPI.getAccountSeqno(accountId: address.toRaw()).seqno
    }

    func emulateMessageWallet(boc: String) async throws -> TonAPI.MessageConsequences {
        try await EmulationAPI.emulateMessageToWallet(
            emulateMessageToWalletRequest: .init(boc: boc)
        )
    }

    func sendTransaction(boc: String) async throws {
        try await BlockchainAPI.sendBlockchainMessage(
            sendBlockchainMessageRequest: .init(boc: boc)
        )
    }
}

//// MARK: - NFTs
//
// extension TONApi {
//    func getAccountNftItems(address: Address,
//                            collectionAddress: Address?,
//                            limit: Int?,
//                            offset: Int?,
//                            isIndirectOwnership: Bool) async throws -> [Nft]
//    {
//        let response = try await tonAPIClient.getAccountNftItems(
//            path: .init(account_id: address.toRaw()),
//            query: .init(collection: collectionAddress?.toRaw(),
//                         limit: limit,
//                         offset: offset,
//                         indirect_ownership: isIndirectOwnership)
//        )
//        let entity = try response.ok.body.json
//        let collectibles = entity.nft_items.compactMap {
//            try? Nft(nftItem: $0)
//        }
//
//        return collectibles
//    }
//
//    func getNftItemsByAddresses(_ addresses: [Address]) async throws -> [Nft] {
//        let response = try await tonAPIClient
//            .getNftItemsByAddresses(
//                .init(
//                    body: .json(.init(account_ids: addresses.map { $0.toRaw() })))
//            )
//        let entity = try response.ok.body.json
//        let nfts = entity.nft_items.compactMap {
//            try? Nft(nftItem: $0)
//        }
//        return nfts
//    }
// }

// MARK: - Jettons

extension TONApi {
    func resolveJetton(address: Address) async throws -> JettonInfo {
        let response = try await JettonsAPI.getJettonInfo(accountId: address.toRaw())
        let verification: JettonInfo.Verification =
            switch response.verification {
            case ._none:
                .none
            case .unknownDefaultOpenApi:
                .unknown
            case .blacklist:
                .blacklist
            case .whitelist:
                .whitelist
            }

        return try JettonInfo(
            address: Address.parse(response.metadata.address),
            fractionDigits: Int(response.metadata.decimals) ?? 0,
            name: response.metadata.name,
            symbol: response.metadata.symbol,
            verification: verification,
            imageURL: URL(string: response.metadata.image ?? "")
        )
    }
}

// MARK: - DNS

extension TONApi {
    enum DNSError: Swift.Error {
        case noWalletData
    }
    
    func resolveDomainName(_ domainName: String) async throws -> FriendlyAddress {
        let response = try await DNSAPI.dnsResolve(domainName: domainName)
        guard let wallet = response.wallet else {
            throw DNSError.noWalletData
        }
        
        let address = try Address.parse(wallet.address)
        return FriendlyAddress(address: address, bounceable: !wallet.isWallet)
    }
    
    func getDomainExpirationDate(_ domainName: String) async throws -> Date? {
        let response = try await DNSAPI.getDnsInfo(domainName: domainName)
        guard let expiringAt = response.expiringAt else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(integerLiteral: Int64(expiringAt)))
    }
}

// MARK: TONApi.APIError

extension TONApi {
    enum APIError: Swift.Error {
        case incorrectResponse
        case serverError(statusCode: Int)
    }
}

// MARK: - Time

extension TONApi {
    func time() async throws -> TimeInterval {
        let response = try await LiteServerAPI.getRawTime()
        return TimeInterval(response.time)
    }

    func timeoutSafely(TTL: UInt64 = 5 * 60) async -> UInt64 {
        do {
            let time = try await time()
            return UInt64(time) + TTL
        } catch {
            return UInt64(Date().timeIntervalSince1970) + TTL
        }
    }
}
