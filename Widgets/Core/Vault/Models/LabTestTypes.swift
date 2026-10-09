//
//  LabTestTypes.swift
//  Widgets
//

import Foundation

enum LabTestTypes {
    private struct Mapping: Decodable {
        let eirly: [String: [String]]
        let junction: [String: [String]]
    }

    private static let mapping: Mapping? = {
        guard let url = Bundle.main.url(forResource: "lab-test-types", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(Mapping.self, from: data)
    }()

    static func eirly(_ testId: String) -> [String] {
        mapping?.eirly[testId] ?? []
    }

    static func junction(_ name: String) -> [String] {
        mapping?.junction[name.trimmingCharacters(in: .whitespaces)] ?? []
    }
}
