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
    @State private var genomeViewModel = GenomeViewModel()
    @State private var orderViewModel = GenomeOrderViewModel()
    @State private var genomeScenario = GenomeDemoScenario.current
    @State private var showingGenome = false
    @State private var showingAddresses = false
    @State private var showingCards = false

    var body: some View {
        BrightSwipePageViewV5(
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
            BrightReceiptSheetV5(order: order)
        }
        .overlay(alignment: .topTrailing) {
            if selectedPage == 1 {
                genomeScenarioPicker
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
        .sheet(
            isPresented: $orderViewModel.showingOrderSheet,
            onDismiss: { orderViewModel.handleOrderSheetDismissed() }
        ) {
            GenomeOrderSheet(viewModel: orderViewModel)
        }
    }

    @ViewBuilder
    private var guidedTesting: some View {
        if guidedOrders.isEmpty {
            BrightPlaceholderViewV5(
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
        Group {
            if genomeViewModel.orderStatus == .none, !genomeViewModel.hasResults {
                Button { orderViewModel.handleOrderTapped() } label: {
                    GenomeOrderWidget()
                }
                .buttonStyle(.plain)
                .padding(.spacing3x)
                .frame(maxHeight: .infinity, alignment: .top)
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

    private var genomeScenarioPicker: some View {
        Menu {
            Section("Scenario") {
                ForEach(GenomeDemoScenario.allCases) { scenario in
                    Button {
                        selectGenomeScenario(scenario)
                    } label: {
                        Label {
                            Text(scenario.title)
                        } icon: {
                            if genomeScenario == scenario {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "ladybug.fill")
                .padding(.spacing2x)
        }
        .padding(.spacing3x)
    }

    private func selectGenomeScenario(_ scenario: GenomeDemoScenario) {
        GenomeDemoScenario.current = scenario
        genomeScenario = scenario
        genomeViewModel.load(scenario)
    }
}

#Preview {
    NavigationStack {
        MyOrdersView()
    }
}
