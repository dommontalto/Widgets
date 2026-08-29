//
//  ExerciseDiagonalStripes.swift
//  Widgets
//
//  Created by Dom Montalto on 29/8/2026.
//

import SwiftUI

// The hatching a rest day wears, wherever a day is drawn.
struct ExerciseDiagonalStripes: Shape {
    var spacing: CGFloat = Constants.spacing

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var x = rect.minX - rect.height
        while x < rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.maxY))
            path.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
            x += spacing
        }
        return path
    }

    enum Constants {
        static let spacing: CGFloat = 9
        static let lineWidth: CGFloat = 3
    }
}

// Rest reads the same on the planner and under the calendar: green hatching,
// no accent bar.
struct ExerciseRestBackground: View {
    var body: some View {
        ExerciseDiagonalStripes()
            .stroke(
                Color.defaultGreen.opacity(.minimalOpacity),
                lineWidth: ExerciseDiagonalStripes.Constants.lineWidth
            )
    }
}
