//
//  Tag.swift
//  TONKit
//
//  Created by Sun on 2024/10/22.
//

import GRDB
import TONSwift

// MARK: - Tag

public class Tag: Codable {
    // MARK: Properties

    public let eventID: String
    public let type: `Type`?
    public let platform: Platform?
    public let jettonAddress: Address?
    public let addresses: [Address]

    // MARK: Lifecycle

    public init(
        eventID: String,
        type: Type? = nil,
        platform: Platform? = nil,
        jettonAddress: Address? = nil,
        addresses: [Address] = []
    ) {
        self.eventID = eventID
        self.type = type
        self.platform = platform
        self.jettonAddress = jettonAddress
        self.addresses = addresses
    }

    // MARK: Functions

    public func conforms(tagQuery: TagQuery) -> Bool {
        if let type = tagQuery.type, self.type != type {
            return false
        }

        if let platform = tagQuery.platform, self.platform != platform {
            return false
        }

        if let jettonAddress = tagQuery.jettonAddress, self.jettonAddress != jettonAddress {
            return false
        }

        if let address = tagQuery.address, !addresses.contains(address) {
            return false
        }

        return true
    }
}

// MARK: FetchableRecord, PersistableRecord

extension Tag: FetchableRecord, PersistableRecord {
    enum Columns {
        static let eventID = Column(CodingKeys.eventID)
        static let type = Column(CodingKeys.type)
        static let platform = Column(CodingKeys.platform)
        static let jettonAddress = Column(CodingKeys.jettonAddress)
        static let addresses = Column(CodingKeys.addresses)
    }
}

extension Tag {
    public enum Platform: String, Codable {
        case native
        case jetton
    }

    public enum `Type`: String, Codable {
        case incoming
        case outgoing
        case swap
        case unsupported
    }
}
