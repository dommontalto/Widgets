//
//  VaultDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 4/11/2026.
//

import Foundation

enum VaultDemo {
    private struct Marker {
        let id: String
        let name: String
        let category: String
        let type: String
        let value: Double?
        let unit: String
        let low: Double
        let high: Double
        var daysAgo = 21
    }

    private static let markers: [Marker] = [
        Marker(id: "bc-hemoglobin", name: "Hemoglobin", category: "Blood Count", type: "clinical", value: 14.6, unit: "g/dL", low: 13, high: 17),
        Marker(id: "bc-wbc", name: "White Blood Cells", category: "Blood Count", type: "clinical", value: 6.1, unit: "10^9/L", low: 4, high: 11),
        Marker(id: "bc-platelets", name: "Platelets", category: "Blood Count", type: "clinical", value: 248, unit: "10^9/L", low: 150, high: 400),
        Marker(id: "bc-ferritin", name: "Ferritin", category: "Blood Count", type: "clinical", value: 38, unit: "ug/L", low: 30, high: 400),
        Marker(id: "lp-ldl", name: "LDL Cholesterol", category: "Lipids", type: "clinical", value: 3.6, unit: "mmol/L", low: 0, high: 3.4),
        Marker(id: "lp-hdl", name: "HDL Cholesterol", category: "Lipids", type: "clinical", value: 1.4, unit: "mmol/L", low: 1, high: 2.2),
        Marker(id: "lp-triglycerides", name: "Triglycerides", category: "Lipids", type: "clinical", value: 1.1, unit: "mmol/L", low: 0, high: 2),
        Marker(id: "mt-glucose", name: "Fasting Glucose", category: "Metabolic", type: "clinical", value: 5.2, unit: "mmol/L", low: 3.6, high: 6),
        Marker(id: "mt-hba1c", name: "HbA1c", category: "Metabolic", type: "clinical", value: 5.4, unit: "%", low: 4, high: 6),
        Marker(id: "th-tsh", name: "TSH", category: "Thyroid Health", type: "clinical", value: 2.1, unit: "mIU/L", low: 0.4, high: 4),
        Marker(id: "vt-vitamin-d", name: "Vitamin D", category: "Vitamins", type: "clinical", value: 52, unit: "nmol/L", low: 50, high: 150),
        Marker(id: "vt-b12", name: "Vitamin B12", category: "Vitamins", type: "clinical", value: 410, unit: "pmol/L", low: 150, high: 700),
        Marker(id: "ho-testosterone", name: "Testosterone", category: "Hormones", type: "clinical", value: 18.4, unit: "nmol/L", low: 8, high: 29),
        Marker(id: "ho-cortisol", name: "Cortisol", category: "Hormones", type: "clinical", value: 610, unit: "nmol/L", low: 140, high: 690),
        Marker(id: "in-crp", name: "C-Reactive Protein", category: "Inflammation", type: "clinical", value: 0.8, unit: "mg/L", low: 0, high: 5),
        Marker(id: "lv-alt", name: "ALT", category: "Liver", type: "clinical", value: 24, unit: "U/L", low: 5, high: 40),
        Marker(id: "kd-creatinine", name: "Creatinine", category: "Kidney", type: "clinical", value: 88, unit: "umol/L", low: 60, high: 110),
        Marker(id: "ls-resting-hr", name: "Resting Heart Rate", category: "Heart", type: "lifestyle", value: 54, unit: "bpm", low: 40, high: 80, daysAgo: 0),
        Marker(id: "ls-hrv", name: "Heart Rate Variability", category: "Heart", type: "lifestyle", value: 68, unit: "ms", low: 30, high: 100, daysAgo: 0),
        Marker(id: "ls-vo2max", name: "VO2 Max", category: "Fitness", type: "lifestyle", value: 48.2, unit: "mL/kg/min", low: 35, high: 60, daysAgo: 2),
        Marker(id: "ls-sleep", name: "Sleep Duration", category: "Sleep", type: "lifestyle", value: 7.1, unit: "hrs", low: 7, high: 9, daysAgo: 0),
        Marker(id: "ls-steps", name: "Steps", category: "Activity", type: "lifestyle", value: 9840, unit: "steps", low: 7000, high: 15000, daysAgo: 0),
        Marker(id: "ls-weight", name: "Weight", category: "Body", type: "lifestyle", value: 78.4, unit: "kg", low: 65, high: 85, daysAgo: 1),
        Marker(id: "ls-body-fat", name: "Body Fat", category: "Body", type: "lifestyle", value: 16.2, unit: "%", low: 10, high: 20, daysAgo: 1),
        Marker(id: "ls-spo2", name: "Blood Oxygen", category: "Respiratory", type: "lifestyle", value: 97, unit: "%", low: 95, high: 100, daysAgo: 0),
        Marker(id: "ls-respiratory-rate", name: "Respiratory Rate", category: "Respiratory", type: "lifestyle", value: 14.5, unit: "br/min", low: 12, high: 20, daysAgo: 0),
        Marker(id: "gn-apoe", name: "APOE", category: "Genetics", type: "genetic", value: nil, unit: "", low: 0, high: 1, daysAgo: 120),
        Marker(id: "gn-mthfr", name: "MTHFR", category: "Genetics", type: "genetic", value: nil, unit: "", low: 0, high: 1, daysAgo: 120),
    ]

    private static let summaryIds = ["ls-hrv", "lp-ldl", "vt-vitamin-d", "ls-resting-hr"]

    // Markers the user hasn't recorded yet; they fill out the datapoints grid as unlit dots.
    private static let missing: [(name: String, category: String, type: String)] = {
        let clinical = ["Iron", "Transferrin", "Magnesium", "Zinc", "Folate", "Insulin", "ApoB", "Lp(a)", "Homocysteine", "Uric Acid",
                        "Free T4", "Free T3", "Oestradiol", "SHBG", "DHEA-S", "Prolactin", "AST", "GGT", "Albumin", "eGFR",
                        "Sodium", "Potassium", "Calcium", "Phosphate", "Omega-3 Index", "Vitamin A", "Vitamin E", "Copper", "Selenium", "Cystatin C"]
        let lifestyle = ["Wrist Temperature", "Walking Speed", "Stand Hours", "Mindful Minutes", "Water Intake", "Caffeine", "Alcohol",
                         "Protein Intake", "Fibre Intake", "Cardio Load", "Strength Volume", "Deep Sleep", "REM Sleep", "Sleep Latency"]
        let genetic = ["ACTN3", "FTO", "CYP1A2", "PER3", "COMT", "BDNF", "VDR", "TCF7L2"]
        return clinical.map { ($0, "Clinical", "clinical") }
            + lifestyle.map { ($0, "Lifestyle", "lifestyle") }
            + genetic.map { ($0, "Genetics", "genetic") }
    }()

    static let ranking = VaultRankingData.demo

    static var summaryMarkers: [VaultMarkerData] {
        summaryIds.compactMap { id in markers.first { $0.id == id } }.map(markerData)
    }

    static var dataMarkers: [VaultMarkerData] {
        markers.map(markerData)
    }

    static var completeness: VaultCompletenessData {
        let recorded = markers.map { marker in
            VaultCompletenessDatapoint(
                name: marker.name,
                category: marker.category,
                bucket: marker.type,
                complete: true,
                unit: marker.unit,
                lastUpdated: dayKey(daysAgo: marker.daysAgo),
                id: marker.id,
                value: valueText(marker),
                markerPosition: marker.value.map { position(value: $0, low: marker.low, high: marker.high) }
            )
        }
        let unrecorded = missing.map { item in
            VaultCompletenessDatapoint(
                name: item.name,
                category: item.category,
                bucket: item.type,
                complete: false,
                unit: nil,
                lastUpdated: nil
            )
        }
        let all = recorded + unrecorded
        func count(_ type: String, complete: Bool? = nil) -> Int {
            all.filter { $0.bucket == type && (complete == nil || $0.complete == complete) }.count
        }
        return VaultCompletenessData(
            lifestyleCompleteCount: count("lifestyle", complete: true),
            lifestyleTotalCount: count("lifestyle"),
            clinicalCompleteCount: count("clinical", complete: true),
            clinicalTotalCount: count("clinical"),
            geneticCompleteCount: count("genetic", complete: true),
            geneticTotalCount: count("genetic"),
            completeCount: recorded.count,
            totalCount: all.count,
            resolutionPct: Double(recorded.count) / Double(all.count) * 100,
            byCategory: nil,
            datapoints: all
        )
    }

    static let impactCards: [CycleTrackingImpactType: CycleTrackingImpactData] = [
        .summary: CycleTrackingImpactData(
            items: [
                CycleTrackingImpactItem(text: "Recovery markers above your cohort", isPositive: true, status: .onTrack),
                CycleTrackingImpactItem(text: "LDL slightly above range", isPositive: false, status: .watch),
                CycleTrackingImpactItem(text: "Vitamin D at the low end", isPositive: false, status: .watch),
            ],
            description: "Your heart and recovery data are strong. Two blood markers are worth keeping an eye on.",
            title: "Your health at a glance"
        ),
        .why: CycleTrackingImpactData(
            items: [
                CycleTrackingImpactItem(text: "HRV trending up over 4 weeks", isPositive: true, status: .onTrack),
                CycleTrackingImpactItem(text: "Resting heart rate steady at 54 bpm", isPositive: true, status: .onTrack),
            ],
            description: "Consistent training and sleep are lifting your recovery.",
            title: "Why you rank where you do"
        ),
        .what: CycleTrackingImpactData(
            items: [
                CycleTrackingImpactItem(text: "LDL is 3.6 mmol/L, above 3.4", isPositive: false, status: .attention),
                CycleTrackingImpactItem(text: "Ferritin close to the lower limit", isPositive: false, status: .watch),
            ],
            description: "A couple of clinical markers sit near the edge of their ranges.",
            title: "What stands out"
        ),
        .how: CycleTrackingImpactData(
            items: [
                CycleTrackingImpactItem(text: "Add more fibre and oily fish", isPositive: true, status: .onTrack),
                CycleTrackingImpactItem(text: "Retest bloods in 3 months", isPositive: true, status: .onTrack),
                CycleTrackingImpactItem(text: "Get 15 minutes of morning sun", isPositive: true, status: .onTrack),
            ],
            description: "Small changes that move your weaker markers back into range.",
            title: "How to improve"
        ),
    ]

    static func history(for markerId: String) -> VaultMarkerHistoryData? {
        guard let marker = markers.first(where: { $0.id == markerId }), let latest = marker.value else { return nil }
        let span = marker.high - marker.low
        let offsets: [(days: Int, change: Double)] = marker.type == "lifestyle"
            ? [(0, 0), (2, -0.04), (5, 0.03), (12, -0.06), (24, 0.05), (60, -0.08), (150, 0.1), (300, -0.12)]
            : [(marker.daysAgo, 0), (marker.daysAgo + 120, -0.12), (marker.daysAgo + 300, 0.08), (marker.daysAgo + 700, -0.2)]
        let readings = offsets.map { offset in
            let value = ((latest + span * offset.change) * 10).rounded() / 10
            let markerPosition = position(value: value, low: marker.low, high: marker.high)
            return VaultMarkerHistoryReading(
                date: dayKey(daysAgo: offset.days),
                lastUpdated: dayKey(daysAgo: offset.days),
                value: value,
                unit: marker.unit,
                status: statusLabel(markerPosition),
                markerPosition: markerPosition,
                normalLow: marker.low,
                normalHigh: marker.high,
                reportId: "demo-\(offset.days)"
            )
        }
        let values = readings.compactMap(\.value)
        return VaultMarkerHistoryData(
            markerId: marker.id,
            name: marker.name,
            category: marker.category,
            unit: marker.unit,
            normalLow: marker.low,
            normalHigh: marker.high,
            average: values.reduce(0, +) / Double(values.count),
            rangeMin: values.min(),
            rangeMax: values.max(),
            readings: readings
        )
    }

    private static func markerData(_ marker: Marker) -> VaultMarkerData {
        let markerPosition = marker.value.map { position(value: $0, low: marker.low, high: marker.high) }
        return VaultMarkerData(
            id: marker.id,
            name: marker.name,
            category: marker.category,
            type: marker.type,
            status: markerPosition.map(statusLabel) ?? "",
            value: valueText(marker),
            lastUpdated: dayKey(daysAgo: marker.daysAgo),
            unit: marker.unit,
            trend: marker.value.map { [$0] } ?? [],
            normalRange: marker.value == nil ? nil : marker.low ... marker.high
        )
    }

    private static func valueText(_ marker: Marker) -> String {
        guard let value = marker.value else { return marker.type == "genetic" ? "Typical" : "" }
        return value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }

    private static func position(value: Double, low: Double, high: Double) -> Double {
        VaultViewModel.markerPosition(value: String(value), range: low ... high)
    }

    private static func statusLabel(_ position: Double) -> String {
        VaultRangeMarkerData(id: "", title: "", lastUpdated: "", value: "", unit: "", markerPosition: position).statusLabel
    }

    private static func dayKey(daysAgo: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        return date.brightDayKey
    }
}
