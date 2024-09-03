//
//  BackgroundUpdateStore.swift
//
//  Created by Sun on 2024/6/13.
//

import Foundation

import EventSource
import OpenAPIRuntime
import TonStreamingAPI
import TonSwift
import WWToolKit

// MARK: - BackgroundUpdateState

public enum BackgroundUpdateState {
    case connecting(addresses: [Address])
    case connected(addresses: [Address])
    case disconnected
    case noConnection
}

// MARK: - BackgroundUpdateEvent

public struct BackgroundUpdateEvent {
    public let accountAddress: Address
    public let lt: Int64
    public let txHash: String
}

// MARK: - BackgroundUpdateStore

public actor BackgroundUpdateStore {
    // MARK: Nested Types

    public enum Event {
        case didUpdateState(BackgroundUpdateState)
        case didReceiveUpdateEvent(BackgroundUpdateEvent)
    }

    typealias ObservationClosure = (Event) -> Void

    // MARK: Properties

    private var task: Task<Void, Never>?
    private let jsonDecoder = JSONDecoder()

    private let streamingAPI: TonStreamingAPI.Client
    private let logger: Logger?

    private var observations = [UUID: ObservationClosure]()

    // MARK: Computed Properties

    public var state: BackgroundUpdateState = .disconnected {
        didSet {
            for value in observations.values {
                value(.didUpdateState(state))
            }
        }
    }

    // MARK: Lifecycle

    init(streamingAPI: TonStreamingAPI.Client, logger: Logger?) {
        self.streamingAPI = streamingAPI
        self.logger = logger
    }

    // MARK: Functions

    public func start(addresses: [Address]) async {
        switch state {
        case let .connecting(connectingAddresses):
            guard addresses != connectingAddresses else {
                return
            }
            connect(addresses: addresses)

        case let .connected(connectedAddresses):
            guard addresses != connectedAddresses else {
                return
            }
            connect(addresses: addresses)

        case .disconnected:
            connect(addresses: addresses)

        case .noConnection:
            connect(addresses: addresses)
        }
    }

    public func stop() async {
        task?.cancel()
        observations.removeAll()
        task = nil
    }

    func addEventObserver<T: AnyObject>(
        _ observer: T,
        closure: @escaping (T, Event) -> Void
    )
        -> ObservationToken {
        let id = UUID()
        let eventHandler: (Event) -> Void = { [weak self, weak observer] event in
            guard let self else {
                return
            }
            guard let observer else {
                Task { await self.removeObservation(key: id) }
                return
            }

            closure(observer, event)
        }
        observations[id] = eventHandler

        return ObservationToken { [weak self] in
            guard let self else {
                return
            }
            Task { await self.removeObservation(key: id) }
        }
    }

    func removeObservation(key: UUID) {
        observations.removeValue(forKey: key)
    }
}

extension BackgroundUpdateStore {
    private func connect(addresses: [Address]) {
        self.task?.cancel()
        self.task = nil

        let task = Task {
            let rawAddresses = addresses.map { $0.toRaw() }.joined(separator: ",")

            do {
                self.state = .connecting(addresses: addresses)
                let stream = try await EventSource.eventSource {
                    let response = try await self.streamingAPI.getTransactions(
                        query: .init(accounts: [rawAddresses])
                    )
                    return try response.ok.body.text_event_hyphen_stream
                }

                guard !Task.isCancelled else {
                    return
                }

                self.state = .connected(addresses: addresses)
                for try await events in stream {
                    handleReceivedEvents(events)
                }
                self.state = .disconnected
                guard !Task.isCancelled else {
                    return
                }
                connect(addresses: addresses)
            } catch {
                if error.isNoConnectionError {
                    self.state = .noConnection
                } else {
                    self.state = .disconnected
                    try? await Task.sleep(nanoseconds: 3000000000)
                    self.connect(addresses: addresses)
                }
            }
        }
        self.task = task
    }

    private func handleReceivedEvents(_ events: [EventSource.Event]) {
        logger?.log(level: .debug, message: "-> receive events :\(events.count)")
        guard
            let messageEvent = events.last(where: { $0.event == "message" }),
            let eventData = messageEvent.data?.data(using: .utf8)
        else {
            return
        }
        do {
            let eventTransaction = try jsonDecoder.decode(EventSource.Transaction.self, from: eventData)
            let address = try Address.parse(eventTransaction.accountId)
            let updateEvent = BackgroundUpdateEvent(
                accountAddress: address,
                lt: eventTransaction.lt,
                txHash: eventTransaction.txHash
            )
            for value in observations.values {
                value(.didReceiveUpdateEvent(updateEvent))
            }
        } catch {
            return
        }
    }
}

extension Swift.Error {
    public var isNoConnectionError: Bool {
        switch self {
        case let urlError as URLError:
            switch urlError.code {
            case URLError.Code.notConnectedToInternet,
                 URLError.Code.networkConnectionLost:
                return true
            default: return false
            }

        case let clientError as OpenAPIRuntime.ClientError:
            return clientError.underlyingError.isNoConnectionError

        default:
            return false
        }
    }

    public var isCancelledError: Bool {
        switch self {
        case let urlError as URLError:
            switch urlError.code {
            case URLError.Code.cancelled:
                return true
            default: return false
            }

        case let clientError as OpenAPIRuntime.ClientError:
            return clientError.underlyingError.isCancelledError

        default:
            return false
        }
    }
}

// MARK: - ObservationToken

public class ObservationToken {
    // MARK: Properties

    private let cancellationClosure: () -> Void

    // MARK: Lifecycle

    init(cancellationClosure: @escaping () -> Void) {
        self.cancellationClosure = cancellationClosure
    }

    // MARK: Functions

    public func cancel() {
        cancellationClosure()
    }
}
