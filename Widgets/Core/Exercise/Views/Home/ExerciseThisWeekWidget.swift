//
//  ExerciseThisWeekWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import SwiftUI

struct ExerciseThisWeekWidget: View {
    private let stats = [
        ExerciseWorkoutStat(label: "Workouts", value: "4"),
        ExerciseWorkoutStat(label: "Volume", value: "38,420", unit: "kg"),
        ExerciseWorkoutStat(label: "Distance", value: "15.1", unit: "km"),
        ExerciseWorkoutStat(label: "Time training", value: "4:12", unit: "hrs"),
    ]

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: .spacing2x), count: 2),
            spacing: .spacing2x
        ) {
            ForEach(stats.indices, id: \.self) { i in
                statTile(stats[i])
            }
        }
    }

    private func statTile(_ stat: ExerciseWorkoutStat) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                BrightText(stat.value, size: .standout3, weight: .regular)
                    .monospacedDigit()
                if let unit = stat.unit {
                    BrightText(unit, size: .body4, color: .lightTextColor)
                }
            }
            BrightText(stat.label, size: .body4, color: .semiLightTextColor)
        }
        .padding(.horizontal, .spacing2x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Constants.tileHeight)
        .modifier(CardModifier(cornerRadius: .cornerRadius24))
    }

    private class Constants {
        static let tileHeight: CGFloat = 67
    }
}

#Preview {
    ExerciseThisWeekWidget()
        .padding(.spacing4x)
}
