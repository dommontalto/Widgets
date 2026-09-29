//
//  GenomeView.swift
//  Widgets
//

import SwiftUI

struct GenomeView: View {
    @State private var scenario = GenomeDemoScenario.current
    @State private var viewModel = GenomeViewModel()
    @State private var orderViewModel = GenomeOrderViewModel()

    var body: some View {
        content
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.infoTapped()
                } label: {
                    Label("Info", systemImage: "info")
                        .labelStyle(.iconOnly)
                }
            }
        }
        .modifier(GenomePresentations(viewModel: viewModel, orderViewModel: orderViewModel))
    }

    private var content: some View {
        BrightSwipePageView(
            pages: GenomeViewTab.allCases.map { SwipePage(title: $0.displayTitle, systemImage: $0.systemImage) },
            fakeLargeTitle: "Genome",
            bottomSafeArea: false,
            backgroundColor: .defaultBackground,
            selectedIndex: Bindable(viewModel).selectedTabIndex
        ) { index in
            switch GenomeViewTab(rawValue: index) ?? .summary {
            case .summary:
                GenomeSummaryTab(viewModel: viewModel, orderViewModel: orderViewModel)
            case .categories:
                GenomeCategoriesTab(viewModel: viewModel, orderViewModel: orderViewModel)
            }
        }
        .overlay(alignment: .topTrailing) { scenarioPicker }
    }

    private var scenarioPicker: some View {
        Menu {
            Section("Scenario") {
                ForEach(GenomeDemoScenario.allCases) { option in
                    Button {
                        selectScenario(option)
                    } label: {
                        Label {
                            Text(option.title)
                        } icon: {
                            if scenario == option {
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

    private func selectScenario(_ option: GenomeDemoScenario) {
        GenomeDemoScenario.current = option
        scenario = option
        viewModel.load(option)
    }

    // MARK: - Tabs

    private struct GenomeSummaryTab: View {
        @Bindable var viewModel: GenomeViewModel
        @Bindable var orderViewModel: GenomeOrderViewModel

        var body: some View {
            VStack(spacing: .spacing3x) {
                if let riskPercentile = viewModel.riskPercentile {
                    GenomePercentileGraphWidget(data: riskPercentile)
                }

                if !viewModel.hasResults {
                    if viewModel.canOrder {
                        Button { orderViewModel.handleOrderTapped() } label: {
                            GenomeOrderWidget()
                        }
                        .buttonStyle(.plain)
                    } else {
                        GenomeOrderStatusWidget(
                            status: viewModel.orderStatus,
                            order: viewModel.orderInfo
                        )
                    }
                }

                if !viewModel.leadingContributors.isEmpty {
                    BrightText("Leading contributors", size: .standout2)
                        .padding(.leading, .spacing2x)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    GenomeContributorWidget(contributors: viewModel.leadingContributors) { contributor in
                        viewModel.showMarker(canonicalName: contributor.canonicalName)
                    }
                }
            }
            .padding(.spacing3x)
        }
    }

    private struct GenomeCategoriesTab: View {
        @Bindable var viewModel: GenomeViewModel
        @Bindable var orderViewModel: GenomeOrderViewModel

        var body: some View {
            Group {
                if viewModel.categories.isEmpty {
                    BrightPlaceholderView(
                        image: ImageNames.genomeV5,
                        title: "Categories coming soon",
                        subtitle: "Your impact categories will appear here once your genome results are ready."
                    )
                } else {
                    GenomeImpactCategoryWidget(
                        categories: viewModel.categories,
                        onSelect: viewModel.handleCategorySelected
                    )
                }
            }
            .padding(.spacing3x)
        }
    }
}

private struct GenomePresentations: ViewModifier {
    @Bindable var viewModel: GenomeViewModel
    @Bindable var orderViewModel: GenomeOrderViewModel

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $viewModel.showingGenomeInfo) {
                GenomeInfoSheet()
            }
            .sheet(isPresented: $orderViewModel.showingOrderSheet) {
                GenomeOrderSheet(viewModel: orderViewModel)
            }
            .sheet(item: $viewModel.selectedCategory) { category in
                GenomeCategorySheet(category: category, dataMarkers: viewModel.dataMarkers)
            }
            .brightMiniSheet(isPresented: markerShown) {
                if let marker = viewModel.selectedMarker {
                    GenomeGeneMiniSheet(marker: marker) { viewModel.selectedMarker = nil }
                }
            }
            .fullScreenCover(
                isPresented: $orderViewModel.showingCheckout,
                onDismiss: { orderViewModel.handleCheckoutCoverDismissed() }
            ) {
                if let url = orderViewModel.checkoutURL {
                    SafariView(url: url) {
                        orderViewModel.handleCheckoutClosed()
                    }
                    .ignoresSafeArea()
                }
            }
            .sheet(
                isPresented: $orderViewModel.showingConfirmation,
                onDismiss: { orderViewModel.handleConfirmationDismissed() }
            ) {
                GenomeOrderConfirmationSheet(viewModel: orderViewModel)
            }
    }

    private var markerShown: Binding<Bool> {
        Binding(
            get: { viewModel.selectedMarker != nil },
            set: { if !$0 { viewModel.selectedMarker = nil } }
        )
    }
}
