//
//  MyOrdersView.swift
//  Widgets
//
//  Created by Dom Montalto on 28/9/2026.
//

import SwiftUI

// Every test ordered through Bright, split by where it came from.
struct MyOrdersView: View {
    @State private var selectedPage = 0
    @State private var guidedOrders = VaultTestOrder.demo
    @State private var receipt: VaultTestOrder?

    var body: some View {
        BrightSwipePageView(
            pages: [
                SwipePage(title: "Guided Testing", systemImage: "heart.text.square"),
                SwipePage(title: "Genome", image: ImageNames.genomeV5),
            ],
            fakeLargeTitle: "My Orders",
            backgroundColor: .defaultBackground,
            selectedIndex: $selectedPage
        ) { page in
            if page == 0 {
                guidedTesting
            } else {
                genome
            }
        }
        .sheet(item: $receipt) { order in
            VaultTestReceiptSheet(order: order)
        }
    }

    @ViewBuilder
    private var guidedTesting: some View {
        if guidedOrders.isEmpty {
            BrightPlaceholderView(
                systemImage: "shippingbox",
                title: "No orders yet",
                subtitle: "Tests you order through Guided Testing will show up here with their status."
            )
        } else {
            VStack(spacing: .spacing3x) {
                ForEach(guidedOrders) { order in
                    VaultOrderCard(order: order) { receipt = order }
                }
            }
            .padding(.spacing3x)
            .padding(.bottom, .spacing10x)
        }
    }

    private var genome: some View {
        BrightPlaceholderView(
            image: ImageNames.genomeV5,
            title: "No genome orders yet",
            subtitle: "Once you order a genome kit, you can follow it here from dispatch to results."
        )
    }
}

#Preview {
    NavigationStack {
        MyOrdersView()
    }
}
