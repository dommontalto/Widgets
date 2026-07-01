//
//  WorkoutsDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import Foundation

enum WorkoutsDemoData {
    static func randomGrid(rows: Int, columns: Int) -> [[Bool]] {
        (0..<rows).map { _ in (0..<columns).map { _ in Bool.random() } }
    }
}
