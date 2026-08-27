//
//  ExerciseTrainingLoadSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 27/8/2026.
//

import SwiftUI

struct ExerciseTrainingLoadSheet: View {
    @State private var load = ExerciseDemoData.trainingLoadYear

    var body: some View {
        BrightPageSheetView(title: "Split") {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing3x) {
                    header

                    ExerciseSplitBar(
                        strengthPercent: load.strengthPercent,
                        cardioPercent: load.cardioPercent
                    )

                    divider

                    months
                }
                .padding(.vertical, .spacing3x)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            BrightText("Last 12 months", size: .body1)
            BrightText("Strength & Cardio", size: .body2, color: .lightTextColor)
        }
    }

    private var months: some View {
        VStack(spacing: .spacing2x) {
            ForEach(load.weeks.indices, id: \.self) { i in
                ExerciseSplitRow(split: load.weeks[i])
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.textColor.opacity(.ultraLowOpacity))
            .frame(height: 1)
    }
}

#Preview {
    ExerciseTrainingLoadSheet()
}
