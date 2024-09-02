//
//  AccountEvents.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import TonSwift

struct AccountEvents: Codable {
    let address: Address
    let events: [AccountEvent]
    let startFrom: Int64
    let nextFrom: Int64
}
