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
    @State private var showingLighthouse = false
    @State private var lighthouseDetent = LighthouseTrayGuidedTesting.restDetent

    var body: some View {
        VaultGuidedTestingHomeView(onOrder: place)
            // A trial of Lighthouse as a tray that stays at the bottom, the way Maps keeps its search.
            .sheet(isPresented: $showingLighthouse) {
                LighthouseTrayGuidedTesting(detent: $lighthouseDetent)
                    .presentationDetents([LighthouseTrayGuidedTesting.restDetent, .medium, .large], selection: $lighthouseDetent)
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled()
            }
            .onAppear { showingLighthouse = true }
            .onDisappear { showingLighthouse = false }
            .sheet(item: $receipt, onDismiss: { showingLighthouse = true }) { order in
                BrightReceiptSheetV5(order: order)
            }
    }

    private func place(_ order: VaultTestOrder) {
        // The test has to be popped before the receipt comes up over it.
        showingLighthouse = false
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
