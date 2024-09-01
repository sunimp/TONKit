//
//  Manager.swift
//  TonKit-Demo
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import HDWalletKit
import TonKit
import TonSwift
import TweetNacl
import WWToolKit

class Manager {
    static let shared = Manager()

    private let keyWords = "mnemonic_words"
    private let keyAddress = "address"

    var tonKit: Kit!
    var adapter: TonAdapter!

    init() {
        if let words = savedWords {
            try? initKit(words: words)
        } else if let address = savedAddress {
            try? initKit(address: address)
        }
    }

    private func initKit(type: Kit.WalletType, configuration: Configuration) throws {
        let logger = Logger(minLogLevel: configuration.minLogLevel)
        let tonKit = try Kit.instance(
            type: type,
            network: configuration.network,
            walletId: "walletId",
            apiKey: nil,
            logger: logger
        )

        adapter = TonAdapter(tonKit: tonKit)

        self.tonKit = tonKit
        tonKit.start()
    }

    private func initKit(words: [String]) throws {
        let configuration = Configuration.shared

        guard let seed = Mnemonic.seed(mnemonic: words, passphrase: configuration.defaultPassphrase) else {
            throw LoginError.seedGenerationFailed
        }

        let hdWallet = HDWallet(seed: seed, coinType: 607, xPrivKey: 0, curve: .ed25519)
        let privateKey = try hdWallet.privateKey(account: 0)
        let privateRaw = Data(privateKey.raw.bytes)
        let pair = try TweetNacl.NaclSign.KeyPair.keyPair(fromSeed: privateRaw)
        let keyPair = KeyPair(publicKey: .init(data: pair.publicKey),
                              privateKey: .init(data: pair.secretKey))

        try initKit(
            type: .full(keyPair),
            configuration: configuration
        )
    }

    private func initKit(address: Address) throws {
        let configuration = Configuration.shared

        try initKit(type: .watch(address), configuration: configuration)
    }

    private var savedWords: [String]? {
        guard let wordsString = UserDefaults.standard.value(forKey: keyWords) as? String else {
            return nil
        }

        return wordsString.split(separator: " ").map(String.init)
    }

    private var savedAddress: Address? {
        guard let addressString = UserDefaults.standard.value(forKey: keyAddress) as? String else {
            return nil
        }

        return try? Address.parse(raw: addressString)
    }

    private func save(words: [String]) {
        UserDefaults.standard.set(words.joined(separator: " "), forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    private func save(address: String) {
        UserDefaults.standard.set(address, forKey: keyAddress)
        UserDefaults.standard.synchronize()
    }

    private func clearStorage() {
        UserDefaults.standard.removeObject(forKey: keyWords)
        UserDefaults.standard.removeObject(forKey: keyAddress)
        UserDefaults.standard.synchronize()
    }
}

extension Manager {
    func login(words: [String]) throws {
        try Kit.clear(exceptFor: ["walletId"])

        save(words: words)
        try initKit(words: words)
    }

    func watch(address: Address) throws {
        try Kit.clear(exceptFor: ["walletId"])

        save(address: address.toRaw())
        try initKit(address: address)
    }

    func logout() {
        clearStorage()

        tonKit = nil
        adapter = nil
    }
}

extension Manager {
    enum LoginError: Error {
        case seedGenerationFailed
    }
}
