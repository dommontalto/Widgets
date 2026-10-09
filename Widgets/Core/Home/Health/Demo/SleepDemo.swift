//
//  SleepDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

extension HealthWidgetDemoV5 {
    // Last night's stages, each as a share of the time asleep. The captions are written
    // out until the date-format file has a duration style.
    static let sleepRings: [BrightRingGroupWidgetV5.Ring] = [
        .init(label: "Awake", shortLabel: "A", value: 7, goal: sleepMinutes, color: .defaultOrange, caption: "7m"),
        .init(label: "REM", shortLabel: "R", value: 114, goal: sleepMinutes, color: .defaultCyan, caption: "1h 54m"),
        .init(label: "Core", shortLabel: "C", value: 262, goal: sleepMinutes, color: .defaultSkyBlue, caption: "4h 22m"),
        .init(label: "Deep", shortLabel: "D", value: 115, goal: sleepMinutes, color: .defaultBrightViolet, caption: "1h 55m"),
    ]

    static let sleepScore = 82
    static let sleepAsleepMinutes = 8 * 60 + 24
    static let sleepInBedMinutes = 8 * 60 + 45
    static let sleepRestingHeartRate = 46
    static let sleepHeartRateVariability = 76

    // Last night's stages from a 10:45 PM bedtime, each lasting this many minutes.
    static var sleepSegments: [BrightSleepWidgetV5.Segment] {
        let stages: [(BrightSleepWidgetV5.Stage, Double)] = [
            (.awake, 11), (.rem, 26), (.core, 18), (.rem, 6), (.core, 13), (.deep, 53), (.rem, 5), (.awake, 5),
            (.rem, 14), (.core, 18), (.core, 61), (.core, 19), (.awake, 8), (.rem, 27), (.deep, 69), (.rem, 16),
            (.core, 46), (.rem, 6), (.awake, 5), (.rem, 22), (.awake, 3), (.rem, 6), (.awake, 5), (.rem, 6),
            (.awake, 13), (.rem, 13), (.awake, 32),
        ]
        let bedtime = Calendar.current.startOfDay(for: anchor).addingTimeInterval(-75 * 60)
        return stages.indices.map { index in
            let start = bedtime.addingTimeInterval(stages[..<index].reduce(0) { $0 + $1.1 } * 60)
            return .init(stage: stages[index].0, start: start, end: start.addingTimeInterval(stages[index].1 * 60))
        }
    }

    static let sleepVitalsAppearance = BrightWidgetAppearanceV5(title: "Sleep Vitals", systemImage: "moon.fill", tint: .defaultCyan)

    // Last night's vitals against each one's usual range; temperature ran warm.
    static let sleepVitals: [BrightDottedRangeChartWidgetV5.Measure] = [
        .init(label: "RHR", systemImage: "heart.fill", iconColor: .defaultRed, value: 56, normalRange: 45 ... 62, unit: "BPM"),
        .init(label: "Resp.", systemImage: "lungs.fill", iconColor: .defaultCyan, value: 14.2, normalRange: 12 ... 17, unit: "br/min", decimals: 1),
        .init(label: "Temp.", systemImage: "thermometer.variable", iconColor: .defaultOrange, value: 0.7, normalRange: -0.5 ... 0.5, unit: "°C", decimals: 1, isSigned: true),
        .init(label: "HRV", systemImage: "waveform.path.ecg.rectangle.fill", iconColor: .defaultRed, value: 34, normalRange: 30 ... 70, unit: "ms"),
    ]

    private static let sleepMinutes = Double(sleepAsleepMinutes)
}
