//
//  OutgoingJettonDecoration.swift
//
//  Created by Sun on 2024/6/20.
//

import Foundation

import BigInt
import TonSwift

// MARK: - OutgoingJettonDecoration

public class OutgoingJettonDecoration: TransactionDecoration {
    // MARK: Properties

    public let address: Address
    public let to: Address
    public let jettonAddress: Address
    public let value: BigUInt
    public let comment: String?
    public let sentToSelf: Bool

    // MARK: Lifecycle

    init(address: Address, to: Address, jettonAddress: Address, value: BigUInt, comment: String?, sentToSelf: Bool) {
        self.address = address
        self.to = to
        self.jettonAddress = jettonAddress
        self.value = value
        self.comment = comment
        self.sentToSelf = sentToSelf

        super.init()
    }

    required init?(address: Address, actions: [Action]) {
        // Maybe we need to make array of decorations (one decoraction for each different recipient address)
        let transfers = actions.compactMap { $0 as? JettonTransfer }

        let amount = IncomingJettonDecoration.incomingAmount(address: address, transfers: transfers)
        guard amount <= 0 else {
            return nil
        }

        guard
            let first = transfers.first(where: {
                guard let sender = $0.sender else {
                    return false
                }
                return sender.address == address
            }), let recipient = first.recipient
        else {
            return nil
        }

        self.address = address
        to = recipient.address
        jettonAddress = first.jettonAddress
        value = BigUInt(abs(amount))
        comment = first.comment
        sentToSelf = recipient.address == address
        super.init(address: address, actions: actions)
    }

    // MARK: Overridden Functions

    override public func tags(userAddress _: Address) -> [TransactionTag] {
        var tags = [
            TransactionTag(type: .outgoing, protocol: .jetton, jettonAddress: jettonAddress, addresses: [to.toRaw()]),
        ]

        if sentToSelf {
            tags.append(TransactionTag(type: .incoming, protocol: .jetton, jettonAddress: jettonAddress))
        }

        return tags
    }
}

// MARK: CustomStringConvertible

extension OutgoingJettonDecoration: CustomStringConvertible {
    public var description: String {
        [
            "Outgoing Jetton",
            value.description,
            jettonAddress.toRaw(),
            to.toRaw(),
            comment,
        ].compactMap { $0 }.joined(separator: "|")
    }
}
