import Foundation
import GRDB
import TonSwift

extension Address: DatabaseValueConvertible {
    public var toData: Data {
        Data(from: [workchain]) + hash
    }

    public static func from(_ data: Data) -> Address? {
        guard data.count > 1 else {
            return nil
        }
        return Address(workchain: Int8(data[0]), hash: data.suffix(from: 1))
    }
}
