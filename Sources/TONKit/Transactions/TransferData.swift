//
//  TransferData.swift
//  TONKit
//
//  Created by Sun on 2024/10/22.
//

import TONSwift

public struct TransferData {
    public let sender: Address
    public let sendMode: SendMode
    public let internalMessages: [MessageRelaxed]
}
