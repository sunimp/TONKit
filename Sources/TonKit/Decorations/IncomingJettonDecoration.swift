//
//  IncomingJettonDecoration.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import BigInt
import TonSwift

// MARK: - IncomingJettonDecoration

public class IncomingJettonDecoration: TransactionDecoration {
    public let from: Address
    public let jettonAddress: Address
    public let value: BigUInt
    public let comment: String?

    init(from: Address, jettonAddress: Address, value: BigUInt, comment: String?) {
        self.from = from
        self.value = value
        self.jettonAddress = jettonAddress
        self.comment = comment

        super.init()
    }

    required init?(address: Address, actions: [Action]) {
        let transfers = actions.compactMap { $0 as? JettonTransfer }

        let amount = IncomingJettonDecoration.incomingAmount(address: address, transfers: transfers)
        guard amount > 0 else { return nil }

        guard
            let first = transfers.first(where: {
                guard let recipient = $0.recipient else { return false }
                return recipient.address == address
            }), let sender = first.sender
        else { return nil }

        from = sender.address
        jettonAddress = first.jettonAddress
        value = BigUInt(abs(amount))
        comment = first.comment

        super.init(address: address, actions: actions)
    }

    override public func tags(userAddress _: Address) -> [TransactionTag] {
        [
            TransactionTag(type: .incoming, protocol: .jetton, jettonAddress: jettonAddress, addresses: [from.toRaw()]),
        ]
    }
}

// MARK: CustomStringConvertible

extension IncomingJettonDecoration: CustomStringConvertible {
    public var description: String {
        [
            "Incoming Jetton",
            jettonAddress.toRaw(),
            from.toRaw(),
            value.description,
            comment,
        ].compactMap { $0 }.joined(separator: "|")
    }
    
    static func incomingAmount(address: Address, transfers: [JettonTransfer]) -> BigInt {
        let incoming = transfers.filter {
            guard let recipient = $0.recipient else { return false }
            return recipient.address == address
        }
        let outgoing = transfers.filter {
            guard let sender = $0.sender else { return false }
            return sender.address == address
        }
            
        return BigInt(incoming.map { $0.amount }.reduce(0, +)) - BigInt(outgoing.map { $0.amount }.reduce(0, +))
    }
}
