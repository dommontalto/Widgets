//
//  SleepDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

extension HealthWidgetDemo {
    // Last night's stages, each as a share of the time asleep. The captions are written
    // out until the date-format file has a duration style.
    static let sleepRings: [BrightRingGroupWidgetV5.Ring] = [
        .init(label: "Awake", shortLabel: "A", value: 7, goal: sleepMinutes, color: .defaultOrange, caption: "7m"),
        .init(label: "REM", shortLabel: "R", value: 114, goal: sleepMinutes, color: .defaultCyan, caption: "1h 54m"),
        .init(label: "Core", shortLabel: "C", value: 262, goal: sleepMinutes, color: .defaultSkyBlue, caption: "4h 22m"),
        .init(label: "Deep", shortLabel: "D", value: 115, goal: sleepMinutes, color: .defaultBrightViolet, caption: "1h 55m"),
    ]

    static let sleepScore = 82

    static let sleepVitalsAppearance = BrightWidgetAppearanceV5(title: "Sleep Vitals", systemImage: "moon.fill", tint: .defaultCyan)

    // Last night's vitals against each one's usual range; temperature ran warm.
    static let sleepVitals: [BrightDottedRangeChartWidgetV5.Measure] = [
        .init(label: "RHR", systemImage: "heart.fill", iconColor: .defaultRed, value: 56, normalRange: 45 ... 62, unit: "BPM"),
        .init(label: "Resp.", systemImage: "lungs.fill", iconColor: .defaultCyan, value: 14.2, normalRange: 12 ... 17, unit: "br/min", decimals: 1),
        .init(label: "Temp.", systemImage: "thermometer.variable", iconColor: .defaultOrange, value: 0.7, normalRange: -0.5 ... 0.5, unit: "°C", decimals: 1, isSigned: true),
        .init(label: "HRV", systemImage: "waveform.path.ecg.rectangle.fill", iconColor: .defaultRed, value: 34, normalRange: 30 ... 70, unit: "ms"),
    ]

    private static let sleepMinutes: Double = 8 * 60 + 24
}

// Time asleep, time in bed, and the night's score.
struct SleepRingsHeader: View {
    var body: some View {
        HStack(spacing: .spacing3x) {
            total(systemImage: "zzz", color: .defaultBrightViolet, hours: 8, minutes: 24)

            total(systemImage: "bed.double", color: .defaultCyan, hours: 8, minutes: 45)

            Spacer(minLength: .spacing0x)

            HStack(alignment: .firstTextBaseline, spacing: .spacing0x) {
                BrightText("\(HealthWidgetDemo.sleepScore)", size: .heading, color: .defaultGreen, weight: .regular)
                    .monospacedDigit()

                BrightText("%", size: .body5, color: .defaultGreen.opacity(.lowOpacity), weight: .regular)
            }
            .padding(.horizontal, .spacing1x)
            .padding(.vertical, .spacing05x)
            .background(Capsule().fill(Color.defaultGreen.opacity(.minimalOpacity)))
        }
        .lineLimit(1)
    }

    private func total(systemImage: String, color: Color, hours: Int, minutes: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
            Image(systemName: systemImage)
                .font(.standard(size: .heading, weight: .light))
                .foregroundStyle(color)

            BrightText("\(hours)", size: .standout3)
            BrightText("hr", size: .body3, color: .lightTextColor)
            BrightText("\(minutes)", size: .standout3)
            BrightText("m", size: .body3, color: .lightTextColor)
        }
    }
}
