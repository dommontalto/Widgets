//
//  ExploreDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 23/9/2026.
//

import SwiftUI

extension ExploreAgent {
    static let demo = [
        ExploreAgent(
            title: "Find Products",
            systemImage: "shippingbox",
            name: "Product Agent",
            blurb: "This agent will help you find health products that fit your goals.",
            mark: .symbol("shippingbox.fill"),
            background: ImageNames.exploreNutritionBackgroundV5,
            tint: .defaultGreen,
            examples: [
                ExerciseProgramChatExample("pills", "Find a magnesium supplement for better sleep."),
                ExerciseProgramChatExample("applewatch", "Compare wearables that track HRV."),
                ExerciseProgramChatExample("takeoutbag.and.cup.and.straw", "Meal delivery that fits my macros."),
            ],
            suggestions: [
                ExerciseProgramChatExample("pills", "Supplements"),
                ExerciseProgramChatExample("applewatch", "Wearables"),
                ExerciseProgramChatExample("takeoutbag.and.cup.and.straw", "Meal services"),
                ExerciseProgramChatExample("dollarsign.circle", "Under $50"),
            ],
            reply: "Here are a few places that stock what you're after, based on your goals:"
        ),
        ExploreAgent(
            title: "Find Services",
            systemImage: "sparkle.text.clipboard",
            name: "Service Agent",
            blurb: "This agent will help you find health services in your area.",
            mark: .asset(ImageNames.exploreAgentStickerV5),
            background: ImageNames.exploreServiceAgentBackgroundV5,
            tint: .defaultYellow,
            examples: [
                ExerciseProgramChatExample("figure.run", "Find a sports physio near me."),
                ExerciseProgramChatExample("bed.double", "Find a sleep specialist in Sydney."),
                ExerciseProgramChatExample("drop", "Compare blood testing options nearby."),
            ],
            suggestions: [
                ExerciseProgramChatExample("location", "Near me"),
                ExerciseProgramChatExample("creditcard", "Bulk billed"),
                ExerciseProgramChatExample("video", "Telehealth"),
                ExerciseProgramChatExample("calendar", "This week"),
            ],
            reply: "I found these clinics near you that match what you asked for:"
        ),
        ExploreAgent(
            title: "Monitor Research",
            systemImage: "inset.filled.rectangle.and.person.filled",
            name: "Research Agent",
            blurb: "This agent will keep an eye on new research that matters to you.",
            mark: .symbol("doc.text.magnifyingglass"),
            background: ImageNames.exploreSleepBackgroundV5,
            tint: .defaultSkyBlue,
            examples: [
                ExerciseProgramChatExample("dna", "Monitor new research on APOE4."),
                ExerciseProgramChatExample("heart.text.square", "Track studies on resting heart rate."),
                ExerciseProgramChatExample("moon.zzz", "Alert me to new sleep research."),
            ],
            suggestions: [
                ExerciseProgramChatExample("newspaper", "Weekly digest"),
                ExerciseProgramChatExample("dna", "My genome"),
                ExerciseProgramChatExample("drop", "My biomarkers"),
                ExerciseProgramChatExample("checkmark.seal", "Trusted sources"),
            ],
            reply: "Got it. While I watch for new studies, these clinics work in that area:"
        ),
    ]
}

extension ExploreBrowseCategory {
    static let demo: [ExploreBrowseCategory] = ([
        ExploreBrowseCategory(
            id: "nutrition",
            name: "Nutrition",
            clinicCount: 10,
            backgroundImage: ImageNames.exploreNutritionBackgroundV5,
            mark: .symbol("fork.knife")
        ),
        testing("gut", named: "Gut"),
        testing("hormones", named: "Hormones"),
        testing("metabolic", named: "Metabolic"),
        testing("fertility", named: "Fertility"),
        ExploreBrowseCategory(
            id: "sleep",
            name: "Sleep",
            clinicCount: 15,
            backgroundImage: ImageNames.exploreSleepBackgroundV5,
            mark: .symbol("moon.fill")
        ),
    ] as [ExploreBrowseCategory?]).compactMap { $0 }

    private static func testing(_ id: String, named name: String) -> ExploreBrowseCategory? {
        guard let category = VaultTestCategory.named(id) else { return nil }
        return ExploreBrowseCategory(
            id: id,
            name: name,
            clinicCount: VaultTestingClinic.count(offering: id),
            backgroundImage: category.backgroundName,
            mark: .testing(category)
        )
    }
}

extension ExploreClinic {
    var website: URL { .demoWebsite(for: name) }

    static let demo = [
        ExploreClinic(name: "Commons Health Club", logo: ImageNames.exploreCommonsHealthClubV5, background: Color(hex: "#296712")),
        ExploreClinic(name: "The Skin Hospital", logo: ImageNames.exploreSkinHospitalV5, background: .white),
    ]
}

extension ExploreAd {
    var website: URL { .demoWebsite(for: title) }

    static let demo = ExploreAd(
        title: "The Microbiome Clinic",
        subtitle: "Gut Health",
        image: ImageNames.exploreMicrobiomeClinicAdV5
    )
}

extension ExploreSearchClinic {
    var website: URL { .demoWebsite(for: name) }

    static let suggestions = [
        ExploreSearchClinic(
            name: "Little Lungs Sleep Clinic",
            address: "Sleep",
            logo: ImageNames.exploreLittleLungsLogoV5,
            logoBackground: Color(hex: "#D9D9D9"),
            isAd: true
        ),
        ExploreSearchClinic(
            name: "Move Clinic",
            address: "21 Danks St, Waterloo NSW 2017",
            logo: ImageNames.exploreMoveClinicLogoV5,
            logoBackground: Color(hex: "#D9D9D9")
        ),
        ExploreSearchClinic(
            name: "The Nutrition Clinic",
            address: "Nutrition",
            logo: ImageNames.exploreNutritionClinicLogoV5,
            logoBackground: .white
        ),
    ]

    static let results = [
        ExploreSearchClinic(
            name: "Move Clinic",
            address: "21 Danks St, Waterloo NSW 2017",
            logo: ImageNames.exploreMoveClinicLogoV5,
            logoBackground: Color(hex: "#D9D9D9"),
            isAd: true,
            services: ["Physiotherapy", "Exercise Physiology", "Women's health", "NDIS - Disability", "Performance Management"]
        ),
        ExploreSearchClinic(
            name: "FXNL Rehab",
            address: "shop 5/289 Liverpool Rd, Strathfield NSW 2135",
            logo: ImageNames.exploreFxnlRehabLogoV5,
            logoBackground: Color(hex: "#D9D9D9"),
            services: ["Manual Therapy", "Movement based rehab", "Telehealth", "Musculoskeletal", "Orthopaedic"]
        ),
        ExploreSearchClinic(
            name: "East Point Recovery",
            address: "Level 1/318 Liverpool St, Darlinghurst NSW 2010",
            logo: ImageNames.exploreEastPointRecoveryLogoV5,
            logoBackground: .black,
            services: ["Osteopathy", "Enhanced Primary Care", "Telehealth", "Musculoskeletal", "Orthopaedic"]
        ),
    ]
}

extension URL {
    static func demoWebsite(for name: String) -> URL {
        URL(string: demoWebsites[name] ?? "https://thebrightapp.xyz")!
    }

    private static let demoWebsites = [
        "Commons Health Club": "https://thecommonshealthclub.com.au",
        "The Skin Hospital": "https://www.skinhospital.edu.au",
        "The Microbiome Clinic": "https://themicrobiomeclinic.com.au",
        "Little Lungs Sleep Clinic": "https://www.littlelungs.com.au",
        "Move Clinic": "https://moveclinic.com.au/waterloo/",
        "The Nutrition Clinic": "https://www.nutritionclinic.com.au",
        "FXNL Rehab": "https://www.fxnlrehab.com.au",
        "East Point Recovery": "https://www.eprecovery.com.au",
        "Longevity Clinic": "https://www.progressivespecialists.com.au/longevity-consultation",
    ]
}
