import HsToolKit
import TonKit

class Configuration {
    static let shared = Configuration()

    let network: Network = .mainNet
    let minLogLevel: Logger.Level = .verbose

    let defaultsWords = ""
    let defaultPassphrase = ""

    let defaultsWatchAddress = "EQDtFpEwcFAEcRe5mLVh2N6C0x-_hJEM7W61_JLnSF74p4q2"
    let defaultSendAddress = "UQDd5wJZ_lA98nktDHFqVfXIU9j3ZNtDt_8Zm3kB530jBWMZ"
    let defaultTrc20ContractAddress = "TXLAQ63Xg1NAzckPwKHvzw7CSEmLMEqcdj"
}
