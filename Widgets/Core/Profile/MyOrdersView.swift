//
//  MyOrdersView.swift
//  Widgets
//
//  Created by Dom Montalto on 28/9/2026.
//

import SwiftUI

// Every test ordered through Bright, split by where it came from. Lab orders come from the demo lab service; the DNA
// page shows the demo genome scenario.
struct MyOrdersView: View {
    private enum Page: Int, CaseIterable {
        case guidedTesting
        case genome

        var swipePage: SwipePage {
            switch self {
            case .guidedTesting: SwipePage(title: "Labs", systemImage: "heart.text.square")
            case .genome: SwipePage(title: "DNA", image: ImageNames.genomeV5)
            }
        }
    }

    @State private var selectedPage = 0
    @State private var labOrders = [LabOrder]()
    // Nothing is "No orders yet" until a load has worked.
    @State private var labOrdersState = LabOrdersState.loading
    @State private var shownLabOrder: LabOrder?
    @State private var genomeViewModel = GenomeViewModel()
    @State private var showingGenome = false
    @State private var showingAddresses = false
    @State private var showingCards = false
    @State private var showingGuidedTesting = false

    var body: some View {
        BrightSwipePageViewV5(
            pages: Page.allCases.map(\.swipePage),
            fakeLargeTitle: "My Orders",
            backgroundColor: .defaultBackground,
            selectedIndex: $selectedPage
        ) { index in
            switch Page.allCases[index] {
            case .guidedTesting:
                guidedTesting
            case .genome:
                genome
            }
        }
        .sheet(item: $shownLabOrder) { order in
            LabOrderSheet(order: order, onChange: update)
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
        .navigationDestination(isPresented: $showingGuidedTesting) {
            VaultGuidedTestingScreen()
        }
        .navigationDestination(isPresented: $showingGenome) {
            GenomeView()
        }
        .task {
            await loadLabOrders()
        }
        .task {
            genomeViewModel.load()
        }
    }

    @ViewBuilder
    private var guidedTesting: some View {
        if labOrdersState == .loading {
            BrightProgressViewV5()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if labOrdersState == .failed {
            BrightPlaceholderViewV5(
                systemImage: "wifi.exclamationmark",
                title: "Couldn't load your orders",
                subtitle: "Check your connection and try again.",
                buttonTitle: "Try again"
            ) {
                labOrdersState = .loading
                Task { await loadLabOrders() }
            }
        } else if labOrders.isEmpty {
            BrightPlaceholderViewV5(
                systemImage: "shippingbox",
                title: "No orders yet",
                subtitle: "Tests you order through Labs will show up here with their status.",
                buttonTitle: "Order Test Kit"
            ) {
                showingGuidedTesting = true
            }
        } else {
            VStack(spacing: .spacing3x) {
                ForEach(labOrders) { order in
                    LabOrderCard(order: order) { shownLabOrder = order }
                }
            }
            .padding(.spacing3x)
            .padding(.bottom, .spacing10x)
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
                GenomeOrderStatusWidget(
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

    private func loadLabOrders() async {
        do {
            labOrders = try await LabOrdersMockService().getOrders().filter { $0.status != "awaiting_payment" }
            labOrdersState = .loaded
        } catch {
            Log("Labs: orders load failed – \(error)")
            labOrdersState = .failed
        }
    }

    private func update(_ order: LabOrder) {
        guard let index = labOrders.firstIndex(where: { $0.id == order.id }) else { return }
        labOrders[index] = order
    }
}

#Preview {
    NavigationStack {
        MyOrdersView()
    }
}

private enum LabOrdersState {
    case loading, loaded, failed
}
