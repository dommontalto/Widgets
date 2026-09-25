//
//  LighthouseMenuModels.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

nonisolated struct LighthouseHistoryEntry: Identifiable {
    let id = UUID()
    var title: String
    let when: String
    var isPinned = false
}

nonisolated enum LighthouseCheckInFrequency: String, CaseIterable, Identifiable, Hashable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"

    var id: String { rawValue }
    var title: String { rawValue }
}

nonisolated enum LighthouseWeekday: Int, CaseIterable, Identifiable, Hashable {
    case sunday = 1
    case monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    @MainActor var title: String { date.formatted(.brightWeekdayShort) }

    private var date: Date {
        let calendar = Calendar.autoupdatingCurrent
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        return calendar.date(bySetting: .weekday, value: rawValue, of: weekStart) ?? weekStart
    }
}

nonisolated struct LighthouseCheckIn: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var frequency: LighthouseCheckInFrequency
    var weekday: LighthouseWeekday
    var dayOfMonth: Int
    var time: Date
    var detail: String
    var isOn: Bool
}

nonisolated struct LighthouseConfiguration: Identifiable {
    let id = UUID()
    let title: String
    let created: String
    let widgets: [String]
    var isOn: Bool
}

// One step of a reply's reasoning. `depth` nests it under the step before,
// and the waypoint is the goal the chain arrives at.
nonisolated struct LighthouseThoughtStep: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    // What the model was doing at this step, in its own words.
    let detail: String
    var tint: Color = .semiLightTextColor
    var depth = 0
    var isWaypoint = false
    var isExpandable = false
    var references: [LighthouseThoughtReference] = []
}

nonisolated struct LighthouseThoughtReference: Identifiable {
    let id = UUID()
    let title: String
    let source: String
    let url: URL
}
