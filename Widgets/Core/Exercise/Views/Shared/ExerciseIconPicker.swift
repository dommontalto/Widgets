//
//  ExerciseIconPicker.swift
//  Widgets
//
//  Created by Dom Montalto on 11/8/2026.
//

import SwiftUI

struct ExerciseIconPicker: View {
    let icons: [ExerciseWorkoutIcon]

    @Binding var selection: ExerciseWorkoutIcon

    @Namespace private var pickerSpace

    var body: some View {
        HStack(spacing: Constants.tileGap) {
            ForEach(icons) { icon in
                tile(icon)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .leading) {
            Color.clear
                .frame(width: Constants.tile, height: Constants.tile)
                .modifier(GlassEffect(shape: .circle))
                .matchedGeometryEffect(id: selection, in: pickerSpace, isSource: false)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    select(at: value.location.x)
                }
        )
        .brightHaptic(.light, trigger: selection)
        .animation(.brightSnappy, value: selection)
    }

    private func tile(_ icon: ExerciseWorkoutIcon) -> some View {
        Image(systemName: icon.symbol)
            .font(.standard(size: .subheading, weight: .light))
            .foregroundStyle(icon == selection ? icon.accentColor : .semiLightTextColor)
            .frame(width: Constants.tile, height: Constants.tile)
            .background {
                Circle()
                    .fill(Color.defaultMainGrey.opacity(.finalBossLowOpacity))
            }
            .matchedGeometryEffect(id: icon, in: pickerSpace)
    }

    // One gesture drives both tap and drag, so the glass follows the finger
    // across the row instead of jumping between taps.
    private func select(at x: CGFloat) {
        let slot = Constants.tile + Constants.tileGap
        let index = min(max(0, Int(x / slot)), icons.count - 1)
        guard icons[index] != selection else { return }
        selection = icons[index]
    }

    private enum Constants {
        static let tile: CGFloat = 44
        static let tileGap: CGFloat = .spacing2x
    }
}

#Preview {
    @Previewable @State var strength = ExerciseWorkoutIcon.dumbbell
    @Previewable @State var cardio = ExerciseWorkoutIcon.run

    VStack(spacing: .spacing4x) {
        ExerciseIconPicker(icons: ExerciseWorkoutIcon.strength, selection: $strength)

        ExerciseIconPicker(icons: ExerciseWorkoutIcon.cardio, selection: $cardio)
    }
    .padding(.spacing3x)
}
