//
//  VaultDataModels.swift
//  Widgets
//
//  Created by Dom Montalto on 4/11/2026.
//

import Foundation

struct VaultCompletenessData {
    let lifestyleCompleteCount: Int?
    let lifestyleTotalCount: Int?
    let clinicalCompleteCount: Int?
    let clinicalTotalCount: Int?
    let geneticCompleteCount: Int?
    let geneticTotalCount: Int?
    let completeCount: Int?
    let totalCount: Int?
    let resolutionPct: Double?
    let byCategory: [VaultCompletenessCategory]?
    let datapoints: [VaultCompletenessDatapoint]?
}

struct VaultCompletenessCategory {
    let category: String?
    let complete: Int?
    let total: Int?
}

struct VaultCompletenessDatapoint: Equatable {
    let name: String?
    let category: String?
    let bucket: String?
    let complete: Bool?
    let unit: String?
    let lastUpdated: String?
    var id: String? = nil
    var value: String? = nil
    var markerPosition: Double? = nil
    var direction: String? = nil
}

struct VaultMarkerHistoryData {
    let markerId: String?
    let name: String?
    let category: String?
    let unit: String?
    let normalLow: Double?
    let normalHigh: Double?
    let average: Double?
    let rangeMin: Double?
    let rangeMax: Double?
    let readings: [VaultMarkerHistoryReading]?
}

struct VaultMarkerHistoryReading: Identifiable {
    let date: String?
    let lastUpdated: String?
    let value: Double?
    let unit: String?
    let status: String?
    let markerPosition: Double?
    let normalLow: Double?
    let normalHigh: Double?
    let reportId: String?

    var id: String { "\(reportId ?? "")-\(date ?? "")-\(value ?? 0)" }
}
