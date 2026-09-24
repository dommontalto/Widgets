//
//  LighthouseModelChoice.swift
//  Widgets
//
//  Created by Dom Montalto on 18/9/2026.
//

import Foundation

enum LighthouseModelChoice: Identifiable, Hashable, CaseIterable {
    case apiKey
    case model(LighthouseModel)

    static var allCases: [LighthouseModelChoice] {
        [.apiKey] + LighthouseModel.allCases.map(Self.model)
    }

    var id: String {
        switch self {
        case .apiKey: Constants.apiKeyId
        case let .model(model): model.id
        }
    }

    var model: LighthouseModel? {
        guard case let .model(model) = self else { return nil }
        return model
    }

    static let apiKeySymbol = "key.icloud"
    static let apiKeyTitle = "API key"

    private enum Constants {
        static let apiKeyId = "api-key"
    }
}
