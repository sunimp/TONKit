//
//  Action+API.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import TonAPI
import TonStreamingAPI
import TonSwift

extension Action {
    static func from(eventID: String, actions: [TonAPI.Action]) -> [Action] {
        var result = [Action]()
        for action in actions {
            do {
                let action = try Action.instance(eventID: eventID, index: result.count, action: action)
                result.append(action)
            } catch {
                print("Can't parse because: \(error.localizedDescription)")
            }
        }
        return result
    }

    static func instance(eventID: String, index: Int, action: TonAPI.Action) throws -> Action {
        if let tonTransfer = action.tonTransfer {
            return try TONTransfer(eventID: eventID, index: index, action: tonTransfer)
        }
        if let jettonTransfer = action.jettonTransfer {
            return try JettonTransfer(eventID: eventID, index: index, action: jettonTransfer)
        }

        throw MapError.unsupported
    }
}

// MARK: - Action.MapError

extension Action {
    enum MapError: Error {
        case cantParse
        case unsupported
    }
}
