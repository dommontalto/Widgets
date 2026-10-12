//
//  VaultGuidedTestingScreen.swift
//  Widgets
//
//  Created by Dom Montalto on 17/9/2026.
//

import SwiftUI

// Guided Testing pushed into the host stack: each lab's tests, with a receipt once
// one is ordered.
struct VaultGuidedTestingScreen: View {
    @State private var receipt: VaultTestOrder?

    var body: some View {
        VaultGuidedTestingHomeView(onOrder: place)
            .sheet(item: $receipt) { order in
                BrightReceiptSheetV5(order: order)
            }
    }

    private func place(_ order: VaultTestOrder) {
        // The test has to be popped before the receipt comes up over it.
        Task {
            try? await Task.sleep(for: .seconds(Constants.popDuration))
            receipt = order
        }
    }

    private enum Constants {
        static let popDuration: TimeInterval = 0.35
    }
}

#Preview {
    NavigationStack {
        VaultGuidedTestingScreen()
    }
}
