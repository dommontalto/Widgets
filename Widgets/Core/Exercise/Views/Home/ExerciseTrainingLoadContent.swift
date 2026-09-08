//
//  ExerciseTrainingLoadContent.swift
//  Widgets
//
//  Created by Dom Montalto on 8/9/2026.
//

import SwiftUI

struct ExerciseTrainingLoadContent<Accessory: View>: View {
    let load: ExerciseTrainingLoad
    let title: String
    let subtitle: String
    @ViewBuilder let accessory: Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing4x) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(title, size: .body1)
                    BrightText(subtitle, size: .body2, color: .lightTextColor)
                }

                Spacer()

                accessory
            }

            ExerciseSplitPlot(
                strengthPercent: load.strengthPercent,
                cardioPercent: load.cardioPercent
            )
            .padding(.horizontal, .spacing1x)

            VStack(spacing: .spacing2x) {
                ForEach(load.weeks.indices, id: \.self) { index in
                    ExerciseSplitRow(split: load.weeks[index])
                }
            }
            .padding(.top, .spacing2x)
            .padding(.horizontal, .spacing1x)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension ExerciseTrainingLoadContent where Accessory == EmptyView {
    init(load: ExerciseTrainingLoad, title: String, subtitle: String) {
        self.init(load: load, title: title, subtitle: subtitle) { EmptyView() }
    }
}

#Preview {
    ExerciseTrainingLoadContent(
        load: ExerciseDemoData.trainingLoad,
        title: "Split",
        subtitle: "Past 4 weeks"
    )
    .padding(.spacing4x)
}
