//
//  HeartWorkoutSummaryBreakdownWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import SwiftUI

struct HeartWorkoutSummaryBreakdownWidget: View {
    let data: HeartWorkoutSummaryBreakdownData

    private var zones: [HeartWorkoutSummaryBreakdownData.HeartWorkoutSummaryBreakdownZones] {
        let zones = data.zones ?? []
        return zones.isEmpty ? placeholderZones : zones
    }

    private var placeholderZones: [HeartWorkoutSummaryBreakdownData.HeartWorkoutSummaryBreakdownZones] {
        (1 ... 5).map { .init(title: "Zone \($0)", rangeStr: nil, duration: nil, scaleValue: 0) }
    }

    private var isEmptyState: Bool {
        (data.zones ?? []).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightText("Zone Breakdown", size: .body1)

            ForEach(zones.indices, id: \.self) { index in
                let zone = zones[index]

                VStack(spacing: .spacing1x) {
                    HStack(alignment: .top, spacing: .spacing2x) {
                        BrightText(zone.title ?? "", size: .body2, color: .semiLightTextColor)

                        if !isEmptyState, let rangeStr = zone.rangeStr, !rangeStr.isEmpty {
                            BrightText("\(rangeStr) BPM", size: .body2, color: .lightTextColor)
                        }

                        Spacer()

                        if !isEmptyState, let durationString = zone.duration?.asString, !durationString.isEmpty {
                            BrightText(durationString, size: .body2, color: .semiLightTextColor)
                        }
                    }

                    ProgressBar(
                        color: zoneColor(for: index),
                        scale: isEmptyState ? 0 : (zone.scaleValue ?? 0)
                    )
                }
            }
        }
        .padding(.spacing3x)
        .modifier(CardModifier(color: .sheetModalCards))
    }

    private func zoneColor(for index: Int) -> Color {
        switch index {
        case 0: .defaultBlue
        case 1: .defaultBrightGreen
        case 2: .defaultYellow
        case 3: .defaultOrange
        case 4: .defaultWarningRed
        default: .defaultBlue
        }
    }

    struct ProgressBar: View {
        let color: Color
        let scale: Int

        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: Constants.progressBarCorner)
                        .fill(color.opacity(.veryMinimalOpacity))

                    let progressWidth = max(
                        0,
                        min((CGFloat(scale) / 100) * geometry.size.width, geometry.size.width)
                    )

                    RoundedRectangle(cornerRadius: Constants.progressBarCorner)
                        .fill(color)
                        .frame(width: progressWidth)
                        .padding(Constants.progressBarInset)
                }
            }
            .frame(height: Constants.progressBarHeight)
        }
    }

    private enum Constants {
        static let progressBarHeight: CGFloat = 15
        static let progressBarCorner: CGFloat = .cornerRadius22
        static let progressBarInset: CGFloat = 2
    }
}

#Preview {
    HeartWorkoutSummaryBreakdownWidget(
        data: HeartDemoData.workout.breakdown ?? HeartWorkoutSummaryBreakdownData()
    )
    .padding(.spacing3x)
    .background(Color.sheetBackground)
}
