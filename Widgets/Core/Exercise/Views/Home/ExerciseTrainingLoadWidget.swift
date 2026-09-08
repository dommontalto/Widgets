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
        ExerciseTrainingLoadContent(load: load, title: "Split", subtitle: "Past 4 weeks") {
            BrightRoundButton(systemImage: "arrow.down.backward.and.arrow.up.forward") {
                showingYear = true
            }
        }
        .padding(.spacing3x)
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
