//
//  ExerciseCompleteIntervalStripView.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import SwiftUI

// The run's intervals as a row of glyphs. Whichever the glass sits on names
// itself underneath, and the summary reads that step's numbers.
struct ExerciseCompleteIntervalStripView: View {
    let strip: ExerciseCompleteIntervalStrip

    @Binding var selectedIndex: Int

    private var icons: [BrightRoundPickerIcon] {
        strip.steps.indices.map {
            BrightRoundPickerIcon(id: "\($0)", symbol: strip.steps[$0].symbol)
        }
    }

    private var selection: Binding<BrightRoundPickerIcon> {
        Binding(
            get: { icons[min(max(selectedIndex, 0), icons.count - 1)] },
            set: { selectedIndex = Int($0.id) ?? 0 }
        )
    }

    private var selected: ExerciseCompleteIntervalStep? {
        strip.steps.indices.contains(selectedIndex) ? strip.steps[selectedIndex] : strip.steps.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing2x) {
                BrightText("Interval:", size: .body1, weight: .regular)

                BrightRoundPicker(icons: icons, selection: selection)
            }

            if let selected {
                BrightText(selected.title, size: .standout3, weight: .regular)
                    .contentTransition(.numericText())
                    .animation(.brightSnappy, value: selected.title)
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedIndex = 5

    ExerciseCompleteIntervalStripView(
        strip: ExerciseDemoComplete.cardio.intervals!,
        selectedIndex: $selectedIndex
    )
    .padding(.spacing3x)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.defaultSheetBackground.ignoresSafeArea())
}
