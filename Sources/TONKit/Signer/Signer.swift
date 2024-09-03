//
//  Signer.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import BigInt
import HDWalletKit
import TonSwift
import WWCryptoKit
import WWExtensions
import WWToolKit

// MARK: - Signer

public class Signer {
    // MARK: Properties

    private let privateKey: Data

    // MARK: Lifecycle

    init(privateKey: Data) {
        self.privateKey = privateKey
    }

    // MARK: Functions

    func signature(hash: Data) throws -> Data {
        try Crypto.ellipticSign(hash, privateKey: privateKey)
    }
}

extension Signer {
    public static func instance(seed: Data) throws -> Signer {
        try Signer(privateKey: privateKey(seed: seed))
    }

    public static func address(seed: Data) throws -> Address {
        try address(privateKey: privateKey(seed: seed))
    }

    public static func address(privateKey _: Data) throws -> Address {
        fatalError()
//        let publicKey = Data(Crypto.publicKey(privateKey: privateKey, compressed: false).dropFirst())
//        return try Address(raw: [0x41] + Data(Crypto.sha3(publicKey).suffix(20)))
    }

    public static func privateKey(string: String) throws -> Data {
        guard let data = string.ww.hexData else {
            throw PrivateKeyValidationError.invalidDataString
        }

        guard data.count == 32 else {
            throw PrivateKeyValidationError.invalidDataLength
        }

        return data
    }

    public static func privateKey(seed: Data) throws -> Data {
        let hdWallet = HDWallet(seed: seed, coinType: 195, xPrivKey: HDExtendedKeyVersion.xprv.rawValue)
        return try hdWallet.privateKey(account: 0, index: 0, chain: .external).raw
    }
}

// MARK: Signer.PrivateKeyValidationError

extension Signer {
    public enum PrivateKeyValidationError: Error {
        case invalidDataString
        case invalidDataLength
    }
}
