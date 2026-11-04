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
    private(set) var documents: [VaultDocumentSummary] = []

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
        documents = VaultDemo.documents
        summaryState = .loaded
    }

    // Display mapping

    static func rangeMarker(from marker: VaultMarkerData) -> VaultRangeMarkerData {
        VaultRangeMarkerData(
            id: marker.id,
            title: marker.name,
            lastUpdated: marker.lastUpdated ?? "",
            value: marker.value,
            unit: marker.unit,
            markerPosition: markerPosition(value: marker.value, range: marker.normalRange, direction: marker.direction),
            direction: marker.direction,
            hasRange: marker.normalRange != nil
        )
    }

    // Where a value sits on the range bar. In range it fills the green segment, which runs
    // to the bar's edge on a one-sided marker's good side.
    static func markerPosition(value: String, range: ClosedRange<Double>?, direction: VaultMarkerDirection = .optimalBand) -> Double {
        guard let value = Double(value),
              let range,
              range.upperBound > range.lowerBound else { return 0.45 }
        let normalized = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        switch direction {
        case .higherBetter where normalized >= 0:
            return min(1, 0.20 + normalized * 0.75)
        case .lowerBetter where normalized <= 1:
            return max(0, 0.05 + normalized * 0.65)
        default:
            return min(1, max(0, 0.20 + normalized * 0.50))
        }
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
            normalRange: marker.normalRange,
            direction: marker.direction
        )
    }
}
