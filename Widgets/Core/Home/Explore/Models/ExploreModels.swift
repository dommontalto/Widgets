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

    var id: String { name }
}

struct ExploreAd {
    let title: String
    let subtitle: String
    let image: String
}

struct ExploreSearchClinic: Identifiable {
    let name: String
    let address: String
    let logo: String
    let logoBackground: Color
    var isAd = false
    var services: [String] = []

    var id: String { name }

    func matches(_ query: String) -> Bool {
        ([name, address] + services).contains { $0.localizedStandardContains(query) }
    }
}
