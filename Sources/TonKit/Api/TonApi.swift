import BigInt
import Foundation
import OpenAPIRuntime
import TonAPI
import TonSwift

struct TonApi {
    private let tonAPIClient: TonAPI.Client
    private let urlSession: URLSession
    let url: URL

    init(tonAPIClient: TonAPI.Client, urlSession: URLSession, url: URL) {
        self.tonAPIClient = tonAPIClient
        self.urlSession = urlSession
        self.url = url
    }
}

// MARK: - Account

extension TonApi {
    func getAccountInfo(address: Address) async throws -> Account {
        let response = try await tonAPIClient
            .getAccount(.init(path: .init(account_id: address.toRaw())))
        return try Account(account: response.ok.body.json)
    }

    func getAccountJettonsBalances(address: Address, currencies: [String]) async throws -> [JettonBalance] {
        let currenciesString = currencies.joined(separator: ",")
        let response = try await tonAPIClient
            .getAccountJettonsBalances(path: .init(account_id: address.toRaw()), query: .init(currencies: currenciesString))
        return try response.ok.body.json.balances
            .compactMap { jetton in
                do {
                    let quantity = BigUInt(stringLiteral: jetton.balance)
                    let walletAddress = try Address.parse(jetton.wallet_address.address)
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
    func getAccountEvents(address: Address,
                          beforeLt: Int64?,
                          limit: Int, 
                          start: Int64? = nil,
                          end: Int64? = nil) async throws -> AccountEvents
    {
        let response = try await tonAPIClient.getAccountEvents(
            path: .init(account_id: address.toRaw()),
            query: .init(before_lt: beforeLt,
                         limit: limit,
                         start_date: start,
                         end_date: end)
        )
        let entity = try response.ok.body.json
        let events: [AccountEvent] = entity.events.compactMap {
            guard let activityEvent = try? AccountEvent(accountEvent: $0) else { return nil }
            return activityEvent
        }
        return AccountEvents(address: address,
                             events: events,
                             startFrom: beforeLt ?? 0,
                             nextFrom: entity.next_from)
    }

    func getAccountJettonEvents(address: Address,
                                jettonInfo: JettonInfo,
                                beforeLt: Int64?,
                                limit: Int, 
                                start: Int64? = nil,
                                end: Int64? = nil) async throws -> AccountEvents
    {
        let response = try await tonAPIClient.getAccountJettonHistoryByID(
            path: .init(account_id: address.toRaw(),
                        jetton_id: jettonInfo.address.toRaw()),
            query: .init(before_lt: beforeLt,
                         limit: limit,
                         start_date: start,
                         end_date: end)
        )
        let entity = try response.ok.body.json
        let events: [AccountEvent] = entity.events.compactMap {
            guard let activityEvent = try? AccountEvent(accountEvent: $0) else { return nil }
            return activityEvent
        }
        return AccountEvents(address: address,
                             events: events,
                             startFrom: beforeLt ?? 0,
                             nextFrom: entity.next_from)
    }

    func getEvent(address: Address,
                  eventId: String) async throws -> AccountEvent
    {
        let response = try await tonAPIClient
            .getAccountEvent(path: .init(account_id: address.toRaw(),
                                         event_id: eventId))
        return try AccountEvent(accountEvent: response.ok.body.json)
    }
}

// MARK: - Wallet

extension TonApi {
    func getSeqno(address: Address) async throws -> Int {
        let response = try await tonAPIClient
            .getAccountSeqno(path: .init(account_id: address.toRaw()))
        return try response.ok.body.json.seqno
    }

    func emulateMessageWallet(boc: String) async throws -> Components.Schemas.MessageConsequences {
        let response = try await tonAPIClient
            .emulateMessageToWallet(body: .json(.init(boc: boc)))
        return try response.ok.body.json
    }

    func sendTransaction(boc: String) async throws {
        let response = try await tonAPIClient
            .sendBlockchainMessage(body: .json(.init(boc: boc)))
        _ = try response.ok
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
        let response = try await tonAPIClient.getJettonInfo(
            Operations.getJettonInfo.Input(
                path: Operations.getJettonInfo.Input.Path(
                    account_id: address.toRaw()
                )
            )
        )
        let entity = try response.ok.body.json
        let verification: JettonInfo.Verification
        switch entity.verification {
        case .none:
            verification = .none
        case .blacklist:
            verification = .blacklist
        case .whitelist:
            verification = .whitelist
        }

        return try JettonInfo(
            address: Address.parse(entity.metadata.address),
            fractionDigits: Int(entity.metadata.decimals) ?? 0,
            name: entity.metadata.name,
            symbol: entity.metadata.symbol,
            verification: verification,
            imageURL: URL(string: entity.metadata.image ?? "")
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
        let response = try await tonAPIClient.getRawTime(Operations.getRawTime.Input())
        let entity = try response.ok.body.json
        return TimeInterval(entity.time)
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
