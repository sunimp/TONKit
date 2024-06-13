import BigInt
import Foundation
import GRDB
import TonSwift

protocol IActionRecord {
    func save(db: Database, index: Int) throws
}

public class Action: Codable {
    public let eventId: String
    public let index: Int

    public init(eventId: String, index: Int) {
        self.eventId = eventId
        self.index = index
    }
}

extension Action: Comparable {
    public static func < (lhs: Action, rhs: Action) -> Bool {
        lhs.index < rhs.index
    }

    public static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.index == rhs.index && lhs.eventId == rhs.eventId
    }
}
