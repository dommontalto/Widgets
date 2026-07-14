//
//  VaultDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import Foundation

// MARK: - Backend-shaped models
// Mirrors the ios Codables for `GET /vault/data/markers` and
// `GET /vault/data/history` — dates travel as ISO 8601 strings.

struct VaultCompletenessData: Codable {
    let completeCount: Int?
    let totalCount: Int?
    let datapoints: [VaultCompletenessDatapoint]?
}

struct VaultCompletenessDatapoint: Codable, Equatable {
    let name: String?
    let category: String?
    let bucket: String?
    let complete: Bool?
    let unit: String?
    let lastUpdated: String?
    var id: String? = nil
    var value: String? = nil
    var markerPosition: Double? = nil
}

struct VaultMarkerHistoryData: Codable {
    let markerId: String?
    let name: String?
    let unit: String?
    let average: Double?
    let rangeMin: Double?
    let rangeMax: Double?
    let readings: [VaultMarkerHistoryReading]?
}

struct VaultMarkerHistoryReading: Codable, Identifiable {
    let date: String?
    let lastUpdated: String?
    let value: Double?
    let unit: String?
    let markerPosition: Double?
    let reportId: String?

    var id: String { "\(reportId ?? "")-\(date ?? "")-\(value ?? 0)" }
}

// MARK: - Demo data

enum VaultDemoData {
    struct Metric {
        let title: String
        let value: String
    }

    static let metrics: [Metric] = [
        Metric(title: "Hemoglobin", value: "14.6 g/dL"),
        Metric(title: "Hematocrit", value: "43.1 %"),
        Metric(title: "WBC Count", value: "6.8 ×10⁹/L"),
        Metric(title: "RBC Count", value: "4.9 ×10¹²/L"),
        Metric(title: "Platelets", value: "248 ×10⁹/L"),
        Metric(title: "HbA1c", value: "5.3 %"),
        Metric(title: "Fasting Glucose", value: "92 mg/dL"),
        Metric(title: "Total Cholesterol", value: "184 mg/dL"),
        Metric(title: "LDL Cholesterol", value: "104 mg/dL"),
        Metric(title: "HDL Cholesterol", value: "58 mg/dL"),
        Metric(title: "Triglycerides", value: "118 mg/dL"),
        Metric(title: "Creatinine", value: "0.92 mg/dL"),
        Metric(title: "eGFR", value: "98 mL/min"),
        Metric(title: "BUN", value: "14 mg/dL"),
        Metric(title: "ALT", value: "27 U/L"),
        Metric(title: "AST", value: "22 U/L"),
        Metric(title: "Total Bilirubin", value: "0.7 mg/dL"),
        Metric(title: "Sodium", value: "140 mmol/L"),
        Metric(title: "Potassium", value: "4.2 mmol/L"),
        Metric(title: "TSH", value: "1.8 mIU/L"),
        Metric(title: "CRP", value: "0.6 mg/L"),
        Metric(title: "Ferritin", value: "112 ng/mL"),
        Metric(title: "Vitamin D", value: "38 ng/mL"),
        Metric(title: "Vitamin B12", value: "476 pg/mL"),
    ]

    static func metric(forIndex index: Int) -> Metric {
        metrics[((index % metrics.count) + metrics.count) % metrics.count]
    }

    static func valueNumber(_ metric: Metric) -> String {
        metric.value.split(separator: " ", maxSplits: 1).first.map(String.init) ?? metric.value
    }

    static func valueUnit(_ metric: Metric) -> String {
        metric.value.split(separator: " ", maxSplits: 1).dropFirst().first.map(String.init) ?? ""
    }

    // MARK: - Completeness (dot grid)

    static let completeness: VaultCompletenessData = {
        let datapoints = (0..<384).map { demoDatapoint(index: $0) }
        return VaultCompletenessData(
            completeCount: datapoints.filter { $0.complete == true }.count,
            totalCount: datapoints.count,
            datapoints: datapoints
        )
    }()

    private static func demoDatapoint(index: Int) -> VaultCompletenessDatapoint {
        let metric = metric(forIndex: index)
        let hash = scatterHash(index)
        let complete = hash % 3 != 0
        return VaultCompletenessDatapoint(
            name: metric.title,
            category: "Clinical",
            bucket: "clinical",
            complete: complete,
            unit: valueUnit(metric),
            lastUpdated: complete ? isoTimestamps[index % isoTimestamps.count] : nil,
            id: "marker-\(index)",
            value: complete ? valueNumber(metric) : nil,
            markerPosition: complete ? Double(hash % 100) / 100 : nil
        )
    }

    /// SplitMix64 finalizer — deterministic scatter, identical on every launch.
    private static func scatterHash(_ x: Int) -> UInt64 {
        var z = UInt64(x) &+ 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    private static let isoTimestamps = [
        "2026-07-10T14:34:00Z",
        "2026-06-28T09:12:00Z",
        "2026-06-03T17:47:00Z",
        "2026-05-16T11:03:00Z",
        "2026-04-21T19:26:00Z",
        "2026-03-02T08:15:00Z",
    ]

    // MARK: - Marker history (detail sheet)

    private static let readingDates = [
        "2026-07-10", "2026-06-26", "2026-06-11", "2026-05-29",
        "2026-05-14", "2026-04-30", "2026-04-16", "2026-04-02",
    ]

    static func markerHistory(for metric: Metric) -> VaultMarkerHistoryData {
        let base = Double(valueNumber(metric)) ?? 50
        let unit = valueUnit(metric)
        let seed = metric.title.hashValue
        let readings = readingDates.enumerated().map { index, date in
            let hash = scatterHash(abs(seed % 1000) + index)
            let value = index == 0 ? base : (base * (0.88 + Double(hash % 25) / 100)).rounded(toPlaces: 1)
            return VaultMarkerHistoryReading(
                date: date,
                lastUpdated: "\(date)T09:30:00Z",
                value: value,
                unit: unit,
                markerPosition: 0.25 + Double(hash % 50) / 100,
                reportId: "report-\(index)"
            )
        }
        let values = readings.compactMap(\.value)
        return VaultMarkerHistoryData(
            markerId: metric.title.lowercased().replacingOccurrences(of: " ", with: "-"),
            name: metric.title,
            unit: unit,
            average: (values.reduce(0, +) / Double(max(1, values.count))).rounded(toPlaces: 1),
            rangeMin: values.min(),
            rangeMax: values.max(),
            readings: readings
        )
    }

    // MARK: - Dates

    static func parseDate(_ iso: String?) -> Date? {
        guard let iso else { return nil }
        if let date = try? Date(iso, strategy: .iso8601) { return date }
        return try? Date(iso, strategy: .iso8601.year().month().day())
    }

    static func displayDateTime(_ iso: String?) -> String? {
        parseDate(iso)?.formatted(date: .abbreviated, time: .shortened)
    }

    static func displayDate(_ iso: String?) -> String? {
        parseDate(iso)?.formatted(.dateTime.day().month(.abbreviated).year())
    }

    // MARK: - Graph demo series

    struct GraphSeries {
        let xDomain: ClosedRange<Double>
        let xLabels: [Double: String]
        let points: [BrightGraphPoint]
    }

    static func graphSeries(for range: String) -> GraphSeries {
        switch range {
        case "W":
            return GraphSeries(
                xDomain: 0...6,
                xLabels: [0: "Mon", 1: "Tue", 2: "Wed", 3: "Thu", 4: "Fri", 5: "Sat", 6: "Sun"],
                points: points([52, 56, 54, 56, 68, 61, 58], startingAt: 0, step: 1)
            )
        case "M":
            return GraphSeries(
                xDomain: 1...30,
                xLabels: [1: "1", 8: "8", 15: "15", 22: "22", 29: "29"],
                points: points([48, 53, 50, 57, 55, 62, 59, 64], startingAt: 1, step: 4)
            )
        case "3M":
            return GraphSeries(
                xDomain: 0...2,
                xLabels: [0: "Nov", 1: "Dec", 2: "Jan"],
                points: points([42, 45, 44, 50, 53, 49, 56, 60, 63], startingAt: 0, step: 0.25)
            )
        case "1Y":
            return GraphSeries(
                xDomain: 0...11,
                xLabels: [0: "Feb", 3: "May", 6: "Aug", 9: "Nov"],
                points: points([38, 42, 40, 47, 52, 49, 55, 58, 54, 61, 64, 68], startingAt: 0, step: 1)
            )
        default:
            return GraphSeries(
                xDomain: 0...24,
                xLabels: [0: "12AM", 6: "6AM", 12: "12PM", 18: "6PM"],
                points: points([46, 44, 49, 58, 62, 57, 63, 60], startingAt: 1, step: 3)
            )
        }
    }

    private static func points(_ values: [Double], startingAt start: Double, step: Double) -> [BrightGraphPoint] {
        values.enumerated().map { BrightGraphPoint(x: start + Double($0.offset) * step, value: $0.element) }
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10, Double(places))
        return (self * factor).rounded() / factor
    }
}

/// One day's cohort percentile, driving the VaultOverviewWidget line chart.
struct VaultWeekPoint: Identifiable {
    var id: String { day }
    let day: String
    let value: Double

    static let week: [VaultWeekPoint] = [
        .init(day: "Mon", value: 52),
        .init(day: "Tue", value: 56),
        .init(day: "Wed", value: 54),
        .init(day: "Thu", value: 56),
        .init(day: "Fri", value: 68),
        .init(day: "Sat", value: 61),
        .init(day: "Sun", value: 58),
    ]
}
