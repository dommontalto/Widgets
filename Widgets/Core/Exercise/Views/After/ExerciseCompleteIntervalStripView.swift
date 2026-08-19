//
//  ExerciseCompleteIntervalStripView.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import SwiftUI

// The run's intervals as a row of glyphs. Whichever the glass sits on names
// itself underneath, and that name heads the metrics below.
struct ExerciseCompleteIntervalStripView: View {
    let strip: ExerciseCompleteIntervalStrip

    @State private var selection: BrightRoundPickerIcon

    init(strip: ExerciseCompleteIntervalStrip) {
        self.strip = strip
        let icons = Self.icons(for: strip)
        let index = icons.indices.contains(strip.selectedIndex) ? strip.selectedIndex : 0
        _selection = State(initialValue: icons.indices.contains(index) ? icons[index] : Self.placeholder)
    }

    private var icons: [BrightRoundPickerIcon] {
        Self.icons(for: strip)
    }

    private var selected: ExerciseCompleteIntervalStep? {
        strip.steps.first { $0.id.uuidString == selection.id } ?? strip.steps.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing2x) {
                BrightText("Interval:", size: .body1, weight: .regular)

                BrightRoundPicker(icons: icons, selection: $selection)
            }

            if let selected {
                BrightText(selected.title, size: .standout4, weight: .regular)
                    .contentTransition(.numericText())
                    .animation(.brightSnappy, value: selected.title)
            }
        }
    }

    private static func icons(for strip: ExerciseCompleteIntervalStrip) -> [BrightRoundPickerIcon] {
        strip.steps.map { BrightRoundPickerIcon(id: $0.id.uuidString, symbol: $0.symbol) }
    }

    // Only reached by a strip with no steps, which never renders a picker.
    private static let placeholder = BrightRoundPickerIcon(id: "", symbol: "flag.pattern.checkered")
}

#Preview {
    ExerciseCompleteIntervalStripView(strip: ExerciseDemoComplete.cardio.intervals!)
        .padding(.spacing3x)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.defaultSheetBackground.ignoresSafeArea())
}
