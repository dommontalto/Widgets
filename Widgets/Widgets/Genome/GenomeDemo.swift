//
//  GenomeDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

// MARK: - GenomePercentileGraphWidget

struct GenomeRiskPoint: Identifiable {
    var id: Double { age }
    let age: Double
    let reference: Double
    let higherRisk: Double
    let userRisk: Double

    static let data: [GenomeRiskPoint] = stride(from: 0.0, through: 80.0, by: 2.0).map { age in
        let t = max(0, (age - 38.0) / 42.0)
        let ref  = min(100, 15.0 * pow(t, 2.3))
        let high = min(100, 30.0 * pow(t, 1.6))
        let user = ref + (high - ref) * 0.72
        return GenomeRiskPoint(age: age, reference: ref, higherRisk: high, userRisk: user)
    }
}

// MARK: - GenomePercentileBarWidget

struct GenomePercentileBarDemoData {
    static let percentile = 72
    static let description = "Genetic load skews toward elevated LDL response. PCSK9 variant provides partial protection. Monitor ApoB and consider a Mediterranean lipid profile."
}

// MARK: - GenomeImpactContributorWidget

struct GenomeCategory: Identifiable {
    let id = UUID()
    let title: String
    let markerCount: Int
    let imageName: String

    static let all: [GenomeCategory] = [
        GenomeCategory(title: "Recovery & Exercise", markerCount: 23, imageName: ImageNames.genomeRecoveryExerciseV5),
        GenomeCategory(title: "Nutrition",           markerCount: 41, imageName: ImageNames.genomeNutritionMetabolismV5),
        GenomeCategory(title: "Sleep & Circadian",   markerCount: 18, imageName: ImageNames.genomeSleepCircadianV5),
        GenomeCategory(title: "Cardiovascular",      markerCount: 31, imageName: ImageNames.genomeCardiovascularV5),
        GenomeCategory(title: "Cognitive & Mental",  markerCount: 27, imageName: ImageNames.genomeCognitiveMentalV5),
        GenomeCategory(title: "Inflammation",        markerCount: 34, imageName: ImageNames.genomeInflammationImmunityV5),
        GenomeCategory(title: "Longevity",           markerCount: 12, imageName: ImageNames.genomeLongevityV5),
        GenomeCategory(title: "Medication",          markerCount: 19, imageName: ImageNames.genomeMedicationResponseV5),
        GenomeCategory(title: "Hormones",            markerCount: 18, imageName: ImageNames.genomeHormonesV5),
        GenomeCategory(title: "Skin & Ageing",       markerCount: 31, imageName: ImageNames.genomeSkinAgeingV5),
        GenomeCategory(title: "Fertility",           markerCount: 18, imageName: ImageNames.genomeFertilityV5),
        GenomeCategory(title: "Injury Risk",         markerCount: 31, imageName: ImageNames.genomeInjuryRiskV5),
    ]
}

// MARK: - GenomeOrderStatusWidget

struct GenomeOrderStatusDemoData {
    static let status = "Order placed"
    static let eta = "ETA: 6 weeks"
    static let totalSteps = 4
    static let completedSteps = 1
}

// MARK: - GenomeContributorWidget

struct GenomeContributor: Identifiable {
    let id = UUID()
    let imageName: String
    let gene: String
    let subtitle: String
    let score: Double

    var scoreText: String {
        score >= 0 ? "+\(String(format: "%.2f", score))" : "\(String(format: "%.2f", score))"
    }
    var scoreColor: Color {
        if score >= 0 { return Color.defaultSkyBlue }
        if score > -0.5 { return Color.defaultBrightGreen }
        return Color.defaultBrightViolet
    }

    static let data: [GenomeContributor] = [
        GenomeContributor(imageName: ImageNames.genomeLungsV5,     gene: "APOE ε3/ε3",      subtitle: "Lipid metabolism", score:  0.21),
        GenomeContributor(imageName: ImageNames.genomeHourglassV5, gene: "LDLR rs6511720",   subtitle: "LDL receptor",     score:  0.14),
        GenomeContributor(imageName: ImageNames.genomeSunriseV5,   gene: "PCSK9 rs11591147", subtitle: "LDL clearance",    score: -0.08),
        GenomeContributor(imageName: ImageNames.genomeBrainV5,     gene: "9p21.3",           subtitle: "Coronary artery",  score: -0.87),
    ]
}
