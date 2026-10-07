//
//  GenomeViewModel.swift
//  Widgets
//

import SwiftUI

enum GenomeViewTab: Int, CaseIterable {
    case summary
    case categories

    var displayTitle: String {
        switch self {
        case .summary: "Summary"
        case .categories: "Categories"
        }
    }

    var systemImage: String {
        switch self {
        case .summary: "ellipsis.calendar"
        case .categories: "folder.fill"
        }
    }
}

@MainActor
@Observable
final class GenomeViewModel {

    // MARK: - State

    var selectedTabIndex = 0
    var showingGenomeInfo = false
    var selectedCategory: GenomeCategory?
    var selectedMarker: GenomeDataMarker?

    private(set) var orderStatus: GenomeOrderStatus = .none
    private(set) var summary: GenomeSummaryData?
    private(set) var categories: [GenomeCategory] = []
    private(set) var dataMarkers: [GenomeDataMarker] = []

    var orderFailed: Bool { orderStatus == .failed || orderStatus == .cancelled }
    var canOrder: Bool { orderStatus.isTerminal && !orderFailed }
    var hasResults: Bool { riskPercentile != nil || !leadingContributors.isEmpty || categories.contains(where: \.isInteractive) }
    var orderInfo: GenomeOrderInfo? { summary?.order }
    var leadingContributors: [GenomeContributor] { summary?.leadingContributors ?? [] }
    var riskPercentile: GenomeRiskPercentile? { summary?.riskPercentile }

    // Optional rather than defaulting to `.current`: default arguments are evaluated
    // off the main actor, where the main-actor `current` can't be read.
    init(scenario: GenomeDemoScenario? = nil) {
        load(scenario)
    }

    // MARK: - Actions

    func infoTapped() {
        showingGenomeInfo = true
    }

    func handleCategorySelected(_ category: GenomeCategory) {
        guard category.isInteractive else { return }
        selectedCategory = category
    }

    func showMarker(canonicalName: String) {
        selectedMarker = dataMarkers.first { $0.canonicalName == canonicalName }
    }

    // MARK: - Demo data

    func load(_ scenario: GenomeDemoScenario? = nil) {
        let scenario = scenario ?? .current
        summary = scenario.summary
        orderStatus = scenario.status
        categories = scenario.categories
        dataMarkers = scenario.dataMarkers
    }
}
