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
        BrightSwipePageViewV5(
            pages: GenomeViewTab.allCases.map { SwipePage(title: $0.displayTitle, systemImage: $0.systemImage) },
            fakeLargeTitle: "DNA",
            pillAccessory: viewModel.isDemo ? AnyView(GenomeSampleTag()) : nil,
            verticalScrollDisabledPageIndex: GenomeViewTab.data.rawValue,
            backgroundColor: .defaultBackground,
            selectedIndex: Bindable(viewModel).selectedTabIndex
        ) { index in
            switch GenomeViewTab(rawValue: index) ?? .summary {
            case .summary:
                GenomeSummaryTab(viewModel: viewModel, orderViewModel: orderViewModel)
            case .categories:
                GenomeCategoriesTab(viewModel: viewModel, orderViewModel: orderViewModel)
            case .data:
                GenomeDataView(
                    markers: viewModel.orderedMarkers,
                    isActive: viewModel.selectedTabIndex == GenomeViewTab.data.rawValue,
                    focus: Bindable(viewModel).strandFocus
                )
                    .containerRelativeFrame([.horizontal, .vertical])
                    .ignoresSafeArea()
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
                BrightWaveWidgetV5(
                    title: "Genetic Risk Percentile",
                    fraction: viewModel.riskPercentile.map { Double($0.value) / 100 },
                    emptySubtitle: "Your percentile appears once your results are in",
                    style: .genome,
                    comparison: BrightWaveComparison(lead: "Your genetic risk is higher than", trail: "of people")
                )

                if !viewModel.hasResults {
                    if viewModel.canOrder {
                        Button { orderViewModel.handleOrderTapped() } label: {
                            GenomeOrderWidget()
                        }
                        .buttonStyle(.plain)
                    } else {
                        GenomeOrderCard(
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
                        viewModel.showOnStrand(canonicalName: contributor.canonicalName)
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
            VStack(spacing: .spacing3x) {
                GenomeImpactCategoryWidget(
                    categories: viewModel.displayedCategories,
                    onSelect: viewModel.handleCategorySelected
                )
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
            .sheet(
                isPresented: $orderViewModel.showingOrderSheet,
                onDismiss: { orderViewModel.handleOrderSheetDismissed() }
            ) {
                GenomeOrderSheet(viewModel: orderViewModel)
            }
            .navigationDestination(item: $viewModel.selectedCategory) { category in
                GenomeCategoryView(category: category) { viewModel.showOnStrand(canonicalName: $0) }
            }
    }
}
