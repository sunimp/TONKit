import Combine
import Foundation
import TonSwift

class TransactionManager {
    private let userAddress: Address
    private let storage: AccountEventStorage
    private let decorationManager: DecorationManager

    private let fullTransactionsWithTagsSubject = PassthroughSubject<[(transaction: FullTransaction, tags: [TransactionTag])], Never>()

    init(userAddress: Address, storage: AccountEventStorage, decorationManager: DecorationManager) {
        self.userAddress = userAddress
        self.storage = storage
        self.decorationManager = decorationManager
    }
}

extension TransactionManager {
    func fullTransactionsPublisher(tagQueries: [TransactionTagQuery]) -> AnyPublisher<[FullTransaction], Never> {
        fullTransactionsWithTagsSubject
            .map { transactionsWithTags in
                transactionsWithTags.compactMap { (transaction: FullTransaction, tags: [TransactionTag]) -> FullTransaction? in
                    for tagQuery in tagQueries {
                        for tag in tags {
                            if tag.conforms(tagQuery: tagQuery) {
                                return transaction
                            }
                        }
                    }

                    return nil
                }
            }
            .filter { transactions in
                transactions.count > 0
            }
            .eraseToAnyPublisher()
    }

    func fullTransactions(tagQueries: [TransactionTagQuery], beforeLt: Int64?, limit: Int?) -> [FullTransaction] {
        let events = storage.eventsBefore(tagQueries: tagQueries, lt: beforeLt, limit: limit)
        return decorationManager.decorate(events: events)
    }

    func events(address _: Address, tagQueries: [TransactionTagQuery], beforeLt: Int64?, limit: Int?) -> [AccountEvent] {
        return storage.eventsBefore(tagQueries: tagQueries, lt: beforeLt, limit: limit)
    }

    func newestEvent() -> AccountEventRecord? {
        storage.lastEventRecord(newest: true)
    }

    func oldestEvent() -> AccountEventRecord? {
        storage.lastEventRecord(newest: false)
    }

    func event(address _: Address, eventId: String) -> AccountEvent? {
        storage.event(eventId: eventId)
    }

    func save(events: [AccountEvent]) {
        storage.save(events: events, replaceOnConflict: true)
    }
    
    @discardableResult func handle(events: [AccountEvent]) -> [FullTransaction] {
        guard !events.isEmpty else {
            return []
        }

        save(events: events)
        let fullTransactions = decorationManager.decorate(events: events)

        var fullTransactionsWithTags = [(transaction: FullTransaction, tags: [TransactionTag])]()
        var tagRecords = [TransactionTagRecord]()

        for fullTransaction in fullTransactions {
            let tags = fullTransaction.decoration.tags(userAddress: userAddress)
            tagRecords.append(contentsOf: tags.map { TransactionTagRecord(eventId: fullTransaction.event.eventId, tag: $0) })
            fullTransactionsWithTags.append((transaction: fullTransaction, tags: tags))
        }

        storage.save(tags: tagRecords)

        fullTransactionsWithTagsSubject.send(fullTransactionsWithTags)

        return fullTransactions
    }
}

public protocol ITransactionDecorator {
    func decoration(actions: [Action]) -> TransactionDecoration?
}
