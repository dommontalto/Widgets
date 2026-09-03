//
//  LighthouseModel.swift
//  Widgets
//
//  Created by Dom Montalto on 3/9/2026.
//

import Foundation

struct LighthouseModelTier: Identifiable, Hashable {
    let id: String
    let name: String
    let label: String
}

enum LighthouseModel: String, CaseIterable, Identifiable {
    case chatGPT
    case gemini
    case claude
    case grok

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .chatGPT: "ChatGPT"
        case .gemini: "Gemini"
        case .claude: "Claude"
        case .grok: "Grok"
        }
    }

    // The tier logo — the icon on its coloured backdrop — shown in the input
    // bar's model picker.
    var tierImageName: String {
        switch self {
        case .chatGPT: ImageNames.lighthouseGptTierV5
        case .gemini: ImageNames.lighthouseGeminiTierV5
        case .claude: ImageNames.lighthouseClaudeTierV5
        case .grok: ImageNames.lighthouseGrokTierV5
        }
    }

    var wallpaperImageName: String {
        switch self {
        case .chatGPT: ImageNames.lighthouseGptWallpaperV5
        case .gemini: ImageNames.lighthouseGeminiWallpaperV5
        case .claude: ImageNames.lighthouseClaudeWallpaperV5
        case .grok: ImageNames.lighthouseGrokWallpaperV5
        }
    }

    var tiers: [LighthouseModelTier] {
        switch self {
        case .chatGPT:
            [
                LighthouseModelTier(id: "gpt54", name: "GPT-5.4", label: "Fast & versatile"),
                LighthouseModelTier(id: "gpt55", name: "GPT-5.5", label: "Most capable"),
                LighthouseModelTier(id: "o3", name: "o3", label: "Advanced reasoning"),
            ]
        case .gemini:
            [
                LighthouseModelTier(id: "flash", name: "2.5 Flash", label: "Fast responses"),
                LighthouseModelTier(id: "pro25", name: "2.5 Pro", label: "Most capable"),
            ]
        case .claude:
            [
                LighthouseModelTier(id: "haiku", name: "Haiku 4.5", label: "Fast & lightweight"),
                LighthouseModelTier(id: "sonnet", name: "Sonnet 4.6", label: "Fast & smart"),
                LighthouseModelTier(id: "opus", name: "Opus 4.6", label: "Most capable"),
            ]
        case .grok:
            [
                LighthouseModelTier(id: "grok420", name: "Grok 4.20", label: "Fast & efficient"),
                LighthouseModelTier(id: "grok43", name: "Grok 4.3", label: "Most capable"),
            ]
        }
    }

    var defaultTier: LighthouseModelTier {
        tiers[0]
    }

    func selectedTier() -> LighthouseModelTier {
        let stored = UserDefaults.standard.dictionary(forKey: Constants.tiersKey) as? [String: String] ?? [:]
        if let tierId = stored[rawValue],
           let tier = tiers.first(where: { $0.id == tierId }) {
            return tier
        }
        return defaultTier
    }

    func saveTier(_ tier: LighthouseModelTier) {
        var stored = UserDefaults.standard.dictionary(forKey: Constants.tiersKey) as? [String: String] ?? [:]
        stored[rawValue] = tier.id
        UserDefaults.standard.set(stored, forKey: Constants.tiersKey)
    }

    private enum Constants {
        static let tiersKey = "lighthouseModelTiers"
    }
}
