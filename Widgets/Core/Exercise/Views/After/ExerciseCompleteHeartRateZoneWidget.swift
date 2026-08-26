//
//  ExerciseCompleteHeartRateZoneWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import SwiftUI

struct ExerciseCompleteHeartRateZoneWidget: View {
    let data: ExerciseBreakdownPayload

    private var zones: [ExerciseBreakdownPayload.Zone] {
        let zones = data.zones ?? []
        return zones.isEmpty ? placeholderZones : zones
    }

    private var placeholderZones: [ExerciseBreakdownPayload.Zone] {
        [
            .init(title: "Zone 1", rangeStr: nil, duration: nil, scaleValue: 0),
            .init(title: "Zone 2", rangeStr: nil, duration: nil, scaleValue: 0),
            .init(title: "Zone 3", rangeStr: nil, duration: nil, scaleValue: 0),
            .init(title: "Zone 4", rangeStr: nil, duration: nil, scaleValue: 0),
            .init(title: "Zone 5", rangeStr: nil, duration: nil, scaleValue: 0),
        ]
    }

    private var isEmptyState: Bool {
        (data.zones ?? []).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightText(
                "Zone Breakdown",
                size: .body1,
                color: .textColor
            )

            ForEach(zones.indices, id: \.self) { index in
                let zone = zones[index]

                VStack(spacing: .spacing1x) {
                    HStack(alignment: .top, spacing: .spacing2x) {
                        BrightText(
                            zone.title ?? "",
                            size: .body1,
                            color: .semiLightTextColor
                        )

                        if !isEmptyState, let rangeStr = zone.rangeStr, !rangeStr.isEmpty {
                            BrightText(
                                "\(rangeStr) BPM",
                                size: .body1,
                                color: .lightTextColor
                            )
                        }

                        Spacer()

                        if !isEmptyState, let durationString = zone.duration?.asString, !durationString.isEmpty {
                            BrightText(
                                durationString,
                                size: .body1,
                                color: .semiLightTextColor
                            )
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
        .modifier(
            CardModifier(color: .defaultSheetModalCards)
        )
    }

    private func zoneColor(for index: Int) -> Color {
        switch index {
        case 0: .defaultBlue
        case 1: .defaultBrightGreen
        case 2: .defaultYellow
        case 3: .defaultOrange
        case 4: .defaultRed
        default: .defaultBlue
        }
    }

    struct ProgressBar: View {
        let color: Color
        let scale: Int

        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(color.opacity(.veryMinimalOpacity))
                        .clipShape(RoundedRectangle(cornerRadius: Constants.progressBarCorner))

                    let progressWidth = max(
                        0,
                        min((CGFloat(scale) / 100) * geometry.size.width, geometry.size.width)
                    )

                    Rectangle()
                        .fill(color)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.progressBarCorner))
                        .frame(width: progressWidth)
                        .padding(2)
                }
            }
            .frame(height: Constants.progressBarHeight)
        }
    }

    private class Constants {
        static let progressBarHeight: CGFloat = 15
        static let progressBarCorner: CGFloat = .cornerRadius22
    }
}

#Preview {
    ExerciseCompleteHeartRateZoneWidget(
        data: ExerciseBreakdownPayload()
    )
}
