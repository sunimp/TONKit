//
//  Event.swift
//  TONKit
//
//  Created by Sun on 2024/10/22.
//

import BigInt
import GRDB
import TONSwift

// MARK: - Event

public struct Event: Codable {
    // MARK: Properties

    public let id: String
    public let lt: Int64
    public let timestamp: Int64
    public let isScam: Bool
    public let inProgress: Bool
    public let extra: Int64
    public let actions: [Action]

    // MARK: Functions

    func tags(address: Address) -> [Tag] {
        var tags = [Tag]()

        for action in actions {
            switch action.type {
            case let .tonTransfer(action):
                if action.sender.address == address {
                    tags.append(Tag(
                        eventID: id,
                        type: .outgoing,
                        platform: .native,
                        addresses: [action.recipient.address]
                    ))
                }

                if action.recipient.address == address {
                    tags.append(Tag(
                        eventID: id,
                        type: .incoming,
                        platform: .native,
                        addresses: [action.sender.address]
                    ))
                }

            case let .jettonTransfer(action):
                if let sender = action.sender, sender.address == address {
                    tags.append(Tag(
                        eventID: id,
                        type: .outgoing,
                        platform: .jetton,
                        jettonAddress: action.jetton.address,
                        addresses: action.recipient.map { [$0.address] } ?? []
                    ))
                }

                if let recipient = action.recipient, recipient.address == address {
                    tags.append(Tag(
                        eventID: id,
                        type: .incoming,
                        platform: .jetton,
                        jettonAddress: action.jetton.address,
                        addresses: action.sender.map { [$0.address] } ?? []
                    ))
                }

            case let .jettonBurn(action):
                tags.append(Tag(eventID: id, type: .outgoing, platform: .jetton, jettonAddress: action.jetton.address))

            case let .jettonMint(action):
                tags.append(Tag(eventID: id, type: .incoming, platform: .jetton, jettonAddress: action.jetton.address))

            case let .jettonSwap(action):
                if let jetton = action.jettonMasterIn {
                    tags.append(Tag(eventID: id, type: .incoming, platform: .jetton, jettonAddress: jetton.address))
                    tags.append(Tag(eventID: id, type: .swap, platform: .jetton, jettonAddress: jetton.address))
                } else {
                    tags.append(Tag(eventID: id, type: .incoming, platform: .native))
                    tags.append(Tag(eventID: id, type: .swap, platform: .native))
                }

                if let jetton = action.jettonMasterOut {
                    tags.append(Tag(eventID: id, type: .outgoing, platform: .jetton, jettonAddress: jetton.address))
                    tags.append(Tag(eventID: id, type: .swap, platform: .jetton, jettonAddress: jetton.address))
                } else {
                    tags.append(Tag(eventID: id, type: .outgoing, platform: .native))
                    tags.append(Tag(eventID: id, type: .swap, platform: .native))
                }

            case let .smartContract(action):
                tags.append(Tag(eventID: id, type: .outgoing, platform: .native, addresses: [action.contract.address]))

            default: ()
            }
        }

        return tags
    }
}

// MARK: FetchableRecord, PersistableRecord

extension Event: FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let lt = Column(CodingKeys.lt)
        static let timestamp = Column(CodingKeys.timestamp)
        static let isScam = Column(CodingKeys.isScam)
        static let isProgress = Column(CodingKeys.inProgress)
        static let extra = Column(CodingKeys.extra)
        static let actions = Column(CodingKeys.actions)
    }
}

// MARK: - EventInfo

public struct EventInfo {
    public let events: [Event]
    public let initial: Bool
}

// MARK: - EventSyncState

struct EventSyncState: Codable {
    // MARK: Properties

    let id: String
    let allSynced: Bool

    // MARK: Lifecycle

    init(allSynced: Bool) {
        id = "unique_id"
        self.allSynced = allSynced
    }
}

// MARK: FetchableRecord, PersistableRecord

extension EventSyncState: FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let allSynced = Column(CodingKeys.allSynced)
    }
}

// MARK: - EmulateResult

public struct EmulateResult {
    public let totalFee: BigUInt
    public let event: Event
}
