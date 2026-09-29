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
    private(set) var isStartingCheckout = false
    private(set) var checkoutURL: URL?
    var showingCheckout = false
    var showingConfirmation = false
    private(set) var confirmationState: OrderConfirmationState?

    func handleOrderTapped() {
        showingOrderSheet = true
    }

    func handlePurchase() {
        showingOrderSheet = false
        checkoutURL = GenomeDemo.checkoutURL
        showingCheckout = true
    }

    func handleCheckoutClosed() {
        confirmationState = .confirming
        showingCheckout = false
    }

    func handleCheckoutCoverDismissed() {
        checkoutURL = nil
        guard confirmationState != nil else { return }
        showingConfirmation = true
        confirmationState = .confirmed
    }

    func handleConfirmationDismissed() {
        confirmationState = nil
    }
}
