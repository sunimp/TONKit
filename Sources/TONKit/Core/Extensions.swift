//
//  Extensions.swift
//  TONKit
//
//  Created by Sun on 2024/10/22.
//

import BigInt
import GRDB
import TONSwift

// MARK: - BigUInt + DatabaseValueConvertible
#if compiler(>=6)
extension BigUInt: @retroactive DatabaseValueConvertible { }
#else
extension BigUInt: DatabaseValueConvertible { }
#endif
extension BigUInt {
    public var databaseValue: DatabaseValue {
        description.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> BigUInt? {
        guard case let DatabaseValue.Storage.string(value) = dbValue.storage else {
            return nil
        }
        return BigUInt(value)
    }
}

// MARK: - Address + DatabaseValueConvertible
#if compiler(>=6)
extension Address: @retroactive DatabaseValueConvertible { }
#else
extension Address: DatabaseValueConvertible { }
#endif
extension Address {
    public var databaseValue: DatabaseValue {
        toRaw().databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Address? {
        guard case let DatabaseValue.Storage.string(value) = dbValue.storage else {
            return nil
        }

        do {
            return try Address.parse(raw: value)
        } catch {
            return nil
        }
    }
}

// MARK: - Account.Status + DatabaseValueConvertible

extension Account.Status: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        rawValue.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Account.Status? {
        guard case let DatabaseValue.Storage.string(value) = dbValue.storage else {
            return nil
        }

        return Account.Status(rawValue: value)
    }
}

// MARK: - Jetton.VerificationType + DatabaseValueConvertible

extension Jetton.VerificationType: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        rawValue.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Jetton.VerificationType? {
        guard case let DatabaseValue.Storage.string(value) = dbValue.storage else {
            return nil
        }

        return Jetton.VerificationType(rawValue: value)
    }
}

// MARK: - Tag.Platform + DatabaseValueConvertible

extension Tag.Platform: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        rawValue.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Tag.Platform? {
        guard case let DatabaseValue.Storage.string(value) = dbValue.storage else {
            return nil
        }

        return Tag.Platform(rawValue: value)
    }
}
