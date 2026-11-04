//
//  VaultView.swift
//  Widgets
//
//  Created by Dom Montalto on 10/5/2026.
//

import SwiftUI

enum VaultImpactSection: String, BrightReorderableSection {
    case summary
    case why
    case what
    case how
}

enum VaultViewTab: Int, CaseIterable, TabDisplayable {
    case summary
    case impact
    case data

    var displayTitle: String {
        switch self {
        case .summary: "Summary"
        case .impact: "Impact"
        case .data: "Data"
        }
    }

    var systemImage: String {
        switch self {
        case .summary: "ellipsis.calendar"
        case .impact: "arrow.down.circle.fill"
        case .data: "chart.xyaxis.line"
        }
    }
}

struct VaultView: View {
    let title: String

    @State private var selectedTabIndex = 0
    @State private var detailData: VaultMarkerDetailData?
    @State private var dataSearchText = ""
    @State private var isDataSearchFocused = false
    @State private var viewModel = VaultViewModel()

    var body: some View {
        BrightSwipePageViewV5(
            pages: VaultViewTab.allCases.map { SwipePage(title: $0.displayTitle, systemImage: $0.systemImage) },
            fakeLargeTitle: title,
            scrollDismissesKeyboardMode: .interactively,
            backgroundColor: .defaultBackground,
            selectedIndex: $selectedTabIndex
        ) { index in
            switch VaultViewTab(rawValue: index) ?? .summary {
            case .summary:
                summaryTab
            case .impact:
                impactTab
            case .data:
                dataTab
            }
        }
        .onAppear { viewModel.loadIfNeeded() }
        .sheet(item: $detailData) { data in
            VaultMarkerDetailSheet(data: data)
        }
    }

    private var summaryTab: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            VaultSummaryWidget(
                ranking: viewModel.ranking,
                fallbackTopPercent: viewModel.fallbackTopPercent
            )

            VStack(alignment: .leading, spacing: .spacing3x) {
                BrightText("Primary Contributors", size: .standout2)
                    .padding(.leading, .spacing2x)
                    .padding(.top, .spacing5x)

                if viewModel.summaryMarkers.isEmpty {
                    VaultLoadStatePlaceholder(state: viewModel.summaryState) {
                        viewModel.reload()
                    }
                } else {
                    ForEach(viewModel.summaryMarkers) { marker in
                        VaultMarkerWidget(data: VaultViewModel.rangeMarker(from: marker)) {
                            detailData = VaultViewModel.detail(from: marker)
                        }
                        .equatable()
                    }
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.defaultBackground)
    }

    @ViewBuilder
    private var impactTab: some View {
        if viewModel.impactCards.isEmpty {
            VaultLoadStatePlaceholder(state: viewModel.summaryState) {
                viewModel.reload()
            }
        } else {
            BrightReorderableStackV5(.vaultImpact, alignment: .center) { (section: VaultImpactSection) in
                switch section {
                case .summary:
                    BrightImpactWidgetV5(type: .summary, data: viewModel.impactCards[.summary])
                case .why:
                    BrightImpactWidgetV5(type: .why, data: viewModel.impactCards[.why])
                case .what:
                    BrightImpactWidgetV5(type: .what, data: viewModel.impactCards[.what])
                case .how:
                    BrightImpactWidgetV5(type: .how, data: viewModel.impactCards[.how])
                }
            }
            .padding(.spacing3x)
        }
    }

    private var dataTab: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightSearchBarV5("Search data points", text: $dataSearchText) { isDataSearchFocused = $0 }

            VStack(alignment: .leading, spacing: .spacing3x) {
                if !isSearchingData {
                    VaultDatapointsWidget(
                        datapoints: viewModel.completeness?.datapoints ?? []
                    )

                    BrightText("All Datapoints", size: .standout2)
                        .padding([.top, .leading], .spacing2x)
                }

                dataMarkerList
            }
            .opacity(isDataFaded ? .zero : .opaque)
            .allowsHitTesting(!isDataFaded)
        }
        .padding(.spacing3x)
        .animation(.brightEaseInOut, value: isSearchingData)
        .animation(.brightEaseInOut, value: isDataFaded)
    }

    private var isSearchingData: Bool {
        !dataSearchText.isEmpty
    }

    private var isDataFaded: Bool {
        isDataSearchFocused && !isSearchingData
    }

    private var dataMarkers: [VaultMarkerData] {
        viewModel.markers(searchText: dataSearchText)
    }

    @ViewBuilder
    private var dataMarkerList: some View {
        if dataMarkers.isEmpty, isSearchingData {
            BrightPlaceholderViewV5(
                systemImage: "magnifyingglass",
                title: "No matches",
                subtitle: "Try a different search."
            )
            .padding(.spacing3x)
        } else if dataMarkers.isEmpty {
            VaultLoadStatePlaceholder(state: viewModel.summaryState) {
                viewModel.reload()
            }
        } else {
            LazyVStack(spacing: .spacing3x) {
                ForEach(dataMarkers) { marker in
                    VaultMarkerWidget(data: VaultViewModel.rangeMarker(from: marker)) {
                        detailData = VaultViewModel.detail(from: marker)
                    }
                    .equatable()
                }
            }
        }
    }
}

struct VaultLoadStatePlaceholder: View {
    let state: VaultViewModel.LoadState
    let onRetry: () -> Void

    var body: some View {
        Group {
            switch state {
            case .failed(let message):
                BrightPlaceholderViewV5(
                    systemImage: "exclamationmark.triangle",
                    title: "Couldn't load your vault",
                    subtitle: message,
                    imageColor: .defaultOrange,
                    buttonTitle: "Retry",
                    buttonAction: onRetry
                )
            default:
                BrightPlaceholderViewV5(
                    systemImage: "tray",
                    title: "Nothing here yet",
                    subtitle: "Upload a lab document or connect a wearable to see your markers."
                )
            }
        }
        .padding(.spacing3x)
    }
}
