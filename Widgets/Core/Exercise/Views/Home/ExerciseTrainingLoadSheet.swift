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
                ExerciseTrainingLoadContent(
                    load: load,
                    title: "Last 12 months",
                    subtitle: "Strength & Cardio"
                )
                .padding(.vertical, .spacing3x)
            }
            .scrollIndicators(.hidden)
        }
    }
}

#Preview {
    ExerciseTrainingLoadSheet()
}
