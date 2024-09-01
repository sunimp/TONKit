//
//  TransactionRecord.swift
//  TonKit-Demo
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import TonKit

struct TransactionRecord {
    let transactionHash: String
    let transactionHashData: Data
    let timestamp: Int
    let isInProgress: Bool
    let lt: Int64

    let decoration: TransactionDecoration
}
