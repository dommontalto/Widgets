//
//  ExerciseSessionPicker.swift
//  Widgets
//
//  Created by Dom Montalto on 11/8/2026.
//

import SwiftUI

// One tag per exercise in the draft, in the order they were added. The tag
// that's lit decides what the create screen shows below it — sets for a lift,
// a cardio plan for a run or a sport.
struct ExerciseSessionPicker: View {
    let exercises: [String]

    @Binding var selection: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacing1x) {
                ForEach(exercises, id: \.self) { exercise in
                    BrightTag(
                        title: exercise,
                        systemImage: ExerciseDemoLibrary.glyph(for: exercise).symbol,
                        isSelected: exercise == selection
                    ) {
                        selection = exercise
                    }
                }
            }
            .padding(.horizontal, .spacing3x)
        }
        .scrollClipDisabled()
        .brightHaptic(.light, trigger: selection)
        .animation(.brightSnappy, value: selection)
        .animation(.brightSnappy, value: exercises)
    }
}

#Preview {
    @Previewable @State var selection: String? = "Bench Press"

    ExerciseSessionPicker(
        exercises: ["Bench Press", "Pull Up", "Outdoor Run", "Football"],
        selection: $selection
    )
}
