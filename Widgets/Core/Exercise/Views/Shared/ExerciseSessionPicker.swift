//
//  ExerciseSessionPicker.swift
//  Widgets
//
//  Created by Dom Montalto on 11/8/2026.
//

import SwiftUI

// One tile per exercise in the draft, in the order they were added. The tile
// that's lit decides what the create screen shows below it — sets for a lift,
// a cardio plan for a run or a sport.
struct ExerciseSessionPicker: View {
    let exercises: [String]

    @Binding var selection: String?

    @Namespace private var pickerSpace

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.tileGap) {
                ForEach(exercises, id: \.self) { exercise in
                    tile(exercise)
                }
            }
            .background(alignment: .leading) {
                if let selection {
                    Color.clear
                        .frame(width: Constants.tile, height: Constants.tile)
                        .modifier(GlassEffect(shape: .circle))
                        .matchedGeometryEffect(id: selection, in: pickerSpace, isSource: false)
                }
            }
            .padding(.horizontal, .spacing3x)
        }
        .scrollClipDisabled()
        .brightHaptic(.light, trigger: selection)
        .animation(.brightSnappy, value: selection)
        .animation(.brightSnappy, value: exercises)
    }

    private func tile(_ exercise: String) -> some View {
        let glyph = ExerciseDemoLibrary.glyph(for: exercise)

        return Button {
            selection = exercise
        } label: {
            Image(systemName: glyph.symbol)
                .font(.standard(size: .subheading, weight: .light))
                .foregroundStyle(exercise == selection ? glyph.color : .semiLightTextColor)
                .frame(width: Constants.tile, height: Constants.tile)
                .background {
                    Circle()
                        .fill(Color.defaultMainGrey.opacity(.finalBossLowOpacity))
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .matchedGeometryEffect(id: exercise, in: pickerSpace)
    }

    private enum Constants {
        static let tile: CGFloat = 44
        static let tileGap: CGFloat = .spacing2x
    }
}

#Preview {
    @Previewable @State var selection: String? = "Bench Press"

    ExerciseSessionPicker(
        exercises: ["Bench Press", "Pull Up", "Outdoor Run", "Football"],
        selection: $selection
    )
}
