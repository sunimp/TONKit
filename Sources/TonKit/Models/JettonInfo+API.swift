//
//  JettonInfo+API.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import TonAPI
import TonSwift

extension JettonInfo {
    
    init(jettonPreview: TonAPI.JettonPreview) throws {
        let tokenAddress = try TonSwift.Address.parse(jettonPreview.address)
        address = tokenAddress
        fractionDigits = jettonPreview.decimals
        name = jettonPreview.name
        symbol = jettonPreview.symbol
        imageURL = URL(string: jettonPreview.image)

        let verification: JettonInfo.Verification
        switch jettonPreview.verification {
        case .whitelist:
            verification = .whitelist
        case .blacklist:
            verification = .blacklist
        case ._none:
            verification = .none
        case .unknownDefaultOpenApi:
            verification = .unknown
        }
        self.verification = verification
    }
}
