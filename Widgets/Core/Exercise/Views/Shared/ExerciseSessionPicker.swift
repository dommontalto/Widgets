//
//  ExerciseSessionPicker.swift
//  Widgets
//
//  Created by Dom Montalto on 11/8/2026.
//

import SwiftUI

// One tag for every lift in the draft and one per run or sport, in the order
// they were added. The tag that's lit decides what the create screen shows
// below it — a stack of set cards, or a cardio plan.
struct ExerciseSessionPicker: View {
    let exercises: [String]

    @Binding var selection: String?

    var title: (String) -> String = { $0 }

    var symbol: (String) -> String? = { _ in nil }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacing1x) {
                    ForEach(exercises, id: \.self) { exercise in
                        BrightTag(
                            title: title(exercise),
                            systemImage: symbol(exercise),
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
    @Previewable @State var selection: String? = "Gym & Bodyweight"

    ExerciseSessionPicker(
        exercises: ["Gym & Bodyweight", "Outdoor Run", "Football"],
        selection: $selection
    )
}
