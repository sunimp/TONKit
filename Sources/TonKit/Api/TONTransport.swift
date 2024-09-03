//
//  TONTransport.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import StreamURLSessionTransport
import TonAPI

struct TONTransport {
    // MARK: Properties

    lazy var transport: StreamURLSessionTransport = .init(urlSessionConfiguration: urlSessionConfiguration)

    lazy var streamingTransport: StreamURLSessionTransport =
        .init(urlSessionConfiguration: streamingURLSessionConfiguration)

    // MARK: Computed Properties

    var urlSessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 60
        return configuration
    }

    var streamingURLSessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = TimeInterval(Int.max)
        configuration.timeoutIntervalForResource = TimeInterval(Int.max)
        return configuration
    }
}
