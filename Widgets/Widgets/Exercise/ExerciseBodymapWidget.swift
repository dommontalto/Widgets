//
//  ExerciseBodymapWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 22/7/2026.
//

import SwiftUI

struct ExerciseBodymapWidget: View {
    private let tileHeight: CGFloat = 67

    @State private var muscleGroups = ExerciseDemoData.muscleGroups

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText("Total Working Sets", size: .body1, color: .textColor)
                BrightText("Per week", size: .body2, color: .lightTextColor)
            }

            Image(ImageNames.exerciseBodymapV5)
                .resizable()
                .scaledToFit()
                .frame(height: 216)
                .frame(maxWidth: .infinity)
                .padding(.bottom, .spacing2x)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: .spacing2x), count: 2),
                spacing: .spacing2x
            ) {
                ForEach(muscleGroups.indices, id: \.self) { i in
                    muscleTile(muscleGroups[i])
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
    }

    private func muscleTile(_ group: ExerciseMuscleGroup) -> some View {
        HStack(spacing: .spacing05x) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                    BrightText("\(group.sets)", size: .standout3, weight: .regular)
                        .monospacedDigit()
                    BrightText("sets", size: .body4, color: .lightTextColor)
                }
                BrightText(group.name, size: .body4, color: .semiLightTextColor)
            }

            Spacer(minLength: .spacing0x)

            BrightHealthStatus(status: group.status)
        }
        .padding(.horizontal, .spacing2x)
        .frame(height: tileHeight)
        .modifier(CardModifier(cornerRadius: .cornerRadius18))
    }
}

#Preview {
    ExerciseBodymapWidget()
        .padding(.spacing4x)
}
