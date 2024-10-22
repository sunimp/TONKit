//
//  ReceiveView.swift
//  TONKit-Example
//
//  Created by Sun on 2024/10/22.
//

import SwiftUI
import TONKit
import UIKit

struct ReceiveView: View {
    @StateObject private var viewModel = ReceiveViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(viewModel.address)
                    .multilineTextAlignment(.center)

                Button("Copy") {
                    UIPasteboard.general.string = viewModel.address
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Receive")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
