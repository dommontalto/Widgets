//
//  VaultGuidedTestingScreen.swift
//  Widgets
//
//  Created by Dom Montalto on 17/9/2026.
//

import SwiftUI

// Guided Testing pushed into the host stack: the clinics home, with each clinic
// opening in a sheet over it.
struct VaultGuidedTestingScreen: View {
    @State private var selectedClinic: VaultTestingClinic?
    @State private var receipt: VaultTestOrder?
    @State private var orders = [VaultTestOrder]()
    @State private var homePage = 0

    var body: some View {
        home
            .sheet(item: $selectedClinic) { clinic in
                VaultClinicSheet(clinic: clinic, onOrder: place)
            }
            .sheet(item: $receipt) { order in
                BrightReceiptSheet(order: order)
            }
    }

    private var home: some View {
        VaultGuidedTestingHomeView(
            orders: orders,
            selectedPage: $homePage,
            onSelectClinic: { selectedClinic = $0 },
            onSelectOrder: { receipt = $0 }
        )
    }

    private func place(_ order: VaultTestOrder) {
        orders.insert(order, at: 0)
        selectedClinic = nil
        withAnimation(.brightEaseInOut) { homePage = 1 }

        // The clinic sheet has to be down before the receipt comes up over it.
        Task {
            try? await Task.sleep(for: .seconds(Constants.sheetDismissDuration))
            receipt = order
        }
    }

    private enum Constants {
        static let sheetDismissDuration: TimeInterval = 0.35
    }
}

#Preview {
    NavigationStack {
        VaultGuidedTestingScreen()
    }
}
