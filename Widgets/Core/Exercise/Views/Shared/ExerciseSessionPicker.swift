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
        ScrollViewReader { proxy in
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
                        .id(exercise)
                    }
                }
                .padding(.horizontal, .spacing3x)
            }
            .scrollClipDisabled()
            .brightHaptic(.light, trigger: selection)
            .animation(.brightSnappy, value: selection)
            .animation(.brightSnappy, value: exercises)
            // A freshly added exercise is lit as it lands, and the row it lands
            // on may already be scrolled past the edge, so the tags follow it.
            .onChange(of: selection) { _, selected in
                guard let selected else { return }
                withAnimation(.brightSnappy) {
                    proxy.scrollTo(selected, anchor: .center)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var selection: String? = "Bench Press"

    ExerciseSessionPicker(
        exercises: ["Bench Press", "Pull Up", "Outdoor Run", "Football"],
        selection: $selection
    )
}
