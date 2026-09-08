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
}
