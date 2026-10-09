//
//  MenstrualDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import SwiftUI

extension HealthWidgetDemoV5 {
    // A 34-day cycle, ten days in: period for five, the window from 14 to 19 with
    // ovulation on 18, and the luteal days showing from 27.
    static let menstrualCycle = BrightMenstrualWidgetV5.Cycle(
        length: 34,
        periodLength: 5,
        ovulationWindow: 14 ... 19,
        ovulationDay: 18,
        lutealStart: 27
    )

    static let menstrualToday = 10

    static var daysUntilPeriod: Int {
        menstrualCycle.length - menstrualToday + 1
    }

    static var nextPeriod: Date {
        day(daysUntilPeriod)
    }

    static var menstrualDetails: BrightMenstrualWidgetV5.Details {
        let window = menstrualCycle.ovulationWindow
        let start = day(window.lowerBound - menstrualToday)
        let end = day(window.upperBound - menstrualToday)
        // Within one month the start drops its month: "14 – 19 Oct".
        let sameMonth = Calendar.current.isDate(start, equalTo: end, toGranularity: .month)
        let startText = sameMonth ? start.formatted(.brightDay) : start.formatted(.brightDate)
        return .init(
            ovulationWindow: "\(startText) – \(end.formatted(.brightDate))",
            ovulation: day(menstrualCycle.ovulationDay - menstrualToday).formatted(.brightDate),
            temperatureDeviation: "+0.1",
            restingHeartRate: "56"
        )
    }

    private static func day(_ daysFromToday: Int) -> Date {
        anchor.addingTimeInterval(Double(daysFromToday) * 24 * 60 * 60)
    }
}
