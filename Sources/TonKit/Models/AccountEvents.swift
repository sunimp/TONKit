//
//  AccountEvents.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import TonSwift

struct AccountEvents: Codable {
    let address: Address
    let events: [AccountEvent]
    let startFrom: Int64
    let nextFrom: Int64
}
