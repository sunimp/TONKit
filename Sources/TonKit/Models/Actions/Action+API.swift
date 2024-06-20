import Foundation
import TonAPI
import TonSwift

extension Action {
    static func from(eventId: String, actions: [Components.Schemas.Action]) -> [Action] {
        var result = [Action]()
        for action in actions {
            do {
                let action = try Action.instance(eventId: eventId, index: result.count, action: action)
                result.append(action)
            } catch {
                print("Can't parse because: \(error.localizedDescription)")
            }
        }
        return result
    }

    static func instance(eventId: String, index: Int, action: Components.Schemas.Action) throws -> Action {
        if let tonTransfer = action.TonTransfer {
            return try TonTransfer(eventId: eventId, index: index, action: tonTransfer)
        }
        if let jettonTransfer = action.JettonTransfer {
            return try JettonTransfer(eventId: eventId, index: index, action: jettonTransfer)
        }

        throw MapError.unsupported
    }
}

extension Action {
    enum MapError: Error {
        case cantParse
        case unsupported
    }
}
