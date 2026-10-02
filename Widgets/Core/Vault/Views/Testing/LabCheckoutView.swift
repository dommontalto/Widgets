//
//  LabCheckoutView.swift
//  Widgets
//

import SwiftUI

struct LabCheckoutView: View {
    @Bindable var viewModel: LabOrderViewModel

    var body: some View {
        BrightCheckoutViewV5(
            item: viewModel.checkoutItem,
            isPaying: viewModel.isPaying,
            onPay: viewModel.handlePay
        )
        .alert("Lab test", isPresented: $viewModel.showingCheckoutError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
