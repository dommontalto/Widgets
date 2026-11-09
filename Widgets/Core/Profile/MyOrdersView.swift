//
//  MyOrdersView.swift
//  Widgets
//
//  Created by Dom Montalto on 28/9/2026.
//

import SwiftUI

// Every test ordered through Bright. The DNA page shows the demo genome scenario.
struct MyOrdersView: View {
    private enum Page: Int, CaseIterable {
        case genome

        var swipePage: SwipePage {
            switch self {
            case .genome: SwipePage(title: "DNA", image: ImageNames.genomeV5)
            }
        }
    }

    @State private var selectedPage = 0
    @State private var genomeViewModel = GenomeViewModel()
    @State private var showingGenome = false
    @State private var showingAddresses = false
    @State private var showingCards = false

    var body: some View {
        BrightSwipePageViewV5(
            pages: Page.allCases.map(\.swipePage),
            fakeLargeTitle: "My Orders",
            backgroundColor: .defaultBackground,
            selectedIndex: $selectedPage
        ) { index in
            switch Page.allCases[index] {
            case .genome:
                genome
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCards = true
                } label: {
                    Label("Cards", systemImage: "creditcard")
                        .labelStyle(.iconOnly)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddresses = true
                } label: {
                    Label("Addresses", systemImage: "house")
                        .labelStyle(.iconOnly)
                }
            }
        }
        .navigationDestination(isPresented: $showingCards) {
            CardsView()
        }
        .navigationDestination(isPresented: $showingAddresses) {
            AddressesView()
        }
        .navigationDestination(isPresented: $showingGenome) {
            GenomeView()
        }
        .task {
            genomeViewModel.load()
        }
    }

    private var genome: some View {
        Group {
            if genomeViewModel.orderStatus == .none, !genomeViewModel.hasResults {
                BrightPlaceholderViewV5(
                    image: ImageNames.genomeV5,
                    title: "No orders yet",
                    subtitle: "Your DNA kit will show up here with its status once you order it.",
                    buttonTitle: "Order DNA Kit"
                ) {
                    showingGenome = true
                }
            } else {
                GenomeOrderCard(
                    status: genomeViewModel.hasResults ? .ready : genomeViewModel.orderStatus,
                    order: genomeViewModel.hasResults ? nil : genomeViewModel.orderInfo
                ) {
                    showingGenome = true
                }
                .padding(.spacing3x)
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MyOrdersView()
    }
}
