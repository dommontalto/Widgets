//
//  LabReceiptSheet.swift
//  Widgets
//

import SwiftUI

// The receipt after paying for a lab test. The order reaches the lab a few
// seconds later (Stripe's webhook places it), so the receipt says so until it has.
struct LabReceiptSheet: View {
    let order: VaultTestOrder

    @State private var labOrder: LabOrder?
    @State private var timedOut = false

    private let service: LabOrdersServiceProtocol = LabOrdersMockService()

    var body: some View {
        BrightReceiptSheetV5(order: order, status: status)
            .task { await poll() }
    }

    private var status: BrightReceiptStatus? {
        guard order.labOrderId != nil else { return nil }
        guard let labOrder, labOrder.isPlaced else {
            return timedOut
                ? BrightReceiptStatus(title: Constants.slowTitle, detail: Constants.slowDetail)
                : BrightReceiptStatus(title: Constants.placingTitle, detail: Constants.placingDetail, isWorking: true)
        }
        if labOrder.isFailed {
            return BrightReceiptStatus(title: labOrder.headline.title, detail: labOrder.headline.detail ?? Constants.failedDetail, isFailed: true)
        }
        return BrightReceiptStatus(title: Constants.placedTitle, detail: Constants.placedDetail)
    }

    private func poll() async {
        guard let id = order.labOrderId else { return }
        for _ in 0..<Constants.polls {
            if let fresh = try? await service.getOrder(id: id) {
                labOrder = fresh
                if fresh.isPlaced { return }
            }
            try? await Task.sleep(for: .seconds(Constants.pollSeconds))
            guard !Task.isCancelled else { return }
        }
        timedOut = true
    }

    private enum Constants {
        static let polls = 40
        static let pollSeconds = 3.0
        static let placingTitle = "Placing your order"
        static let placingDetail = "Payment received. We're sending your order to the lab now."
        static let placedTitle = "Order placed"
        static let placedDetail = "Follow it in My Orders. We'll let you know at each step."
        static let slowTitle = "Still placing your order"
        static let slowDetail = "This is taking longer than usual. It'll appear in My Orders, and we'll let you know."
        static let failedDetail = "We couldn't place this order with the lab, so we're refunding you in full."
    }
}
