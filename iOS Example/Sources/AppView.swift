//
//  AppView.swift
//  TONKit-Example
//
//  Created by Sun on 2024/10/22.
//

import SwiftUI

@main
struct AppView: App {
    @StateObject var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            if viewModel.tonKit != nil {
                MainView(appViewModel: viewModel)
            } else {
                LoginView(appViewModel: viewModel)
            }
        }
    }
}
