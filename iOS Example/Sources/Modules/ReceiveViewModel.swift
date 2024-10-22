//
//  ReceiveViewModel.swift
//  TONKit-Example
//
//  Created by Sun on 2024/10/22.
//

import Combine
import TONKit

class ReceiveViewModel: ObservableObject {
    var address: String {
        Singleton.tonKit?.receiveAddress.toFriendlyWallet ?? ""
    }
}
