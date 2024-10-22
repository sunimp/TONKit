//
//  BalanceViewModel.swift
//  TONKit-Example
//
//  Created by Sun on 2024/10/22.
//

import Combine
import Foundation
import TONKit
import TONSwift

class BalanceViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    @Published var syncState: SyncState
    @Published var account: Account?

    @Published var jettonSyncState: SyncState
    @Published var jettonBalanceMap: [Address: JettonBalance]

    @Published var eventSyncState: SyncState

    init() {
        syncState = Singleton.tonKit?.syncState ?? .notSynced(error: AppError.noTONKit)
        account = Singleton.tonKit?.account

        jettonSyncState = Singleton.tonKit?.jettonSyncState ?? .notSynced(error: AppError.noTONKit)
        jettonBalanceMap = Singleton.tonKit?.jettonBalanceMap ?? [:]

        eventSyncState = Singleton.tonKit?.eventSyncState ?? .notSynced(error: AppError.noTONKit)

        Singleton.tonKit?.syncStatePublisher.receive(on: DispatchQueue.main).sink { [weak self] in self?.syncState = $0 }.store(in: &cancellables)
        Singleton.tonKit?.accountPublisher.receive(on: DispatchQueue.main).sink { [weak self] in self?.account = $0 }.store(in: &cancellables)

        Singleton.tonKit?.jettonSyncStatePublisher.receive(on: DispatchQueue.main).sink { [weak self] in self?.jettonSyncState = $0 }.store(in: &cancellables)
        Singleton.tonKit?.jettonBalanceMapPublisher.receive(on: DispatchQueue.main).sink { [weak self] in self?.jettonBalanceMap = $0 }.store(in: &cancellables)

        Singleton.tonKit?.eventSyncStatePublisher.receive(on: DispatchQueue.main).sink { [weak self] in self?.eventSyncState = $0 }.store(in: &cancellables)

        // print(tonKit.receiveAddress.toFriendly(testOnly: Configuration.isTestNet(), bounceable: false).toString())
    }

    var address: String {
        Singleton.tonKit?.receiveAddress.toFriendlyWallet ?? ""
    }

    func refresh() {
        Singleton.tonKit?.sync()
    }
}
