//
//  GenomeModels.swift
//  Widgets
//

import SwiftUI

// MARK: - Shared

enum GenomeAsset {
    static func imageName(for iconKey: String) -> String {
        "Genome/Icons/\(iconKey)"
    }

    static func color(for iconKey: String) -> Color {
        palette.first(where: { $0.iconKeys.contains(iconKey) })?.color ?? .defaultCyan
    }

    static func rainbowRank(for iconKey: String) -> Int {
        palette.firstIndex(where: { $0.iconKeys.contains(iconKey) }) ?? palette.count
    }

    private static let palette: [(color: Color, iconKeys: [String])] = [
        (.defaultRed, ["genome_inflammation_immunity_v5"]),
        (.defaultOrange, ["genome_hourglass_v5", "genome_nutrition_metabolism_v5", "genome_skin_ageing_v5"]),
        (.defaultYellow, ["genome_medication_response_v5", "genome_injury_risk_v5"]),
        (.defaultGreen, ["genome_longevity_v5", "genome_recovery_exercise_v5"]),
        (.defaultCyan, ["genome_lungs_v5", "genome_cardiovascular_v5"]),
        (.defaultSkyBlue, ["genome_sunrise_v5", "genome_clock_v5", "genome_sleep_circadian_v5", "genome_hormones_v5"]),
        (.defaultBrightViolet, ["genome_brain_v5", "genome_cognitive_mental_v5"]),
        (.defaultBrightPink, ["genome_dna_v5"]),
    ]
}

// MARK: - Summary

struct GenomeSummaryData: Codable {
    let genomeStatus: String
    let interpretationVersion: String?
    let order: GenomeOrderInfo?
    let riskPercentile: GenomeRiskPercentile?
    let leadingContributors: [GenomeContributor]
    // GEN-DEMO: sample results from the demo genome, shown with demoLabel
    var demo: Bool? = nil
    var demoLabel: String? = nil
}

struct GenomeRiskPercentile: Codable {
    let value: Int
    let description: String?
    let curve: [GenomeRiskCurvePoint]

    var displayDescription: String? {
        guard let description, !description.isEmpty else { return nil }
        return description
    }
}

struct GenomeRiskCurvePoint: Codable, Identifiable {
    let age: Int
    let reference: Double
    let higherRisk: Double
    let userRisk: Double

    var id: Int { age }
}

// MARK: - Categories (Impact grid)

struct GenomeCategoriesData: Codable {
    let genomeStatus: String
    let interpretationVersion: String?
    let categories: [GenomeCategory]
    // GEN-DEMO: sample results from the demo genome, shown with demoLabel
    var demo: Bool? = nil
    var demoLabel: String? = nil
}

enum GenomeCategoryState: String {
    case built
    case partial
    case pending
    case unavailable
}

struct GenomeCategory: Codable, Identifiable {
    let id: String
    let title: String
    let iconKey: String
    let markerCount: Int
    let state: String

    var categoryState: GenomeCategoryState {
        GenomeCategoryState(rawValue: state) ?? .pending
    }

    var imageName: String {
        GenomeAsset.imageName(for: iconKey)
    }

    var isInteractive: Bool {
        switch categoryState {
        case .built, .partial: true
        case .pending, .unavailable: false
        }
    }
}

extension GenomeCategory {
    static let placeholders: [GenomeCategory] = [
        ("nutrition", "Nutrition", "genome_nutrition_metabolism_v5"),
        ("sleep_circadian", "Sleep & Circadian", "genome_sleep_circadian_v5"),
        ("recovery_exercise", "Recovery & Exercise", "genome_recovery_exercise_v5"),
        ("cardiovascular", "Cardiovascular", "genome_cardiovascular_v5"),
        ("cognitive_mental", "Cognitive & Mental", "genome_cognitive_mental_v5"),
        ("inflammation", "Inflammation", "genome_inflammation_immunity_v5"),
        ("longevity", "Longevity", "genome_longevity_v5"),
        ("medication", "Medication", "genome_medication_response_v5"),
        ("hormones", "Hormones", "genome_hormones_v5"),
        ("skin_ageing", "Skin & Ageing", "genome_skin_ageing_v5"),
        ("body_traits", "Body Traits", "genome_dna_v5"),
        ("methylation", "Methylation", "genome_hourglass_v5"),
        ("injury_risk", "Injury Risk", "genome_injury_risk_v5"),
    ].map { GenomeCategory(id: $0, title: $1, iconKey: $2, markerCount: 0, state: GenomeCategoryState.unavailable.rawValue) }
}

// MARK: - Category Detail

struct GenomeCategoryDetail: Codable, Identifiable {
    let id: String
    let title: String
    let iconKey: String
    let state: String
    let percentileBar: GenomePercentileBar?
    let markers: [GenomeCategoryMarker]
    // GEN-DEMO: sample results from the demo genome, shown with demoLabel
    var demo: Bool? = nil
    var demoLabel: String? = nil

    var imageName: String {
        GenomeAsset.imageName(for: iconKey)
    }
}

struct GenomeCategoryMarker: Codable, Identifiable, Hashable {
    let canonicalName: String
    let gene: String
    let subtitle: String
    let rawValue: String
    let unit: String
    let evidenceLevel: String?
    let iconKey: String
    let reportId: String
    let panelId: String
    let score: Double?
    let isFeatured: Bool

    var id: String { canonicalName }

    var imageName: String {
        GenomeAsset.imageName(for: iconKey)
    }

    var scoreText: String? {
        guard let score else { return nil }
        return score >= 0 ? "+\(String(format: "%.2f", score))" : String(format: "%.2f", score)
    }

    var scoreColor: Color {
        guard let score else { return .lightTextColor }
        if score >= 0 { return .defaultSkyBlue }
        if score > -0.5 { return .defaultGreen }
        return .defaultBrightViolet
    }
}

struct GenomePercentileBar: Codable {
    let value: Int
    let description: String?

    var displayDescription: String? {
        guard let description, !description.isEmpty else { return nil }
        return description
    }
}

// MARK: - Contributor (Summary + Category Detail)

struct GenomeContributor: Codable, Identifiable, Hashable {
    let canonicalName: String
    let gene: String
    let subtitle: String
    let score: Double?
    let iconKey: String
    let reportId: String
    let categoryId: String?

    var id: String { canonicalName }

    var imageName: String {
        GenomeAsset.imageName(for: iconKey)
    }

    var iconColor: Color {
        GenomeAsset.color(for: iconKey)
    }

    /// Nil when the server leaves the placeholder score out (GEN-AUDIT P0-1).
    var scoreText: String? {
        guard let score else { return nil }
        return score >= 0 ? "+\(String(format: "%.2f", score))" : String(format: "%.2f", score)
    }

    var scoreColor: Color {
        guard let score else { return .lightTextColor }
        if score >= 0 { return Color.defaultSkyBlue }
        if score > -0.5 { return Color.defaultGreen }
        return Color.defaultBrightViolet
    }
}

// MARK: - Data (Strand)

struct GenomeData: Codable {
    let genomeStatus: String
    let interpretationVersion: String?
    let markers: [GenomeDataMarker]
    // GEN-DEMO: sample results from the demo genome, shown with demoLabel
    var demo: Bool? = nil
    var demoLabel: String? = nil
}

struct GenomeDataMarker: Codable, Identifiable, Equatable {
    let canonicalName: String
    let gene: String
    let rsid: String?
    let alleles: [String]?
    let categoryId: String
    let panelId: String
    let reportId: String
    let rawValue: String
    let unit: String
    let resultLabel: String?
    let evidenceLevel: String?
    let evidenceBasis: String?
    let validatedPopulations: [String]?
    let meaning: String?
    let citations: [GenomeCitation]?
    let sequenceContext: GenomeSequenceContext?
    let isFeatured: Bool
    let score: Double?
    let iconKey: String

    var id: String { canonicalName }

    var color: Color {
        GenomeAsset.color(for: iconKey)
    }

    // The two allele letters for a strand rung, when this is a genotype variant.
    var basePair: (base: String, pair: String)? {
        guard unit == "genotype", rawValue.count == 2 else { return nil }
        let letters = Array(rawValue)
        return (String(letters[0]), String(letters[1]))
    }
}

struct GenomeCitation: Codable, Equatable {
    let source: String?
    let url: String?
    let accessedAt: String?
}

struct GenomeSequenceContext: Codable, Equatable {
    let available: Bool
    let type: String?
    let source: String?
    let referenceGenome: String?
    let chromosome: String?
    let position: Int?
    let windowBp: Int?
    let leftFlank: String?
    let observedVariant: String?
    let rightFlank: String?
    let displaySequence: String?
    let personalizedFlanks: Bool?
    let reason: String?
}

enum GenomeEvidenceLevel: String {
    case high
    case moderate
    case low
    case exploratory

    init(_ raw: String?) {
        self = GenomeEvidenceLevel(rawValue: raw ?? "") ?? .exploratory
    }

    // The evidence behind a result, never a verdict on it ("Sub-Optimal" read as one)
    var label: String {
        self == .exploratory ? "Exploratory" : "\(rawValue.capitalized) evidence"
    }

    var color: Color {
        switch self {
        case .high: Color.defaultGreen
        case .moderate: Color.defaultYellow
        case .low: Color.defaultCyan
        case .exploratory: Color.lightTextColor
        }
    }
}
