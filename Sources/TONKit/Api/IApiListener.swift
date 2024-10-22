//
//  IApiListener.swift
//  TONKit
//
//  Created by Sun on 2024/10/22.
//

import Combine
import TONSwift

protocol IApiListener {
    func start(address: Address)
    func stop()
    var transactionPublisher: AnyPublisher<String, Never> { get }
}
