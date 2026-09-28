//
//  GraphWorkbenchModels.swift
//  Widgets
//
//  Created by Dom Montalto on 28/9/2026.
//

import SwiftUI

// Bright's health domains. Each draws in a family of shades, so a domain
// reads as one colour across the constellation while its entities stay
// distinguishable.
enum GraphEntityType: String {
    case sleep
    case heart
    case exercise
    case nutrition
    case mind
    case biomarker
    case genome

    var title: String {
        rawValue.uppercased()
    }

    var shades: [Color] {
        switch self {
        case .sleep: [.defaultSkyBlue, .defaultRemBlue, .defaultElectricBlue, .defaultLighthouseBlue, .defaultDeepBlue]
        case .heart: [.defaultRed, .defaultOrange, .defaultPink]
        case .exercise: [.defaultOrange, .defaultAmber, .defaultSaturatedYellow]
        case .nutrition: [.defaultYellow, .defaultPolyUnsaturatedYellow, .defaultTransFatYellow]
        case .mind: [.defaultBrightPink, .defaultPink, .defaultPurple, .defaultBrightViolet]
        case .biomarker: [.defaultBrightGreen, .genomePRSGreen, .progressBarStartingGreen]
        case .genome: [.genomePRSCyan, .defaultCyan, .defaultSkyBlue]
        }
    }

    var systemImage: String {
        switch self {
        case .sleep: "moon.zzz.fill"
        case .heart: "heart.fill"
        case .exercise: "figure.run"
        case .nutrition: "fork.knife"
        case .mind: "brain.head.profile"
        case .biomarker: "testtube.2"
        case .genome: "circle.hexagongrid.fill"
        }
    }
}

struct GraphEntity: Identifiable, Hashable {
    let id: String
    let humanReadableID: Int
    let title: String
    let type: GraphEntityType
    // Which of the domain's shades this entity draws in.
    let shade: Int
    let description: String
    let frequency: Int
    let degree: Int

    var color: Color {
        type.shades[shade % type.shades.count]
    }
}

struct GraphRelationship: Identifiable, Hashable {
    let id: String
    let source: String
    let target: String
    let description: String
    let weight: Int
}

struct GraphCommunity: Identifiable, Hashable {
    let id: String
    let level: Int
    let parentID: String?
    let title: String
    let summary: String
    let entityIDs: [String]

    var size: Int {
        entityIDs.count
    }

    // GraphRAG's levels, named the way the Workbench names them.
    var levelTitle: String {
        switch level {
        case 0: "Sector"
        case 1: "System"
        case 2: "Subsystem"
        case 3: "Component"
        case 4: "Element"
        default: "L\(level)"
        }
    }
}

struct GraphWorkbenchData {
    let name: String
    let entities: [GraphEntity]
    let relationships: [GraphRelationship]
    let communities: [GraphCommunity]
}
