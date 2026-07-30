//
//  BrightPluralisation.swift
//  Widgets
//
//  Created by Dom Montalto on 30/7/2026.
//

import Foundation

nonisolated extension Int {
    func counted(_ singular: String, plural: String? = nil) -> String {
        "\(self) \(self == 1 ? singular : plural ?? singular + "s")"
    }
}
