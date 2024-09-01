//
//  AccountEvent.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import GRDB

public struct AccountEvent: Codable {
    public let eventId: String
    public let timestamp: TimeInterval
    public let account: WalletAccount
    public let isScam: Bool
    public let isInProgress: Bool
    public let fee: Int64
    public let lt: Int64
    public let actions: [Action]
}
