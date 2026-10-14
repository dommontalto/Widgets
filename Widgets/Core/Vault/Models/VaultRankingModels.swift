//
//  VaultRankingModels.swift
//  Widgets
//
//  Created by Dom Montalto on 14/10/2026.
//

import Foundation

struct VaultRankingData {
    let topPct: Double?
    let delta7d: Double?
    let cohortAxes: [VaultRankingCohortAxis]?
    let histogramBinIndex: Int?
    let summaryText: String?
}

struct VaultRankingCohortAxis {
    let axis: String?
    let value: String?
}
