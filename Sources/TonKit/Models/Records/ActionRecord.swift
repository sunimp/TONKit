//
//  ActionRecord.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import GRDB

enum ActionRecord {
    static func actions(db: Database, eventIds: [String]) throws -> [String: [Action]] {
        var accountUids = [String]()
        var actions = [Action]()

        // Collect all actions for every eventId

        // 1.1.1 Get transfers for all events
        let tonTransfersRecords = try TonTransferRecord.filter(eventIds.contains(TonTransferRecord.Columns.eventId)).fetchAll(db)
        let jettonTransfersRecords = try JettonTransferRecord.filter(eventIds.contains(JettonTransferRecord.Columns.eventId))
            .fetchAll(db)
        // 1.1.2 Reduce walletAccounts from tonTransferRecords
        let tonTransfersAccounts = tonTransfersRecords.reduce(into: []) { uids, action in uids.append(contentsOf: [
            action.recipientUid,
            action.senderUid,
        ]) }
        let jettonTransfersAccounts = jettonTransfersRecords.reduce(into: []) { uids, action in uids.append(contentsOf: [
            action.recipientUid,
            action.senderUid,
        ].compactMap { $0 }) }
        accountUids.append(contentsOf: tonTransfersAccounts)
        accountUids.append(contentsOf: jettonTransfersAccounts)
        // 1.x.1/2 same actions for other events

        // 2. Get all accounts
        accountUids = Array(Set(accountUids))
        let walletAccounts = try WalletAccountRecord.filter(accountUids.contains(WalletAccountRecord.Columns.uid)).fetchAll(db)
        let accountMap = Dictionary(uniqueKeysWithValues: walletAccounts.map { ($0.uid, $0) })

        // 3.1 Converting and grouping transfers
        let tonTransfers: [Action] = tonTransfersRecords.compactMap { record -> Action? in
            guard
                let sender = accountMap[record.senderUid]?.walletAccount,
                let recipient = accountMap[record.recipientUid]?.walletAccount
            else { return nil }
            return record.tonTransfer(sender: sender, recipient: recipient)
        }
        let jettonTransfers: [Action] = jettonTransfersRecords.compactMap { record -> Action? in
            var sender: WalletAccount?
            var recipient: WalletAccount?

            if let senderUid = record.senderUid {
                if let account = accountMap[senderUid]?.walletAccount {
                    sender = account
                } else {
                    return nil
                }
            }

            if let recipientUid = record.recipientUid {
                if let account = accountMap[recipientUid]?.walletAccount {
                    recipient = account
                } else {
                    return nil
                }
            }
            return record.jettonTransfer(sender: sender, recipient: recipient)
        }

        // 3.2 Add to all actions
        actions.append(contentsOf: tonTransfers)
        actions.append(contentsOf: jettonTransfers)

        // 4.1 Make dictionary of actions by eventId
        let actionMap = Dictionary(grouping: actions, by: { $0.eventId })

        return actionMap
    }
}
