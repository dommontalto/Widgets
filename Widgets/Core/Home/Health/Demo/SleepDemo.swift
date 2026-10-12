//
//  SleepDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

extension HealthWidgetDemoV5 {
    // Last night's time in each stage, totalled from the stages below. The captions are
    // written out until the date-format file has a duration style.
    static var sleepRings: [BrightRingGroupWidgetV5.Ring] {
        [
            .init(label: "Awake", shortLabel: "A", value: minutes(in: .awake), goal: sleepMinutes, color: .defaultOrange, caption: "1h 22m"),
            .init(label: "REM", shortLabel: "R", value: minutes(in: .rem), goal: sleepMinutes, color: .defaultCyan, caption: "2h 27m"),
            .init(label: "Core", shortLabel: "C", value: minutes(in: .core), goal: sleepMinutes, color: .defaultSkyBlue, caption: "2h 55m"),
            .init(label: "Deep", shortLabel: "D", value: minutes(in: .deep), goal: sleepMinutes, color: .defaultBrightViolet, caption: "2h 2m"),
        ]
    }

    static func sleepStageRing(_ stage: HealthSleepStageV5) -> BrightRingGroupWidgetV5.Ring {
        var ring = sleepRings[HealthSleepStageV5.allCases.firstIndex(of: stage) ?? 0]
        ring.isDuration = true
        ring.heldText = sleepStageShare(stage)
        return ring
    }

    static func sleepStageBar(_ stage: HealthSleepStageV5) -> BrightHorizontalBarChartWidgetV5.Bar {
        let ring = sleepStageRing(stage)
        var stageBar = bar(ring, systemImage: "bed.double.fill", reading: ring.caption, goalReading: "100%")
        stageBar.heldReading = "\(Int((ring.progress * 100).rounded()))%"
        stageBar.heldUnit = "of the night"
        return stageBar
    }

    static func sleepStageShare(_ stage: HealthSleepStageV5) -> String {
        let ring = sleepRings[HealthSleepStageV5.allCases.firstIndex(of: stage) ?? 0]
        return "\(Int((ring.progress * 100).rounded()))% of the night"
    }

    static let sleepScore = 82
    static let sleepRestingHeartRate = 56
    static let sleepHeartRateVariability = 34

    static var sleepAsleepMinutes: Int {
        Int(minutes(in: .rem) + minutes(in: .core) + minutes(in: .deep))
    }

    static var sleepInBedMinutes: Int {
        Int(sleepStages.reduce(0) { $0 + $1.1 })
    }

    // Last night's stages from a 10:45 PM bedtime, each lasting this many minutes.
    static var sleepSegments: [BrightSleepWidgetV5.Segment] {
        let bedtime = Calendar.current.startOfDay(for: anchor).addingTimeInterval(-75 * 60)
        return sleepStages.indices.map { index in
            let start = bedtime.addingTimeInterval(sleepStages[..<index].reduce(0) { $0 + $1.1 } * 60)
            return .init(stage: sleepStages[index].0, start: start, end: start.addingTimeInterval(sleepStages[index].1 * 60))
        }
    }

    static let sleepVitalsAppearance = BrightWidgetAppearanceV5(title: "Sleep Vitals", systemImage: "moon.fill", tint: .defaultCyan)

    // Last night's vitals against each one's usual range; temperature ran warm.
    static let sleepVitals: [BrightDottedRangeChartWidgetV5.Measure] = [
        .init(label: "RHR", systemImage: "heart.fill", iconColor: .defaultRed, value: Double(sleepRestingHeartRate), normalRange: 45 ... 62, unit: "BPM"),
        .init(label: "Resp.", systemImage: "lungs.fill", iconColor: .defaultCyan, value: 14.2, normalRange: 12 ... 17, unit: "br/min", decimals: 1),
        .init(label: "Temp.", systemImage: "thermometer.variable", iconColor: .defaultOrange, value: 0.7, normalRange: -0.5 ... 0.5, unit: "°C", decimals: 1, isSigned: true),
        .init(label: "HRV", systemImage: "waveform.path.ecg.rectangle.fill", iconColor: .defaultRed, value: Double(sleepHeartRateVariability), normalRange: 30 ... 70, unit: "ms"),
    ]

    private static let sleepStages: [(BrightSleepWidgetV5.Stage, Double)] = [
        (.awake, 11), (.rem, 26), (.core, 18), (.rem, 6), (.core, 13), (.deep, 53), (.rem, 5), (.awake, 5),
        (.rem, 14), (.core, 18), (.core, 61), (.core, 19), (.awake, 8), (.rem, 27), (.deep, 69), (.rem, 16),
        (.core, 46), (.rem, 6), (.awake, 5), (.rem, 22), (.awake, 3), (.rem, 6), (.awake, 5), (.rem, 6),
        (.awake, 13), (.rem, 13), (.awake, 32),
    ]

    private static var sleepMinutes: Double {
        Double(sleepAsleepMinutes)
    }

    private static func minutes(in stage: BrightSleepWidgetV5.Stage) -> Double {
        sleepStages.filter { $0.0 == stage }.reduce(0) { $0 + $1.1 }
    }
}
