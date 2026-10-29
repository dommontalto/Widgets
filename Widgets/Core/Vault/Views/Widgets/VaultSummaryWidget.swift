//
//  VaultSummaryWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 14/10/2026.
//

import SwiftUI

struct VaultSummaryWidget: View {
    var ranking: VaultRankingData?
    var fallbackTopPercent: Double?

    @State private var gender = "men"
    @State private var ageRange = "18-24"
    @State private var topPct: Double?
    @State private var delta7d: Double = 0

    private var fraction: Double? {
        (topPct ?? ranking?.topPct ?? fallbackTopPercent).map { 1 - $0 / 100 }
    }

    var body: some View {
        BrightWaveWidgetV5(
            title: "Global Health Ranking",
            fraction: fraction,
            delta: delta7d,
            emptySubtitle: "Your ranking appears once your data syncs"
        ) {
            BrightCohortRowV5(gender: $gender, ageRange: $ageRange)
        }
        .onChange(of: ranking?.topPct, initial: true) { _, _ in
            seedFromRanking()
        }
        .onChange(of: gender) { _, _ in refetch() }
        .onChange(of: ageRange) { _, _ in refetch() }
    }

    private func seedFromRanking() {
        guard let ranking else { return }
        topPct = ranking.topPct
        delta7d = ranking.delta7d ?? 0
        for axis in ranking.cohortAxes ?? [] {
            switch axis.axis?.lowercased() {
            case "sex":
                if let value = axis.value?.lowercased() {
                    gender = value == "female" ? "women" : "men"
                }
            case "age":
                if let value = axis.value, !value.isEmpty {
                    ageRange = value
                }
            default:
                break
            }
        }
    }

    private func refetch() {
        let sex = gender == "women" ? "female" : "male"
        let cohort = "sex:\(sex),age:\(ageRange)"
        let result = VaultRankingData.demo(cohort: cohort)
        withAnimation(.brightBouncy) {
            topPct = result.topPct ?? topPct
            delta7d = result.delta7d ?? delta7d
        }
    }
}

#Preview {
    VaultSummaryWidget(ranking: .demo)
        .padding(.spacing3x)
        .background(Color.defaultBackground)
}
