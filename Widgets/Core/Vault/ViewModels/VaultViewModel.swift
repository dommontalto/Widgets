//
//  VaultViewModel.swift
//  Widgets
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class VaultViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(message: String)
    }

    // Summary
    private(set) var summaryState: LoadState = .idle
    private(set) var fallbackTopPercent: Double?
    private(set) var ranking: VaultRankingData?
    private(set) var summaryMarkers: [VaultMarkerData] = []

    // Impact
    private(set) var impactCards: [CycleTrackingImpactType: CycleTrackingImpactData] = [:]

    // Data
    private(set) var completeness: VaultCompletenessData?
    private(set) var performanceMarkers: [VaultMarkerData] = []

    func loadIfNeeded() {
        guard summaryState == .idle else {
            return
        }
        reload()
    }

    func reload() {
        ranking = VaultDemo.ranking
        summaryMarkers = VaultDemo.summaryMarkers
        impactCards = VaultDemo.impactCards
        completeness = VaultDemo.completeness
        performanceMarkers = VaultDemo.dataMarkers
        summaryState = .loaded
    }

    // Filtering

    func markers(searchText: String) -> [VaultMarkerData] {
        let matched = performanceMarkers
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        guard !searchText.isEmpty else { return matched }
        return matched.filter { $0.name.localizedStandardContains(searchText) }
    }

    // Display mapping

    static func rangeMarker(from marker: VaultMarkerData) -> VaultRangeMarkerData {
        VaultRangeMarkerData(
            id: marker.id,
            title: marker.name,
            lastUpdated: marker.lastUpdated ?? "",
            value: marker.value,
            unit: marker.unit,
            markerPosition: markerPosition(value: marker.value, range: marker.normalRange)
        )
    }

    static func markerPosition(value: String, range: ClosedRange<Double>?) -> Double {
        guard let value = Double(value),
              let range,
              range.upperBound > range.lowerBound else { return 0.45 }
        let normalized = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return min(1, max(0, 0.20 + normalized * 0.50))
    }

    static func detail(from marker: VaultMarkerData) -> VaultMarkerDetailData {
        VaultMarkerDetailData(
            markerId: marker.id,
            title: marker.name,
            subtitle: marker.category,
            value: marker.value,
            unit: marker.unit,
            status: marker.status,
            accentColor: BrightStatus(status: marker.status).color,
            normalRange: marker.normalRange
        )
    }
}
