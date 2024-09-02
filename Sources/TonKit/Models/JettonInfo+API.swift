//
//  JettonInfo+API.swift
//
//  Created by Sun on 2024/6/13.
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

        let verification: JettonInfo.Verification =
            switch jettonPreview.verification {
            case .whitelist:
                .whitelist
            case .blacklist:
                .blacklist
            case ._none:
                .none
            case .unknownDefaultOpenApi:
                .unknown
            }
        self.verification = verification
    }
}
