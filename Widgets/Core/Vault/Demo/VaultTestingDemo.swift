//
//  VaultTestingDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 18/9/2026.
//

import Foundation

extension VaultTestCategory {
    static let demo: [VaultTestCategory] = [
        VaultTestCategory(
            id: "longevity",
            name: "Longevity",
            backgroundName: ImageNames.vaultTestLongevityCategoryV5,
            tileName: ImageNames.vaultTestLongevityTileV5,
            systemImage: "figure"
        ),
        VaultTestCategory(
            id: "hormones",
            name: "Hormones",
            backgroundName: ImageNames.vaultTestHormonesCategoryV5,
            tileName: ImageNames.vaultTestHormonesTileV5,
            systemImage: "bolt.heart",
            iconName: ImageNames.vaultTestHormonesIconV5
        ),
        VaultTestCategory(
            id: "gut",
            name: "Gut Health",
            backgroundName: ImageNames.vaultTestGutHealthCategoryV5,
            tileName: ImageNames.vaultTestGutHealthTileV5,
            systemImage: "allergens",
            iconName: ImageNames.vaultTestGutHealthIconV5
        ),
        VaultTestCategory(
            id: "metabolic",
            name: "Metabolic Health",
            backgroundName: ImageNames.vaultTestMetabolicHealthBackgroundV5,
            tileName: ImageNames.vaultTestMetabolicHealthTileV5,
            systemImage: "flame",
            iconName: ImageNames.vaultTestMetabolicHealthIconV5
        ),
        VaultTestCategory(
            id: "fertility",
            name: "Fertility",
            backgroundName: ImageNames.vaultTestFertilityBackgroundV5,
            tileName: ImageNames.vaultTestFertilityTileV5,
            systemImage: "heart.circle",
            iconName: ImageNames.vaultTestFertilityIconV5
        ),
        VaultTestCategory(
            id: "heart",
            name: "Heart Health",
            backgroundName: ImageNames.vaultTestHeartHealthCategoryV5,
            tileName: ImageNames.vaultTestHeartHealthTileV5,
            systemImage: "heart"
        ),
        VaultTestCategory(
            id: "sleep",
            name: "Sleep",
            backgroundName: ImageNames.vaultTestSleepCategoryV5,
            tileName: ImageNames.vaultTestSleepTileV5,
            systemImage: "moon.fill"
        ),
        VaultTestCategory(
            id: "vitamins",
            name: "Vitamins",
            backgroundName: ImageNames.vaultTestVitaminsCategoryV5,
            tileName: ImageNames.vaultTestVitaminsTileV5,
            systemImage: "pills"
        ),
    ]

    static func named(_ id: String) -> VaultTestCategory? {
        demo.first { $0.id == id }
    }

    @MainActor static var offered: [VaultTestCategory] {
        demo.filter { VaultTestingClinic.testCount(in: $0.id) > 0 }
    }
}

extension VaultTestOrder {
    static let demo: [VaultTestOrder] = {
        let clinic = VaultTestingClinic.demo[0]
        let now = Date.now
        return [
            VaultTestOrder(
                number: "482913",
                test: clinic.tests[0],
                clinic: clinic,
                type: .atHomeKit,
                placedAt: now.addingTimeInterval(-2 * 86_400),
                address: "2/23 Wardell St, Marrickville NSW 2204, AUS",
                delivery: VaultTestDelivery(arrivesOn: now.addingTimeInterval(2 * 86_400), progress: 0.55),
                paymentMethod: .applePay
            ),
        ]
    }()
}

extension VaultTestingClinic {
    var website: URL { .demoWebsite(for: name) }

    static func tests(at clinicId: String) -> [VaultClinicTest] {
        demo.first { $0.id == clinicId }?.tests ?? []
    }

    @MainActor static func testCount(in categoryId: String) -> Int {
        LabCatalog.shared.clinics.reduce(0) { count, clinic in
            count + clinic.tests.filter { $0.categoryIds.contains(categoryId) }.count
        }
    }

    static let demo: [VaultTestingClinic] = [
        VaultTestingClinic(
            id: "longevity-clinic",
            name: "Longevity Clinic",
            address: "121 Norton St, Leichhardt NSW 2040",
            distanceKm: 5.3,
            latitude: -33.8836,
            longitude: 151.1566,
            services: ["Blood / CBC", "Electrolytes", "Liver", "Lipids", "Metabolic Health", "Inflammation"],
            tests: [
                VaultClinicTest(
                    id: "heart-panel-0",
                    name: "Heart Health Panel",
                    detail: "Cholesterol, inflammation and the markers most closely tied to cardiovascular risk.",
                    categoryIds: ["heart"],
                    included: ["ApoB", "Lipid profile", "Lp(a)", "hs-CRP", "Homocysteine"],
                    availability: [.inPerson, .homeVisit]
                ),
                VaultClinicTest(
                    id: "longevity-panel",
                    name: "Longevity Panel",
                    detail: "A broad blood panel covering the markers most linked to biological ageing and long-term disease risk.",
                    categoryIds: ["longevity"],
                    included: ["Complete blood count", "Lipid profile", "HbA1c", "hs-CRP", "Liver function", "Kidney function"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "metabolic-panel",
                    name: "Metabolic Panel",
                    detail: "Blood sugar regulation and insulin sensitivity alongside your cholesterol picture.",
                    categoryIds: ["metabolic"],
                    included: ["Fasting glucose", "HbA1c", "Fasting insulin", "Lipid profile"],
                    availability: [.inPerson, .atHomeKit, .homeVisit]
                ),
                VaultClinicTest(
                    id: "inflammation-markers",
                    name: "Inflammation Markers",
                    detail: "The main circulating markers of chronic inflammation, useful for tracking recovery and diet changes.",
                    categoryIds: ["longevity"],
                    included: ["hs-CRP", "ESR", "Ferritin"],
                    availability: [.inPerson, .homeVisit]
                ),
                VaultClinicTest(
                    id: "hormone-baseline",
                    name: "Hormone Baseline",
                    detail: "A starting read on the hormones behind energy, mood and recovery.",
                    categoryIds: ["hormones"],
                    included: ["Testosterone", "Estradiol", "TSH", "Cortisol"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "gut-health-screen",
                    name: "Gut Health Screen",
                    detail: "A first-pass stool screen for the causes behind bloating and irregularity.",
                    categoryIds: ["gut"],
                    included: ["Calprotectin", "Pathogen screen", "Occult blood"],
                    availability: [.atHomeKit, .homeVisit]
                ),
                VaultClinicTest(
                    id: "fertility-overview",
                    name: "Fertility Overview",
                    detail: "The cycle and reserve markers worth knowing before any fertility planning.",
                    categoryIds: ["fertility"],
                    included: ["AMH", "FSH", "LH", "Progesterone"],
                    availability: [.inPerson, .atHomeKit, .homeVisit]
                ),
            ]
        ),
        VaultTestingClinic(
            id: "meridian-health-labs",
            name: "Meridian Health Labs",
            address: "88 Pirrama Rd, Pyrmont NSW 2009",
            distanceKm: 2.1,
            latitude: -33.8695,
            longitude: 151.1948,
            services: ["Hormones", "Thyroid", "Vitamin D", "Iron Studies", "Cortisol"],
            tests: [
                VaultClinicTest(
                    id: "sleep-study-1",
                    name: "Sleep Study",
                    detail: "A night of monitoring at home to see how long you sleep, how deeply, and how well you breathe.",
                    categoryIds: ["sleep"],
                    included: ["Sleep stages", "Oxygen saturation", "Breathing events", "Heart rate", "Melatonin"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "vitamin-panel-1",
                    name: "Vitamins & Minerals",
                    detail: "The nutrients most often low in active people, from iron stores to vitamin D.",
                    categoryIds: ["vitamins"],
                    included: ["Vitamin D", "B12", "Folate", "Iron studies", "Magnesium", "Zinc"],
                    availability: [.inPerson, .atHomeKit, .homeVisit]
                ),
                VaultClinicTest(
                    id: "hormone-panel",
                    name: "Hormone Panel",
                    detail: "Sex and adrenal hormones that shape energy, mood, libido, sleep and body composition.",
                    categoryIds: ["hormones"],
                    included: ["Total testosterone", "Free testosterone", "Estradiol", "SHBG", "DHEA-S", "LH and FSH"],
                    availability: [.atHomeKit, .inPerson, .homeVisit]
                ),
                VaultClinicTest(
                    id: "thyroid-function",
                    name: "Thyroid Function",
                    detail: "A full thyroid picture, including the antibodies that flag autoimmune thyroid conditions.",
                    categoryIds: ["hormones"],
                    included: ["TSH", "Free T4", "Free T3", "Thyroid antibodies"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "cortisol-rhythm",
                    name: "Cortisol Rhythm",
                    detail: "Four saliva samples across the day map how your stress hormone rises and falls.",
                    categoryIds: ["hormones"],
                    included: ["Waking cortisol", "Midday cortisol", "Evening cortisol", "Bedtime cortisol"],
                    availability: [.atHomeKit, .homeVisit]
                ),
                VaultClinicTest(
                    id: "longevity-bloods",
                    name: "Longevity Bloods",
                    detail: "The everyday bloods that track how well you are ageing, repeated quarterly.",
                    categoryIds: ["longevity"],
                    included: ["Complete blood count", "hs-CRP", "HbA1c", "Liver function", "Kidney function"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "glucose-and-lipids",
                    name: "Glucose and Lipids",
                    detail: "Sugar handling and cholesterol in one fasting draw.",
                    categoryIds: ["metabolic"],
                    included: ["Fasting glucose", "HbA1c", "Lipid profile", "ApoB"],
                    availability: [.inPerson, .homeVisit]
                ),
                VaultClinicTest(
                    id: "gut-symptom-panel",
                    name: "Gut Symptom Panel",
                    detail: "Digestion, absorption and inflammation markers read together.",
                    categoryIds: ["gut"],
                    included: ["Pancreatic elastase", "Calprotectin", "Secretory IgA", "Zonulin"],
                    availability: [.atHomeKit, .homeVisit]
                ),
                VaultClinicTest(
                    id: "fertility-hormones",
                    name: "Fertility Hormones",
                    detail: "Day-three hormones timed to the cycle, with reserve markers alongside.",
                    categoryIds: ["fertility"],
                    included: ["AMH", "Day 3 FSH", "Estradiol", "Prolactin"],
                    availability: [.inPerson, .atHomeKit]
                ),
            ]
        ),
        VaultTestingClinic(
            id: "harbour-diagnostics",
            name: "Harbour Diagnostics",
            address: "45 Miller St, North Sydney NSW 2060",
            distanceKm: 8.7,
            latitude: -33.8389,
            longitude: 151.2072,
            services: ["Genomics", "Microbiome", "Food Sensitivity", "Heavy Metals"],
            tests: [
                VaultClinicTest(
                    id: "vitamin-panel-2",
                    name: "Vitamins & Minerals",
                    detail: "The nutrients most often low in active people, from iron stores to vitamin D.",
                    categoryIds: ["vitamins"],
                    included: ["Vitamin D", "B12", "Folate", "Iron studies", "Magnesium", "Zinc"],
                    availability: [.inPerson, .atHomeKit, .homeVisit]
                ),
                VaultClinicTest(
                    id: "microbiome-map",
                    name: "Microbiome Map",
                    detail: "Sequences the bacteria in a stool sample to score diversity and screen for pathogens.",
                    categoryIds: ["gut"],
                    included: ["16S sequencing", "Diversity score", "Pathogen screen", "Short-chain fatty acids"],
                    availability: [.atHomeKit, .homeVisit]
                ),
                VaultClinicTest(
                    id: "food-sensitivity",
                    name: "Food Sensitivity",
                    detail: "IgG reactions to 96 common foods, to help narrow down what is driving digestive symptoms.",
                    categoryIds: ["gut"],
                    included: ["96-food IgG panel", "Reaction ranking", "Elimination guide"],
                    availability: [.atHomeKit, .homeVisit]
                ),
                VaultClinicTest(
                    id: "heavy-metals",
                    name: "Heavy Metals",
                    detail: "Blood levels of the metals that accumulate from diet, water and the environment.",
                    categoryIds: ["longevity"],
                    included: ["Lead", "Mercury", "Arsenic", "Cadmium"],
                    availability: [.inPerson, .homeVisit]
                ),
                VaultClinicTest(
                    id: "metabolic-genomics",
                    name: "Metabolic Genomics",
                    detail: "The gene variants that shape how you handle carbs, fats and caffeine.",
                    categoryIds: ["metabolic"],
                    included: ["Carbohydrate response", "Lipid metabolism", "Caffeine clearance", "Lactose tolerance"],
                    availability: [.atHomeKit, .homeVisit]
                ),
            ]
        ),
        VaultTestingClinic(
            id: "apex-wellness-centre",
            name: "Apex Wellness Centre",
            address: "312 Crown St, Surry Hills NSW 2010",
            distanceKm: 3.9,
            latitude: -33.8848,
            longitude: 151.2113,
            services: ["Cardiac", "Lipids", "Glucose / HbA1c", "Blood Pressure", "ECG"],
            tests: [
                VaultClinicTest(
                    id: "heart-panel-3",
                    name: "Heart Health Panel",
                    detail: "Cholesterol, inflammation and the markers most closely tied to cardiovascular risk.",
                    categoryIds: ["heart"],
                    included: ["ApoB", "Lipid profile", "Lp(a)", "hs-CRP", "Homocysteine"],
                    availability: [.inPerson, .homeVisit]
                ),
                VaultClinicTest(
                    id: "heart-health",
                    name: "Heart Health",
                    detail: "The advanced lipid markers and a resting ECG that together size up cardiovascular risk.",
                    categoryIds: ["metabolic"],
                    included: ["ApoB", "Lipoprotein(a)", "Lipid profile", "hs-CRP", "Resting ECG"],
                    availability: [.inPerson, .homeVisit, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "glucose-control",
                    name: "Glucose Control",
                    detail: "How well your body handles sugar day to day and over the last three months.",
                    categoryIds: ["metabolic"],
                    included: ["Fasting glucose", "HbA1c", "Fasting insulin"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "cardio-longevity-bloods",
                    name: "Cardio Longevity Bloods",
                    detail: "Heart markers read as an ageing signal rather than a one-off risk score.",
                    categoryIds: ["longevity"],
                    included: ["ApoB", "Lipoprotein(a)", "hs-CRP", "Homocysteine"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "stress-hormones",
                    name: "Stress Hormones",
                    detail: "Cortisol through the day for when training load and sleep stop adding up.",
                    categoryIds: ["hormones"],
                    included: ["Waking cortisol", "Midday cortisol", "Evening cortisol", "DHEA-S"],
                    availability: [.atHomeKit, .homeVisit]
                ),
            ]
        ),
        VaultTestingClinic(
            id: "coastal-pathology",
            name: "Coastal Pathology",
            address: "17 Bronte Rd, Bondi Junction NSW 2022",
            distanceKm: 11.4,
            latitude: -33.8915,
            longitude: 151.2477,
            services: ["Fertility", "Hormones", "Vitamin Panel", "AMH", "Semen Analysis"],
            tests: [
                VaultClinicTest(
                    id: "sleep-study-4",
                    name: "Sleep Study",
                    detail: "A night of monitoring at home to see how long you sleep, how deeply, and how well you breathe.",
                    categoryIds: ["sleep"],
                    included: ["Sleep stages", "Oxygen saturation", "Breathing events", "Heart rate", "Melatonin"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "fertility-panel",
                    name: "Fertility Panel",
                    detail: "Ovarian reserve and the cycle hormones that matter most when planning to conceive.",
                    categoryIds: ["fertility"],
                    included: ["AMH", "FSH", "LH", "Estradiol", "Progesterone"],
                    availability: [.inPerson, .atHomeKit, .homeVisit]
                ),
                VaultClinicTest(
                    id: "semen-analysis",
                    name: "Semen Analysis",
                    detail: "Count, movement and shape of sperm, assessed in the lab within an hour of collection.",
                    categoryIds: ["fertility"],
                    included: ["Sperm count", "Motility", "Morphology", "Volume and pH"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "vitamin-panel",
                    name: "Vitamin Panel",
                    detail: "The vitamins and minerals most often low in an otherwise healthy diet.",
                    categoryIds: ["longevity"],
                    included: ["Vitamin D", "Vitamin B12", "Folate", "Iron studies"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "cycle-hormones",
                    name: "Cycle Hormones",
                    detail: "Hormones sampled across a full cycle to map how it actually runs.",
                    categoryIds: ["hormones"],
                    included: ["Estradiol", "Progesterone", "LH", "FSH", "Prolactin"],
                    availability: [.inPerson, .atHomeKit, .homeVisit]
                ),
            ]
        ),
        VaultTestingClinic(
            id: "inner-west-pathology",
            name: "Inner West Pathology",
            address: "2/188 Marion St, Leichhardt NSW 2040",
            distanceKm: 5.6,
            latitude: -33.8845,
            longitude: 151.1572,
            services: ["Blood / CBC", "Iron Studies", "Thyroid", "Vitamin D"],
            tests: [
                VaultClinicTest(
                    id: "vitamin-panel-5",
                    name: "Vitamins & Minerals",
                    detail: "The nutrients most often low in active people, from iron stores to vitamin D.",
                    categoryIds: ["vitamins"],
                    included: ["Vitamin D", "B12", "Folate", "Iron studies", "Magnesium", "Zinc"],
                    availability: [.inPerson, .atHomeKit, .homeVisit]
                ),
                VaultClinicTest(
                    id: "full-blood-screen",
                    name: "Full Blood Screen",
                    detail: "The standard screen most GPs start with, covering blood cells, iron and the common deficiencies.",
                    categoryIds: ["longevity"],
                    included: ["Complete blood count", "Iron studies", "Vitamin D", "Vitamin B12", "Folate"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "thyroid-check",
                    name: "Thyroid Check",
                    detail: "A first look at thyroid function when energy, weight or temperature feel off.",
                    categoryIds: ["hormones"],
                    included: ["TSH", "Free T4", "Free T3"],
                    availability: [.inPerson, .homeVisit]
                ),
            ]
        ),
        VaultTestingClinic(
            id: "darlinghurst-health-collective",
            name: "Darlinghurst Health Collective",
            address: "210 Oxford St, Darlinghurst NSW 2010",
            distanceKm: 4.2,
            latitude: -33.8794,
            longitude: 151.2169,
            services: ["Hormones", "Cortisol", "Sleep", "Vitamin Panel"],
            tests: [
                VaultClinicTest(
                    id: "heart-panel-6",
                    name: "Heart Health Panel",
                    detail: "Cholesterol, inflammation and the markers most closely tied to cardiovascular risk.",
                    categoryIds: ["heart"],
                    included: ["ApoB", "Lipid profile", "Lp(a)", "hs-CRP", "Homocysteine"],
                    availability: [.inPerson, .homeVisit]
                ),
                VaultClinicTest(
                    id: "sleep-study-6",
                    name: "Sleep Study",
                    detail: "A night of monitoring at home to see how long you sleep, how deeply, and how well you breathe.",
                    categoryIds: ["sleep"],
                    included: ["Sleep stages", "Oxygen saturation", "Breathing events", "Heart rate", "Melatonin"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "sleep-and-stress",
                    name: "Sleep and Stress Panel",
                    detail: "Cortisol and melatonin through the day, read against the hormones that shape sleep quality.",
                    categoryIds: ["hormones"],
                    included: ["Waking cortisol", "Evening cortisol", "Melatonin", "DHEA-S"],
                    availability: [.atHomeKit, .homeVisit]
                ),
                VaultClinicTest(
                    id: "testosterone-check",
                    name: "Testosterone Check",
                    detail: "Total and free testosterone with the binding protein needed to read them properly.",
                    categoryIds: ["hormones"],
                    included: ["Total testosterone", "Free testosterone", "SHBG", "LH"],
                    availability: [.inPerson, .atHomeKit]
                ),
            ]
        ),
        VaultTestingClinic(
            id: "parramatta-diagnostic-hub",
            name: "Parramatta Diagnostic Hub",
            address: "12 Macquarie St, Parramatta NSW 2150",
            distanceKm: 22.8,
            latitude: -33.8148,
            longitude: 151.0017,
            services: ["Metabolic Health", "Glucose / HbA1c", "Liver", "Kidney"],
            tests: [
                VaultClinicTest(
                    id: "vitamin-panel-7",
                    name: "Vitamins & Minerals",
                    detail: "The nutrients most often low in active people, from iron stores to vitamin D.",
                    categoryIds: ["vitamins"],
                    included: ["Vitamin D", "B12", "Folate", "Iron studies", "Magnesium", "Zinc"],
                    availability: [.inPerson, .atHomeKit, .homeVisit]
                ),
                VaultClinicTest(
                    id: "liver-kidney-panel",
                    name: "Liver and Kidney Panel",
                    detail: "How well the two organs clearing your bloodstream are keeping up.",
                    categoryIds: ["longevity"],
                    included: ["ALT and AST", "GGT", "Bilirubin", "eGFR", "Creatinine"],
                    availability: [.inPerson, .homeVisit, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "insulin-resistance",
                    name: "Insulin Resistance",
                    detail: "Fasting markers that flag insulin resistance years before glucose starts to drift.",
                    categoryIds: ["metabolic"],
                    included: ["Fasting insulin", "Fasting glucose", "HOMA-IR", "HbA1c"],
                    availability: [.inPerson, .atHomeKit]
                ),
            ]
        ),
        VaultTestingClinic(
            id: "bondi-beach-wellness",
            name: "Bondi Beach Wellness",
            address: "180 Campbell Pde, Bondi Beach NSW 2026",
            distanceKm: 12.9,
            latitude: -33.8908,
            longitude: 151.2743,
            services: ["Microbiome", "Food Sensitivity", "Vitamin Panel", "Omega-3"],
            tests: [
                VaultClinicTest(
                    id: "heart-panel-8",
                    name: "Heart Health Panel",
                    detail: "Cholesterol, inflammation and the markers most closely tied to cardiovascular risk.",
                    categoryIds: ["heart"],
                    included: ["ApoB", "Lipid profile", "Lp(a)", "hs-CRP", "Homocysteine"],
                    availability: [.inPerson, .homeVisit]
                ),
                VaultClinicTest(
                    id: "gut-repair-panel",
                    name: "Gut Repair Panel",
                    detail: "Digestive markers that show how well the gut lining is absorbing and holding up.",
                    categoryIds: ["gut"],
                    included: ["Calprotectin", "Zonulin", "Pancreatic elastase", "Secretory IgA"],
                    availability: [.atHomeKit, .homeVisit]
                ),
                VaultClinicTest(
                    id: "omega-3-index",
                    name: "Omega-3 Index",
                    detail: "The share of omega-3 in your red blood cells, the marker used in longevity research.",
                    categoryIds: ["longevity"],
                    included: ["Omega-3 index", "EPA", "DHA", "Omega-6 to omega-3 ratio"],
                    availability: [.homeVisit, .atHomeKit]
                ),
            ]
        ),
        VaultTestingClinic(
            id: "chatswood-medical-labs",
            name: "Chatswood Medical Labs",
            address: "5 Help St, Chatswood NSW 2067",
            distanceKm: 14.3,
            latitude: -33.7969,
            longitude: 151.1803,
            services: ["Thyroid", "Fertility", "AMH", "Iron Studies"],
            tests: [
                VaultClinicTest(
                    id: "ovarian-reserve",
                    name: "Ovarian Reserve",
                    detail: "AMH and the early-cycle hormones that estimate how many eggs are left in reserve.",
                    categoryIds: ["fertility"],
                    included: ["AMH", "Day 3 FSH", "Day 3 LH", "Estradiol"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "thyroid-antibodies",
                    name: "Thyroid Antibodies",
                    detail: "The antibodies behind Hashimoto's and Graves', for when thyroid results keep moving.",
                    categoryIds: ["hormones"],
                    included: ["TPO antibodies", "Thyroglobulin antibodies", "TSH receptor antibodies"],
                    availability: [.inPerson, .atHomeKit, .homeVisit]
                ),
            ]
        ),
        VaultTestingClinic(
            id: "newtown-community-pathology",
            name: "Newtown Community Pathology",
            address: "320 King St, Newtown NSW 2042",
            distanceKm: 6.1,
            latitude: -33.8965,
            longitude: 151.1793,
            services: ["Blood / CBC", "Inflammation", "Coeliac", "Food Sensitivity"],
            tests: [
                VaultClinicTest(
                    id: "coeliac-screen",
                    name: "Coeliac Screen",
                    detail: "The antibody screen for gluten sensitivity, taken while you are still eating gluten.",
                    categoryIds: ["gut"],
                    included: ["Tissue transglutaminase IgA", "Total IgA", "Deamidated gliadin peptide"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "inflammation-baseline",
                    name: "Inflammation Baseline",
                    detail: "A starting point for tracking inflammation through a training block or diet change.",
                    categoryIds: ["longevity"],
                    included: ["hs-CRP", "ESR", "White cell differential"],
                    availability: [.inPerson, .homeVisit]
                ),
            ]
        ),
        VaultTestingClinic(
            id: "manly-coastal-health",
            name: "Manly Coastal Health",
            address: "30 The Corso, Manly NSW 2095",
            distanceKm: 16.7,
            latitude: -33.7969,
            longitude: 151.2874,
            services: ["Cardiac", "Lipids", "Blood Pressure", "ECG"],
            tests: [
                VaultClinicTest(
                    id: "cardio-risk-panel",
                    name: "Cardio Risk Panel",
                    detail: "Blood pressure, an ECG and the blood markers that together score heart risk.",
                    categoryIds: ["metabolic"],
                    included: ["Resting ECG", "Blood pressure", "Lipid profile", "hs-CRP"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "advanced-lipids",
                    name: "Advanced Lipids",
                    detail: "The particle-level cholesterol markers a standard lipid panel leaves out.",
                    categoryIds: ["metabolic"],
                    included: ["ApoB", "ApoA1", "Lipoprotein(a)", "LDL particle number"],
                    availability: [.inPerson, .atHomeKit]
                ),
            ]
        ),
        VaultTestingClinic(
            id: "barangaroo-executive-health",
            name: "Barangaroo Executive Health",
            address: "100 Barangaroo Ave, Sydney NSW 2000",
            distanceKm: 1.4,
            latitude: -33.8612,
            longitude: 151.2010,
            services: ["Longevity", "Biological Age", "Hormones", "Full Body"],
            tests: [
                VaultClinicTest(
                    id: "biological-age-panel",
                    name: "Biological Age Panel",
                    detail: "An epigenetic read of biological age alongside the bloods that explain the number.",
                    categoryIds: ["longevity"],
                    included: ["Epigenetic age", "Telomere length", "hs-CRP", "HbA1c", "Lipid profile"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "executive-hormone-screen",
                    name: "Executive Hormone Screen",
                    detail: "A broad hormone sweep aimed at energy, recovery and body composition under load.",
                    categoryIds: ["hormones"],
                    included: ["Testosterone", "Cortisol", "Thyroid panel", "IGF-1", "DHEA-S"],
                    availability: [.inPerson, .homeVisit]
                ),
                VaultClinicTest(
                    id: "gut-and-microbiome-screen",
                    name: "Gut and Microbiome Screen",
                    detail: "Full microbiome sequencing paired with the markers of a leaky or inflamed gut.",
                    categoryIds: ["gut"],
                    included: ["16S sequencing", "Diversity score", "Calprotectin", "Zonulin", "Short-chain fatty acids"],
                    availability: [.atHomeKit, .homeVisit]
                ),
                VaultClinicTest(
                    id: "metabolic-performance-panel",
                    name: "Metabolic Performance Panel",
                    detail: "Fuel use under load, from fasting insulin through to advanced lipids.",
                    categoryIds: ["metabolic"],
                    included: ["Fasting insulin", "HbA1c", "ApoB", "Lipoprotein(a)", "Liver function"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "family-planning-check",
                    name: "Family Planning Check",
                    detail: "Reserve, thyroid and immunity checks for couples thinking a year ahead.",
                    categoryIds: ["fertility"],
                    included: ["AMH", "Thyroid panel", "Rubella immunity", "Semen analysis"],
                    availability: [.inPerson, .atHomeKit, .homeVisit]
                ),
            ]
        ),
        VaultTestingClinic(
            id: "randwick-fertility-labs",
            name: "Randwick Fertility Labs",
            address: "48 Belmore Rd, Randwick NSW 2031",
            distanceKm: 9.8,
            latitude: -33.9146,
            longitude: 151.2415,
            services: ["Fertility", "AMH", "Semen Analysis", "Genetics"],
            tests: [
                VaultClinicTest(
                    id: "preconception-panel",
                    name: "Preconception Panel",
                    detail: "The hormone, iron and immunity checks recommended in the months before trying.",
                    categoryIds: ["fertility"],
                    included: ["AMH", "Thyroid panel", "Iron studies", "Rubella immunity", "Vitamin D"],
                    availability: [.inPerson, .atHomeKit]
                ),
                VaultClinicTest(
                    id: "carrier-screening",
                    name: "Carrier Screening",
                    detail: "Screens both partners for the inherited conditions most often passed on together.",
                    categoryIds: ["fertility"],
                    included: ["Cystic fibrosis", "Spinal muscular atrophy", "Fragile X", "Expanded panel"],
                    availability: [.atHomeKit, .homeVisit]
                ),
            ]
        ),
        VaultTestingClinic(
            id: "hurstville-metabolic-clinic",
            name: "Hurstville Metabolic Clinic",
            address: "225 Forest Rd, Hurstville NSW 2220",
            distanceKm: 17.2,
            latitude: -33.9675,
            longitude: 151.1027,
            services: ["Glucose / HbA1c", "Metabolic Health", "Kidney", "Lipids"],
            tests: [
                VaultClinicTest(
                    id: "metabolic-deep-dive",
                    name: "Metabolic Deep Dive",
                    detail: "Two weeks of continuous glucose paired with the bloods that explain the curves.",
                    categoryIds: ["metabolic"],
                    included: ["Continuous glucose monitor", "HbA1c", "Fasting insulin", "Lipid profile", "Liver function"],
                    availability: [.atHomeKit, .inPerson]
                ),
                VaultClinicTest(
                    id: "kidney-function",
                    name: "Kidney Function",
                    detail: "Filtration rate and urine protein, the pair that catch kidney strain early.",
                    categoryIds: ["longevity"],
                    included: ["eGFR", "Creatinine", "Urea", "Urine albumin to creatinine ratio"],
                    availability: [.inPerson, .homeVisit]
                ),
            ]
        ),
    ]
}
