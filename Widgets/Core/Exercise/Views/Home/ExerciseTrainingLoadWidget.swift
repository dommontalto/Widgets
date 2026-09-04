//
//  ExerciseTrainingLoadWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 21/7/2026.
//

import SwiftUI

struct ExerciseTrainingLoadWidget: View {
    @State private var load = ExerciseDemoData.trainingLoad

    @State private var showingYear = false

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing4x) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText("Split", size: .body1)
                    BrightText("Past 4 weeks", size: .body2, color: .lightTextColor)
                }

                Spacer()

                BrightRoundButton(systemImage: "arrow.down.backward.and.arrow.up.forward", size: .small) {
                    showingYear = true
                }
            }

            ExerciseSplitBar(
                strengthPercent: load.strengthPercent,
                cardioPercent: load.cardioPercent
            )

            Rectangle()
                .fill(Color.textColor.opacity(.ultraLowOpacity))
                .frame(height: 1)

            VStack(spacing: .spacing2x) {
                ForEach(load.weeks.indices, id: \.self) { i in
                    ExerciseSplitRow(split: load.weeks[i])
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
        .sheet(isPresented: $showingYear) {
            ExerciseTrainingLoadSheet()
        }
    }
}

#Preview {
    ExerciseTrainingLoadWidget()
        .padding(.spacing4x)
}
