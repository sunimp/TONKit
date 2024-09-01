//
//  Action+API.swift
//  TonKit
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import TonAPI
import TonStreamingAPI
import TonSwift

extension Action {
    
    static func from(eventId: String, actions: [TonAPI.Action]) -> [Action] {
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

    static func instance(eventId: String, index: Int, action: TonAPI.Action) throws -> Action {
        if let tonTransfer = action.tonTransfer {
            return try TonTransfer(eventId: eventId, index: index, action: tonTransfer)
        }
        if let jettonTransfer = action.jettonTransfer {
            return try JettonTransfer(eventId: eventId, index: index, action: jettonTransfer)
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
