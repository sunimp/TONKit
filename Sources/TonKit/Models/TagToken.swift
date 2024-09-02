//
//  TagToken.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import TonSwift

public struct TagToken {
    public let `protocol`: TransactionTag.TagProtocol
    public let contractAddress: TonSwift.Address?
}
