//
//  VaultDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import Foundation

enum VaultDemoData {
    static func randomGrid(rows: Int, columns: Int) -> [[Bool]] {
        (0..<rows).map { _ in (0..<columns).map { _ in Bool.random() } }
    }

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

    private static let latestTimestamps = [
        "10/5/2026, 2:34 PM",
        "28/4/2026, 9:12 AM",
        "3/6/2026, 5:47 PM",
        "16/3/2026, 11:03 AM",
        "21/6/2026, 7:26 PM",
    ]

    static func latestRecorded(_ metric: Metric) -> String {
        latestTimestamps[metric.title.count % latestTimestamps.count]
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
