//
//  VaultRankingDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 14/10/2026.
//

import Foundation

extension VaultRankingData {
    static let demo = VaultRankingData(
        topPct: 8,
        delta7d: 3,
        cohortAxes: [
            VaultRankingCohortAxis(axis: "sex", value: "male"),
            VaultRankingCohortAxis(axis: "age", value: "18-24"),
        ],
        histogramBinIndex: nil,
        summaryText: nil
    )

    static func demo(cohort: String) -> VaultRankingData {
        let seed = cohort.unicodeScalars.reduce(0) { ($0 * 31 + Int($1.value)) % 9973 }
        return VaultRankingData(
            topPct: Double(seed % 40 + 3),
            delta7d: Double(seed % 61) / 10 - 3,
            cohortAxes: nil,
            histogramBinIndex: nil,
            summaryText: nil
        )
    }
}
