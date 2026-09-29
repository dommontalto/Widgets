//
//  GenomeDemo.swift
//  Widgets
//

import Foundation

enum GenomeDemoScenario: String, CaseIterable, Identifiable {
    case notOrdered
    case orderPlaced
    case shipping
    case delivered
    case processing
    case full
    case orderFailed
    case cancelled

    static var current: GenomeDemoScenario = .notOrdered

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notOrdered: "Not ordered"
        case .orderPlaced: "Order placed"
        case .shipping: "Kit shipping"
        case .delivered: "Kit delivered"
        case .processing: "Processing sample"
        case .full: "Results ready (full)"
        case .orderFailed: "Order failed"
        case .cancelled: "Order cancelled"
        }
    }
}

extension GenomeDemoScenario {
    var status: GenomeOrderStatus {
        switch self {
        case .notOrdered: .none
        case .orderPlaced: .ordered
        case .shipping: .shipping
        case .delivered: .delivered
        case .processing: .processing
        case .full: .ready
        case .orderFailed: .failed
        case .cancelled: .cancelled
        }
    }

    var summary: GenomeSummaryData {
        let hasResults = self == .full
        return GenomeSummaryData(
            genomeStatus: status.rawValue,
            interpretationVersion: "2026.05.1",
            order: order,
            riskPercentile: hasResults ? GenomeDemo.sampleRiskPercentile : nil,
            leadingContributors: hasResults ? GenomeDemo.sampleContributors : []
        )
    }

    var categories: [GenomeCategory] {
        self == .full ? GenomeDemo.sampleCategories : []
    }

    var dataMarkers: [GenomeDataMarker] {
        self == .full ? GenomeDemo.sampleDataMarkers : []
    }

    private var order: GenomeOrderInfo? {
        switch status {
        case .none, .ready, .failed, .cancelled: nil
        default:
            GenomeOrderInfo(
                widgetState: status.rawValue,
                statusLabel: status.displayTitle,
                eta: "6 weeks",
                completedSteps: status.completedSteps,
                totalSteps: 4
            )
        }
    }
}

enum GenomeDemo {
    static let checkoutItem = BrightCheckoutItem(
        title: "30x Whole Genome Sequencing",
        detail: "Whole genome sequencing kit, posted to you. Your results appear in Bright once your sample is sequenced.",
        priceText: "$499.00",
        currency: "AUD",
        fulfilment: .delivered
    )

    static func categoryDetail(id: String) -> GenomeCategoryDetail {
        let category = sampleCategories.first { $0.id == id }
        let bar = id == "hormones" ? nil : GenomePercentileBar(
            value: 70,
            description: "Your genetics suggest you are likely a 'taster' for bitter flavors."
        )
        return GenomeCategoryDetail(
            id: id,
            title: category?.title ?? id.capitalized,
            iconKey: category?.iconKey ?? "genome_dna_v5",
            state: "built",
            percentileBar: bar,
            markers: sampleCategoryMarkers
        )
    }

    static var sampleRiskPercentile: GenomeRiskPercentile {
        GenomeRiskPercentile(
            value: 64,
            description: "Your genetics suggest a slight tendency toward being a morning person.",
            curve: stride(from: 20, through: 70, by: 5).map { age in
                let t = max(0, Double(age - 30) / 40)
                let ref = 0.15 * t * t
                return GenomeRiskCurvePoint(age: age, reference: ref, higherRisk: ref * 2, userRisk: ref * 1.64)
            }
        )
    }

    static var sampleContributors: [GenomeContributor] {
        [
            .init(canonicalName: "gc.rs4988235", gene: "MCM6 rs4988235", subtitle: "Lactose tolerance", score: 0.12, iconKey: "genome_nutrition_metabolism_v5", reportId: "r1", categoryId: "nutrition"),
            .init(canonicalName: "gc.rs5751876", gene: "ADORA2A rs5751876", subtitle: "Caffeine-sleep sensitivity", score: -0.22, iconKey: "genome_clock_v5", reportId: "r2", categoryId: "sleep_circadian"),
            .init(canonicalName: "gc.rs1815739", gene: "ACTN3 rs1815739", subtitle: "Muscle fiber type", score: 0.28, iconKey: "genome_lungs_v5", reportId: "r3", categoryId: "recovery_exercise"),
            .init(canonicalName: "gc.rs1800795", gene: "IL6 rs1800795", subtitle: "Inflammation risk", score: -0.17, iconKey: "genome_inflammation_immunity_v5", reportId: "r4", categoryId: "cardiovascular"),
        ]
    }

    static var sampleCategories: [GenomeCategory] {
        [
            .init(id: "nutrition", title: "Nutrition", iconKey: "genome_nutrition_metabolism_v5", markerCount: 15, state: "built"),
            .init(id: "sleep_circadian", title: "Sleep & Circadian", iconKey: "genome_sleep_circadian_v5", markerCount: 3, state: "built"),
            .init(id: "recovery_exercise", title: "Recovery & Exercise", iconKey: "genome_recovery_exercise_v5", markerCount: 8, state: "built"),
            .init(id: "cardiovascular", title: "Cardiovascular", iconKey: "genome_cardiovascular_v5", markerCount: 4, state: "built"),
            .init(id: "cognitive_mental", title: "Cognitive & Mental", iconKey: "genome_cognitive_mental_v5", markerCount: 3, state: "built"),
            .init(id: "inflammation", title: "Inflammation", iconKey: "genome_inflammation_immunity_v5", markerCount: 6, state: "built"),
            .init(id: "longevity", title: "Longevity", iconKey: "genome_longevity_v5", markerCount: 3, state: "built"),
            .init(id: "medication", title: "Medication", iconKey: "genome_medication_response_v5", markerCount: 5, state: "built"),
            .init(id: "hormones", title: "Hormones", iconKey: "genome_hormones_v5", markerCount: 3, state: "built"),
            .init(id: "skin_ageing", title: "Skin & Ageing", iconKey: "genome_skin_ageing_v5", markerCount: 4, state: "built"),
            .init(id: "body_traits", title: "Body Traits", iconKey: "genome_dna_v5", markerCount: 3, state: "built"),
            .init(id: "methylation", title: "Methylation", iconKey: "genome_hourglass_v5", markerCount: 6, state: "built"),
            .init(id: "injury_risk", title: "Injury Risk", iconKey: "genome_injury_risk_v5", markerCount: 4, state: "built"),
        ]
    }

    static var sampleCategoryMarkers: [GenomeCategoryMarker] {
        [
            .init(canonicalName: "gc.rs4988235", gene: "MCM6 rs4988235", subtitle: "Lactose tolerance", rawValue: "GA", unit: "genotype", evidenceLevel: "high", iconKey: "genome_hourglass_v5", reportId: "r1", panelId: "nutrition_diet_response", score: 0.12, isFeatured: true),
            .init(canonicalName: "gc.rs762551", gene: "CYP1A2 rs762551", subtitle: "Caffeine metabolism", rawValue: "AC", unit: "genotype", evidenceLevel: "moderate", iconKey: "genome_sunrise_v5", reportId: "r1", panelId: "nutrition_diet_response", score: -0.08, isFeatured: true),
            .init(canonicalName: "gc.rs2282679", gene: "GC rs2282679", subtitle: "Fat-Soluble Vitamins", rawValue: "TG", unit: "genotype", evidenceLevel: "moderate", iconKey: "genome_nutrition_metabolism_v5", reportId: "r2", panelId: "micronutrients_and_vitamins", score: nil, isFeatured: false),
            .init(canonicalName: "gc.pgs.bitter_taste_sensitivity", gene: "Bitter taste sensitivity", subtitle: "Taste", rawValue: "", unit: "score", evidenceLevel: "high", iconKey: "genome_nutrition_metabolism_v5", reportId: "r3", panelId: "taste_and_smell", score: nil, isFeatured: false),
        ]
    }

    static var sampleDataMarkers: [GenomeDataMarker] {
        let specs: [(String, String, String, String, String, String, Double?)] = [
            ("gc.rs4680", "COMT rs4680", "methylation", "genome_hourglass_v5", "GA", "exploratory", 0.11),
            ("gc.rs6265", "BDNF rs6265", "cognitive_mental", "genome_brain_v5", "CT", "exploratory", 0.12),
            ("gc.pgx.cyp2c19", "CYP2C19", "medication", "genome_medication_response_v5", "*1/*17", "high", 0.34),
            ("gc.rs2282679", "GC rs2282679", "nutrition", "genome_nutrition_metabolism_v5", "TG", "moderate", nil),
            ("gc.rs1800795", "IL6 rs1800795", "recovery_exercise", "genome_inflammation_immunity_v5", "GC", "exploratory", -0.11),
            ("gc.rs6259", "SHBG rs6259", "hormones", "genome_hormones_v5", "GA", "moderate", 0.12),
            ("gc.rs1800012", "COL1A1 rs1800012", "skin_ageing", "genome_skin_ageing_v5", "GT", "low", 0.09),
            ("gc.rs2802292", "FOXO3 rs2802292", "longevity", "genome_longevity_v5", "GT", "moderate", 0.31),
            ("gc.rs6184", "GHR rs6184", "inflammation", "genome_inflammation_immunity_v5", "AC", "exploratory", nil),
            ("gc.rs17822931", "ABCC11 rs17822931", "body_traits", "genome_dna_v5", "GA", "high", 0.05),
        ]
        return specs.map { name, gene, category, icon, raw, level, score in
            GenomeDataMarker(
                canonicalName: name, gene: gene, rsid: String(name.dropFirst(3)),
                alleles: raw.count == 2 ? raw.map(String.init) : nil,
                categoryId: category, panelId: "\(category)_panel", reportId: "r",
                rawValue: raw, unit: raw.contains("*") ? "diplotype" : "genotype",
                resultLabel: "Result for \(gene)", evidenceLevel: level, evidenceBasis: "GWAS Catalog",
                validatedPopulations: ["broad"], meaning: "Demo meaning for \(gene).",
                citations: [], sequenceContext: nil, isFeatured: score != nil, score: score, iconKey: icon
            )
        }
    }
}
