//
//  TagQuery.swift
//  TONKit
//
//  Created by Sun on 2024/10/22.
//

import TONSwift

public class TagQuery {
    // MARK: Properties

    public let type: Tag.`Type`?
    public let platform: Tag.Platform?
    public let jettonAddress: Address?
    public let address: Address?

    // MARK: Computed Properties

    var isEmpty: Bool {
        type == nil && platform == nil && jettonAddress == nil && address == nil
    }

    // MARK: Lifecycle

    public init(
        type: Tag.`Type`? = nil,
        platform: Tag.Platform? = nil,
        jettonAddress: Address? = nil,
        address: Address? = nil
    ) {
        self.type = type
        self.platform = platform
        self.jettonAddress = jettonAddress
        self.address = address
    }
}
