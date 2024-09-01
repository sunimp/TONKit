//
//  Configuration.swift
//  TonKit-Demo
//
//  Created by Sun on 2024/8/26.
//

import Foundation

import WWToolKit
import TonKit

class Configuration {
    static let shared = Configuration()

    let network: Network = .mainNet
    let minLogLevel: Logger.Level = .verbose

    let defaultsWords = "vivid episode rabbit vapor they expose excess ten fog old ridge abandon"
    let defaultPassphrase = ""

    let defaultsWatchAddress = "EQDtFpEwcFAEcRe5mLVh2N6C0x-_hJEM7W61_JLnSF74p4q2"
    let defaultSendAddress = "UQDd5wJZ_lA98nktDHFqVfXIU9j3ZNtDt_8Zm3kB530jBWMZ"
    let defaultTrc20ContractAddress = "TXLAQ63Xg1NAzckPwKHvzw7CSEmLMEqcdj"
}
