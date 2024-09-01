//
//  TagToken.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import TonSwift

public struct TagToken {
    public let `protocol`: TransactionTag.TagProtocol
    public let contractAddress: TonSwift.Address?
}
