//
//  BrightWidgetRangeV5.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import Foundation

// The stretch of time a widget shows. Each widget design lists the ones it offers.
enum BrightWidgetRangeV5: String, CaseIterable, Codable, Identifiable {
    case rolling1h
    case rolling6h
    case rolling12h
    case fixed6h
    case fixed12h
    case today
    case week
    case lastNight
    // Just the most recent reading, for widgets that show a single value.
    case latest
    // The last few readings side by side, however far apart they were taken.
    case lastReadings

    static let readingCount = 14

    enum Section: String, CaseIterable {
        case current = "Current"
        case rolling = "Rolling"
        case fixed = "Fixed"
        case calendar = "Calendar"
    }

    var id: Self { self }

    var section: Section {
        switch self {
        case .rolling1h, .rolling6h, .rolling12h: .rolling
        case .fixed6h, .fixed12h: .fixed
        case .today, .week, .lastNight: .calendar
        case .latest, .lastReadings: .current
        }
    }

    // Shown on the widget sheet, under its section's header.
    var rowTitle: String {
        switch self {
        case .today: "Today"
        case .week: "This week"
        case .lastNight: "Last night"
        case .latest: "Latest reading"
        case .lastReadings: "Past \(Self.readingCount) readings"
        default: hours == 1 ? "1 hour" : "\(hours) hours"
        }
    }

    var isRolling: Bool {
        section == .rolling
    }

    var isWeek: Bool {
        self == .week
    }

    var duration: TimeInterval {
        Double(hours) * 60 * 60
    }

    // Longer hourly ranges average a line's readings into buckets so it keeps
    // roughly the same detail as the hour does.
    var bucket: TimeInterval? {
        switch hours {
        case 6: 5 * 60
        case 12, 24: 10 * 60
        default: nil
        }
    }

    // A dot every 10 minutes for the hour, otherwise one an hour.
    var tickCount: Int {
        self == .rolling1h ? 7 : hours + 1
    }

    // A bar an hour, or a bar a day for the week.
    var slotCount: Int {
        isWeek ? 7 : max(hours, 1)
    }

    // Rolling ranges end now. Fixed ones step forward by half their length on the clock,
    // so the left half is always a complete block and the right half fills in until the
    // next step. Today and the week run from midnight and from Monday.
    func interval(endingAt latest: Date) -> DateInterval {
        let calendar = Calendar.current
        switch section {
        case .rolling, .current:
            return DateInterval(start: latest.addingTimeInterval(-duration), duration: duration)
        case .fixed:
            let step = duration / 2
            let midnight = calendar.startOfDay(for: latest)
            let blockStart = midnight.addingTimeInterval((latest.timeIntervalSince(midnight) / step).rounded(.down) * step)
            return DateInterval(start: blockStart.addingTimeInterval(-step), duration: duration)
        case .calendar:
            var mondayFirst = calendar
            mondayFirst.firstWeekday = 2
            let start = isWeek
                ? mondayFirst.dateInterval(of: .weekOfYear, for: latest)?.start ?? latest
                : calendar.startOfDay(for: latest)
            return DateInterval(start: start, duration: duration)
        }
    }

    // Rolling ranges count back from now; the rest name the hours they start and halve at.
    func labels(for interval: DateInterval) -> (leading: String, trailing: String) {
        if isRolling {
            return (hours == 1 ? "60m ago" : "\(hours)h ago", "Now")
        }
        let midpoint = interval.start.addingTimeInterval(duration / 2)
        return (interval.start.formatted(.brightHour), midpoint.formatted(.brightHour))
    }

    private var hours: Int {
        switch self {
        case .rolling1h: 1
        case .rolling6h, .fixed6h: 6
        case .rolling12h, .fixed12h: 12
        case .latest, .lastReadings: 1
        case .today, .lastNight: 24
        case .week: 7 * 24
        }
    }
}
