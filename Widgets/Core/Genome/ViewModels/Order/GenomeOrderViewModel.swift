//
//  GenomeOrderViewModel.swift
//  Widgets
//

import SwiftUI

@MainActor
@Observable
final class GenomeOrderViewModel {
    enum OrderConfirmationState: Equatable {
        case confirming
        case confirmed
        case pendingWebhook
    }

    var showingOrderSheet = false
    var showingCheckout = false
    var showingConfirmation = false
    private(set) var isStartingCheckout = false
    private(set) var confirmationState: OrderConfirmationState?

    let checkoutItem = GenomeDemo.checkoutItem

    func handleOrderTapped() {
        showingOrderSheet = true
    }

    func handlePurchase() {
        showingCheckout = true
    }

    func handlePay(_ details: BrightCheckoutDetails) {
        confirmationState = .confirmed
        showingConfirmation = true
    }

    func handleOrderSheetDismissed() {
        showingCheckout = false
        showingConfirmation = false
        confirmationState = nil
    }
}
