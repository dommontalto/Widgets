//
//  ExploreModels.swift
//  Widgets
//
//  Created by Dom Montalto on 23/9/2026.
//

import SwiftUI

struct ExploreAgent: Identifiable {
    enum Mark {
        case asset(String)
        case symbol(String)
    }

    let title: String
    let systemImage: String
    let name: String
    let blurb: String
    let mark: Mark
    let background: String
    let tint: Color
    let examples: [ExerciseProgramChatExample]
    let suggestions: [ExerciseProgramChatExample]
    let reply: String
    let steps: [String]
    let animation: ExploreAgentAnimation.Style

    var id: String { title }
}

struct ExploreAgentReply {
    let query: String
    let clinics: [ExploreSearchClinic]
}

struct ExploreClinic: Identifiable {
    let name: String
    let logo: String
    let background: Color
    var fillsLogo = false

    var id: String { name }
}

struct ExploreSearchClinic: Identifiable {
    let name: String
    let address: String
    let logo: String
    let logoBackground: Color
    var isAd = false
    var services: [String] = []
    var blurb = ""
    var tests: [VaultClinicTest] = []

    var id: String { name }

    var testingClinic: VaultTestingClinic {
        VaultTestingClinic(
            id: name,
            name: name,
            address: address,
            distanceKm: 0,
            latitude: 0,
            longitude: 0,
            services: services,
            tests: tests
        )
    }

    func matches(_ query: String) -> Bool {
        ([name, address] + services).contains { $0.localizedStandardContains(query) }
    }
}
