//
//  MainView.swift
//  TONKit-Example
//
//  Created by Sun on 2024/10/22.
//

import SwiftUI
import TONKit

struct MainView: View {
    @ObservedObject private var appViewModel: AppViewModel

    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
    }

    var body: some View {
        TabView {
            BalanceView(appViewModel: appViewModel)
                .tabItem {
                    Label("Balance", systemImage: "creditcard.circle")
                }

            EventView(appViewModel: appViewModel)
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.circle")
                }

            if Singleton.keyPair != nil {
                SendView()
                    .tabItem {
                        Label("Send", systemImage: "paperplane.circle")
                    }

                ReceiveView()
                    .tabItem {
                        Label("Receive", systemImage: "tray.circle")
                    }
            }
        }
    }
}
