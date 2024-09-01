//
//  TonApi.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import BigInt
import OpenAPIRuntime
import TonAPI
import TonStreamingAPI
import TonSwift

// MARK: - TonApi

struct TonApi {
    
    private let tonAPIClient: TonStreamingAPI.Client
    private let urlSession: URLSession
    let url: URL

    init(tonAPIClient: TonStreamingAPI.Client, urlSession: URLSession, url: URL) {
        self.tonAPIClient = tonAPIClient
        self.urlSession = urlSession
        self.url = url
    }
}

// MARK: - Account

extension TonApi {
    
    func getAccountInfo(address: Address) async throws -> Account {
        let response = try await AccountsAPI.getAccount(accountId: address.toRaw())
        return try Account(account: response)
    }

    func getAccountJettonsBalances(address: Address, currencies: [String]) async throws -> [JettonBalance] {
        let response = try await AccountsAPI.getAccountJettonsBalances(accountId: address.toRaw(), currencies: currencies)
        return response.balances
            .compactMap { jetton in
                do {
                    let quantity = BigUInt(stringLiteral: jetton.balance)
                    let walletAddress = try Address.parse(jetton.walletAddress.address)
                    let jettonInfo = try JettonInfo(jettonPreview: jetton.jetton)
                    let jettonItem = JettonItem(jettonInfo: jettonInfo, walletAddress: walletAddress)
                    let jettonBalance = JettonBalance(item: jettonItem, quantity: quantity)
                    return jettonBalance
                } catch {
                    return nil
                }
            }
    }
}

//// MARK: - Events

extension TonApi {
    
    func getAccountEvents(
        address: Address,
        beforeLt: Int64?,
        limit: Int,
        start: Int64? = nil,
        end: Int64? = nil
    ) async throws -> AccountEvents {
        let response = try await AccountsAPI.getAccountEvents(
            accountId: address.toRaw(),
            limit: limit,
            beforeLt: beforeLt,
            startDate: start,
            endDate: end
        )
        let events: [AccountEvent] = response.events.compactMap {
            guard let activityEvent = try? AccountEvent(accountEvent: $0) else { return nil }
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
    ) async throws -> AccountEvents {
        let response = try await AccountsAPI.getAccountJettonHistoryByID(
            accountId: address.toRaw(),
            jettonId: jettonInfo.address.toRaw(),
            limit: limit,
            beforeLt: beforeLt,
            startDate: start,
            endDate: end
        )
        let events: [AccountEvent] = response.events.compactMap {
            guard let activityEvent = try? AccountEvent(accountEvent: $0) else { return nil }
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
        eventId: String
    ) async throws -> AccountEvent {
        let response = try await AccountsAPI.getAccountEvent(
            accountId: address.toRaw(),
            eventId: eventId
        )
        return try AccountEvent(accountEvent: response)
    }
}

// MARK: - Wallet

extension TonApi {
    
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
// extension TonApi {
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

extension TonApi {
    
    func resolveJetton(address: Address) async throws -> JettonInfo {
        let response = try await JettonsAPI.getJettonInfo(accountId: address.toRaw())
        let verification: JettonInfo.Verification
        switch response.verification {
        case ._none:
            verification = .none
        case .unknownDefaultOpenApi:
            verification = .unknown
        case .blacklist:
            verification = .blacklist
        case .whitelist:
            verification = .whitelist
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

//// MARK: - DNS
//
// extension TonApi {
//  enum DNSError: Swift.Error {
//    case noWalletData
//  }
//
//  func resolveDomainName(_ domainName: String) async throws -> FriendlyAddress {
//    let response = try await tonAPIClient.dnsResolve(path: .init(domain_name: domainName))
//    let entity = try response.ok.body.json
//    guard let wallet = entity.wallet else {
//      throw DNSError.noWalletData
//    }
//
//    let address = try Address.parse(wallet.address)
//    return FriendlyAddress(address: address, bounceable: !wallet.is_wallet)
//  }
//
//  func getDomainExpirationDate(_ domainName: String) async throws -> Date? {
//    let response = try await tonAPIClient.getDnsInfo(path: .init(domain_name: domainName))
//    let entity = try response.ok.body.json
//    guard let expiringAt = entity.expiring_at else { return nil }
//    return Date(timeIntervalSince1970: TimeInterval(integerLiteral: Int64(expiringAt)))
//  }
// }
//
// extension TonApi {
//  enum APIError: Swift.Error {
//    case incorrectResponse
//    case serverError(statusCode: Int)
//  }
// }

// MARK: - Time

extension TonApi {
    
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
