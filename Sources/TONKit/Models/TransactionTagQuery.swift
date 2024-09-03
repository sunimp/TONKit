//
//  TransactionTagQuery.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import TonSwift

public class TransactionTagQuery {
    // MARK: Properties

    public let type: TransactionTag.TagType?
    public let `protocol`: TransactionTag.TagProtocol?
    public let jettonAddress: Address?
    public let address: String?

    // MARK: Computed Properties

    var isEmpty: Bool {
        type == nil && `protocol` == nil && jettonAddress == nil && address == nil
    }

    // MARK: Lifecycle

    public init(
        type: TransactionTag.TagType? = nil,
        protocol: TransactionTag.TagProtocol? = nil,
        jettonAddress: Address? = nil,
        address: String?
    ) {
        self.type = type
        self.protocol = `protocol`
        self.jettonAddress = jettonAddress
        self.address = address
    }
}
