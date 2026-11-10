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
    @State private var viewModel = VaultViewModel()
    @State private var openedPage: VaultPage?
    @State private var genomeViewModel = GenomeViewModel()
    @State private var genomeOrderViewModel = GenomeOrderViewModel()

    var body: some View {
        BrightSwipePageViewV5(
            pages: VaultViewTab.allCases.map { SwipePage(title: $0.displayTitle, systemImage: $0.systemImage) },
            fakeLargeTitle: title,
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
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    openedPage = .upload
                } label: {
                    Label("Upload", systemImage: "arrow.up.document")
                        .labelStyle(.iconOnly)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    openedPage = .share
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                }
            }
        }
        .onAppear { viewModel.loadIfNeeded() }
        .sheet(item: $detailData) { data in
            VaultMarkerDetailSheet(data: data)
        }
        .sheet(
            isPresented: $genomeOrderViewModel.showingOrderSheet,
            onDismiss: { genomeOrderViewModel.handleOrderSheetDismissed() }
        ) {
            GenomeOrderSheet(viewModel: genomeOrderViewModel)
        }
        .sheet(item: $openedPage) { page in
            switch page {
            case .upload:
                VaultUploadSheet()
            case .datapoints:
                VaultDatapointsListSheet(markers: viewModel.performanceMarkers)
            case .documents:
                VaultDocumentsListSheet(documents: viewModel.documents) { document in
                    VaultDocumentPreviewView(document: document)
                }
            case let .document(document):
                BrightPageSheetViewV5(title: document.labName, horizontalPadding: .spacing0x) {
                    VaultDocumentPreviewView(document: document)
                }
            default:
                BrightPageSheetViewV5(title: page.title) {
                    EmptyView()
                }
            }
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
        VStack(alignment: .leading, spacing: .spacing5x) {
            BrightWidgetTitleV5(icon: .symbol("circle.hexagonpath.fill"), title: "All datapoints") {
                VaultDatapointsWidget(datapoints: viewModel.completeness?.datapoints ?? []) {
                    openedPage = .datapoints
                }
            }

            if genomeViewModel.orderStatus == .none, !genomeViewModel.hasResults {
                Button { genomeOrderViewModel.handleOrderTapped() } label: {
                    GenomeOrderWidget()
                }
                .buttonStyle(.plain)
            }

            if !viewModel.documents.isEmpty {
                BrightWidgetTitleV5(icon: .symbol("waveform.path.ecg.text.page.fill"), title: "My Documents") {
                    VaultDocumentsWidget(
                        documents: Array(viewModel.documents.prefix(3)),
                        onExpand: { openedPage = .documents },
                        onOpen: { openedPage = .document($0) }
                    )
                }
            }
        }
        .padding(.spacing3x)
    }
}

private struct VaultUploadSheet: View {
    @State private var showingImportInstructions = false

    var body: some View {
        BrightPageSheetViewV5 {
            VaultUploadRecordsView(
                onScan: {},
                onChooseImage: {},
                onChooseFile: {},
                onImportFromApp: { showingImportInstructions = true }
            )
        }
        .brightMiniSheetV5(isPresented: $showingImportInstructions) {
            ShareFromAppInstructionsMiniSheet {
                showingImportInstructions = false
            }
        }
    }
}

private enum VaultPage: Identifiable {
    case upload
    case share
    case datapoints
    case documents
    case document(VaultDocumentSummary)

    var id: String {
        switch self {
        case .upload: "upload"
        case .share: "share"
        case .datapoints: "datapoints"
        case .documents: "documents"
        case let .document(document): document.id
        }
    }

    var title: String {
        switch self {
        case .upload: "Upload"
        case .share: "Share"
        case .datapoints: "All datapoints"
        case .documents: "My Documents"
        case let .document(document): document.labName
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
