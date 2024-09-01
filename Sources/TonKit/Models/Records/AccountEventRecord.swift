//
//  AccountEventRecord.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import GRDB

// MARK: - AccountEventRecord

class AccountEventRecord: Record {
    let eventId: String
    let timestamp: TimeInterval
    let accountUid: String
    let isScam: Bool
    let isInProgress: Bool
    let fee: Int64
    let lt: Int64

    override class var databaseTableName: String {
        return "account_event"
    }

    enum Columns: String, ColumnExpression {
        case eventId
        case timestamp
        case accountUid
        case isScam
        case isInProgress
        case fee
        case lt
    }

    init(eventId: String, timestamp: TimeInterval, accountUid: String, isScam: Bool, isInProgress: Bool, fee: Int64, lt: Int64) {
        self.eventId = eventId
        self.timestamp = timestamp
        self.accountUid = accountUid
        self.isScam = isScam
        self.isInProgress = isInProgress
        self.fee = fee
        self.lt = lt

        super.init()
    }

    required init(row: Row) throws {
        eventId = row[Columns.eventId]
        timestamp = row[Columns.timestamp]
        accountUid = row[Columns.accountUid]
        isScam = row[Columns.isScam]
        isInProgress = row[Columns.isInProgress]
        fee = row[Columns.fee]
        lt = row[Columns.lt]

        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.eventId] = eventId
        container[Columns.timestamp] = timestamp
        container[Columns.accountUid] = accountUid
        container[Columns.isScam] = isScam
        container[Columns.isInProgress] = isInProgress
        container[Columns.fee] = fee
        container[Columns.lt] = lt
    }
}

extension Collection<AccountEventRecord> {
    func events(db: Database) throws -> [AccountEvent] {
        let accountUids = map { $0.accountUid }
        let eventUids = map { $0.eventId }
        let account = try WalletAccountRecord.accounts(db: db, uids: Array(Set(accountUids)))
        let actions = try ActionRecord.actions(db: db, eventIds: eventUids)

        return compactMap { record -> AccountEvent? in
            guard let account = account[record.accountUid] else { return nil }
            guard let actions = actions[record.eventId], !actions.isEmpty else { return nil }

            return record.accountEvent(walletAccount: account, actions: actions.sorted())
        }
    }
}

extension AccountEventRecord {
    func accountEvent(walletAccount: WalletAccount, actions: [Action]) -> AccountEvent {
        return AccountEvent(
            eventId: eventId,
            timestamp: timestamp,
            account: walletAccount,
            isScam: isScam,
            isInProgress: isInProgress,
            fee: fee,
            lt: lt,
            actions: actions
        )
    }

    static func record(_ from: AccountEvent) -> AccountEventRecord {
        .init(
            eventId: from.eventId,
            timestamp: from.timestamp,
            accountUid: from.account.address.toRaw(),
            isScam: from.isScam,
            isInProgress: from.isInProgress,
            fee: from.fee,
            lt: from.lt
        )
    }
}
