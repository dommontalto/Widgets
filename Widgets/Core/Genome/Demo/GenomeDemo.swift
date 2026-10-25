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
            .init(canonicalName: "gc.rs4988235", gene: "MCM6 rs4988235", subtitle: "Lactose tolerance", rawValue: "GA", unit: "genotype", evidenceLevel: "moderate", iconKey: "genome_hourglass_v5", reportId: "r1", panelId: "nutrition_diet_response", score: 0.12, isFeatured: true),
            .init(canonicalName: "gc.rs762551", gene: "CYP1A2 rs762551", subtitle: "Caffeine metabolism", rawValue: "AC", unit: "genotype", evidenceLevel: "moderate", iconKey: "genome_sunrise_v5", reportId: "r1", panelId: "nutrition_diet_response", score: -0.08, isFeatured: true),
            .init(canonicalName: "gc.rs2282679", gene: "GC rs2282679", subtitle: "Fat-Soluble Vitamins", rawValue: "TG", unit: "genotype", evidenceLevel: "moderate", iconKey: "genome_nutrition_metabolism_v5", reportId: "r2", panelId: "micronutrients_and_vitamins", score: nil, isFeatured: false),
            .init(canonicalName: "gc.pgs.bitter_taste_sensitivity", gene: "Bitter taste sensitivity", subtitle: "Taste", rawValue: "", unit: "score", evidenceLevel: "moderate", iconKey: "genome_nutrition_metabolism_v5", reportId: "r3", panelId: "taste_and_smell", score: nil, isFeatured: false),
        ]
    }

    // Real Genome Computer wording (staging panels) so the strand panel is tested at real lengths.
    private static let sampleCopy: [String: (result: String, meaning: String)] = [
            "gc.rs17822931": ("One copy of G and one copy of A", "ABCC11 determines earwax type (wet vs dry) and is linked to underarm body-odor production. A clean single-gene trait; the dry/low-odor version is common in East Asian ancestry."),
            "gc.rs1815739": ("One copy of C and one copy of T", "The ACTN3 'R577X' variant affects a protein in fast-twitch muscle fibers; the functional version is overrepresented in power athletes and the X/X version leans endurance. The variant is real but predicts very little for any individual; training dominates."),
            "gc.rs6184": ("One copy of A and one copy of C", "GHR (growth-hormone receptor) variation is studied in growth-hormone signaling and response; evidence for individual prediction is limited. Pathway context only."),
            "gc.rs1800012": ("One copy of G and one copy of T", "A COL1A1 variant studied for collagen production and connective-tissue properties. Evidence is modest; background context for collagen-related traits, not a structural diagnosis."),
            "gc.rs12722": ("One copy of C and one copy of T", "COL5A1 rs12722 has been studied for tendon and ligament properties and soft-tissue injury tendency in athletes. Exploratory and population-dependent; not an injury prediction."),
            "gc.rs1800795": ("One copy of G and one copy of C", "This IL6 promoter variant is associated with differences in baseline inflammatory signaling. Evidence is mixed and effects small; exploratory inflammatory-tone context, not a measure of current inflammation."),
            "gc.rs2802292": ("One copy of G and one copy of T", "FOXO3 is one of the few genes besides APOE repeatedly associated with exceptional longevity, via stress-resistance pathways. The effect is real but small and population-level; it does not predict your lifespan."),
            "gc.rs6259": ("One copy of G and one copy of A", "rs6259 affects sex-hormone-binding globulin, influencing how much sex hormone circulates free versus bound. Inherited endocrine context; it does not measure your hormone levels."),
            "gc.rs4680": ("One copy of G and one copy of A", "The COMT 'Val/Met' variant affects how quickly dopamine is cleared in the prefrontal cortex, popularly framed 'warrior vs worrier' for stress and focus tendencies. Widely studied but with small, inconsistent effects; a tendency, not a determinant, and not a measure of intelligence or any condition."),
            "gc.rs2282679": ("One copy of T and one copy of G", "GC affects the protein that carries vitamin D in blood; this variant is associated with lower circulating vitamin D in studies. A tendency, not a measurement: confirm with labs before any change."),
            "gc.rs1801133": ("One copy of C and one copy of T", "The MTHFR C677T 'T' allele modestly lowers folate-processing enzyme activity and can slightly raise homocysteine, more so with two copies. Routine MTHFR testing is not clinically recommended, and this is not a basis for folate supplementation or methylation protocols: discuss any supplementation with a clinician."),
            "gc.pgx.cyp2c19": ("Rapid metabolizer (*1/*17)", "CYP2C19 metabolizer status affects how you process drugs like clopidogrel, some antidepressants, and PPIs. Rapid/ultrarapid status can lower drug levels; poor status can raise them and side-effect risk. PGx context for clinician review, not a dosing instruction."),
            "gc.rs6265": ("One copy of C and one copy of T", "The BDNF 'Val66Met' variant affects activity-dependent BDNF release, studied in learning, stress, and focus tendencies. Evidence is mixed and effect sizes small; exploratory trait context only, not a cognitive or mental-health assessment."),
            "gc.rs4988235": ("One copy of G and one copy of A", "The main lactase-persistence variant in European-ancestry populations; the persistence allele is associated with digesting dairy into adulthood. Separate persistence variants in African and Middle Eastern populations are not captured by this SNP, so a non-persistence call here does not rule out persistence in those ancestries."),
            "gc.rs762551": ("One copy of A and one copy of C", "Associated with CYP1A2 inducibility and caffeine-metabolism rate; the *1F allele links to higher inducible activity in some studies. Smoking and other inducers also strongly affect CYP1A2, so genotype is only part of the picture."),
            "gc.rs1801260": ("One copy of A and one copy of G", "A CLOCK variant linked to a slight lean toward later sleep timing."),
            "gc.rs429358": ("Two copies of T", "APOE rs429358 is one of the two variants that together define the APOE e2, e3 and e4 types. This result alone does not tell you your APOE type; that needs rs7412 as well. APOE is widely studied for lipid handling and for later-life brain health, and e4 carriers show a higher average risk in large population studies. A tendency in averages is not a diagnosis, many carriers never develop any condition, and lifestyle factors such as exercise, sleep, blood pressure and diet carry substantial weight. Talk to a clinician before acting on this result."),
            "gc.rs1799752": ("One insertion and one deletion", "An ACE insertion/deletion variant studied in endurance and power performance and in blood-pressure regulation. Effects are small and context-dependent."),
            "gc.rs53576": ("Two copies of G", "An OXTR variant studied for social sensitivity and stress response; findings are mixed."),
            "gc.rs1695": ("One copy of A and one copy of G", "GSTP1 helps clear oxidative by-products. This variant modestly changes enzyme activity in lab studies; real-world effects are small."),
    ]

    static var sampleDataMarkers: [GenomeDataMarker] {
        let specs: [(String, String, String, String, String, String, Double?)] = [
            ("gc.rs4680", "COMT", "methylation", "genome_hourglass_v5", "GA", "low", 0.11),
            ("gc.rs6265", "BDNF", "cognitive_mental", "genome_brain_v5", "CT", "low", 0.12),
            ("gc.pgx.cyp2c19", "CYP2C19", "medication", "genome_medication_response_v5", "*1/*17", "moderate", 0.34),
            ("gc.rs2282679", "GC", "nutrition", "genome_nutrition_metabolism_v5", "TG", "moderate", nil),
            ("gc.rs1800795", "IL6", "recovery_exercise", "genome_inflammation_immunity_v5", "GC", "low", -0.11),
            ("gc.rs6259", "SHBG", "hormones", "genome_hormones_v5", "GA", "moderate", 0.12),
            ("gc.rs1800012", "COL1A1", "skin_ageing", "genome_skin_ageing_v5", "GT", "low", 0.09),
            ("gc.rs2802292", "FOXO3", "longevity", "genome_longevity_v5", "GT", "moderate", 0.31),
            ("gc.rs6184", "GHR", "inflammation", "genome_inflammation_immunity_v5", "AC", "low", nil),
            ("gc.rs17822931", "ABCC11", "body_traits", "genome_dna_v5", "GA", "moderate", 0.05),
            ("gc.rs4988235", "MCM6", "nutrition", "genome_nutrition_metabolism_v5", "GA", "moderate", 0.12),
            ("gc.rs762551", "CYP1A2", "nutrition", "genome_sunrise_v5", "AC", "moderate", -0.08),
            ("gc.rs1801133", "MTHFR", "methylation", "genome_hourglass_v5", "CT", "moderate", -0.14),
            ("gc.rs1815739", "ACTN3", "recovery_exercise", "genome_recovery_exercise_v5", "CT", "moderate", 0.18),
            ("gc.rs1801260", "CLOCK", "sleep_circadian", "genome_sleep_circadian_v5", "AG", "low", 0.07),
            ("gc.rs429358", "APOE", "cardiovascular", "genome_cardiovascular_v5", "TT", "moderate", 0.22),
            ("gc.rs1799752", "ACE", "cardiovascular", "genome_cardiovascular_v5", "ID", "moderate", nil),
            ("gc.rs12722", "COL5A1", "injury_risk", "genome_injury_risk_v5", "CT", "low", -0.09),
            ("gc.rs53576", "OXTR", "cognitive_mental", "genome_cognitive_mental_v5", "GG", "low", nil),
            ("gc.rs1695", "GSTP1", "longevity", "genome_longevity_v5", "AG", "low", 0.06),
        ]
        return specs.map { name, gene, category, icon, raw, level, score in
            GenomeDataMarker(
                canonicalName: name, gene: gene, rsid: name.hasPrefix("gc.rs") ? String(name.dropFirst(3)) : nil,
                alleles: raw.count == 2 ? raw.map(String.init) : nil,
                categoryId: category, panelId: "\(category)_panel", reportId: "r",
                rawValue: raw, unit: raw.contains("*") ? "diplotype" : "genotype",
                resultLabel: sampleCopy[name]?.result, evidenceLevel: level, evidenceBasis: "GWAS Catalog",
                validatedPopulations: ["broad"], meaning: sampleCopy[name]?.meaning,
                citations: [], sequenceContext: nil, isFeatured: score != nil, score: score, iconKey: icon
            )
        }
    }
}
