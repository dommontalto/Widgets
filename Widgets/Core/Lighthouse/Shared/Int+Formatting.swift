//
//  Int+Formatting.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import Foundation

extension Int {
    var withCommas: String {
        formatted(.number.grouping(.automatic))
    }

    func ordinalSuffix() -> String {
        if (11 ... 13).contains(self % 100) {
            return "\(self)th"
        }
        switch self % 10 {
        case 1: return "\(self)st"
        case 2: return "\(self)nd"
        case 3: return "\(self)rd"
        default: return "\(self)th"
        }
    }
}
