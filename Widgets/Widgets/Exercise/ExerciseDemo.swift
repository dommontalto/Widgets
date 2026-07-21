//
//  ExerciseDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import Foundation

enum ExerciseDayType: CaseIterable {
    case strength
    case cardio
    case both
    case rest
}

struct ExerciseMonthData {
    let name: String
    /// Week columns of 7 weekday slots (Monday first); nil = day outside this month.
    let columns: [[ExerciseDayType?]]
}

struct ExerciseWeekLoad {
    let name: String
    /// Fractions of the row's bar track, so the pair leaves a gap where they meet.
    let strengthFraction: CGFloat
    let cardioFraction: CGFloat
    let ratio: String
}

struct ExerciseTrainingLoad {
    let strengthPercent: Int
    let cardioPercent: Int
    let weeks: [ExerciseWeekLoad]
}

struct ExerciseSession {
    let name: String
    let timestamp: String
}

struct ExerciseSessionGoal {
    let icon: String
    let label: String
    let value: String
}

struct ExerciseUpcomingSession {
    let name: String
    let time: String
    let type: ExerciseDayType
    let goals: [ExerciseSessionGoal]
    let note: String
}

enum ExerciseDemoData {
    static let upcomingSessions = [
        ExerciseUpcomingSession(
            name: "Gym session",
            time: "6:00 - 7:00 PM",
            type: .strength,
            goals: [
                ExerciseSessionGoal(icon: "square.stack.3d.up", label: "Total sets:", value: "20"),
                ExerciseSessionGoal(icon: "gauge.with.needle", label: "Target RPE", value: "8"),
            ],
            note: "Based off your recovery and sleep, we recommend adjusting a lower RPE today."
        ),
        ExerciseUpcomingSession(
            name: "5K Run",
            time: "8:30 - 9:00 PM",
            type: .cardio,
            goals: [
                ExerciseSessionGoal(icon: "clock", label: "Pace:", value: "4\u{2019}26"),
                ExerciseSessionGoal(icon: "arrow.up.heart", label: "Zone:", value: "3"),
            ],
            note: "Based off your recovery and sleep, we recommend adjusting for a slower run."
        ),
    ]

    static let sessionHistory = [
        ExerciseSession(name: "Gym session", timestamp: "6:00 PM, 18 Jul, 2026"),
        ExerciseSession(name: "Outdoor run", timestamp: "4:40 PM, 17 Jul, 2026"),
        ExerciseSession(name: "Gym session", timestamp: "6:00 PM, 18 Jul, 2026"),
        ExerciseSession(name: "Outdoor run", timestamp: "4:40 PM, 17 Jul, 2026"),
        ExerciseSession(name: "Gym session", timestamp: "6:00 PM, 18 Jul, 2026"),
        ExerciseSession(name: "Outdoor run", timestamp: "4:40 PM, 17 Jul, 2026"),
    ]

    static let trainingLoad = ExerciseTrainingLoad(
        strengthPercent: 45,
        cardioPercent: 55,
        weeks: [
            ExerciseWeekLoad(name: "Week 1", strengthFraction: 0.35, cardioFraction: 0.63, ratio: "40/60"),
            ExerciseWeekLoad(name: "Week 2", strengthFraction: 0.47, cardioFraction: 0.51, ratio: "40/60"),
            ExerciseWeekLoad(name: "Week 3", strengthFraction: 0.20, cardioFraction: 0.78, ratio: "40/60"),
            ExerciseWeekLoad(name: "Week 4", strengthFraction: 0.58, cardioFraction: 0.40, ratio: "40/60"),
        ]
    )

    static func consistencyMonths(trainedThroughDay: Int = 45) -> [ExerciseMonthData] {
        // Rest appears twice so untrained days stay common in the demo mix
        let weighted: [ExerciseDayType] = [.strength, .strength, .cardio, .both, .rest, .rest]
        // (name, weekday of the 1st with Monday = 0, day count) for Jan–Mar 2026
        let months = [("Jan", 3, 31), ("Feb", 6, 28), ("Mar", 6, 31)]

        var dayIndex = 0
        return months.map { name, offset, dayCount in
            var days: [ExerciseDayType?] = Array(repeating: nil, count: offset)
            for _ in 0..<dayCount {
                dayIndex += 1
                days.append(dayIndex <= trainedThroughDay ? weighted.randomElement()! : .rest)
            }
            let columns = stride(from: 0, to: days.count, by: 7).map { start in
                var column = Array(days[start..<min(start + 7, days.count)])
                column.append(contentsOf: Array(repeating: ExerciseDayType?.none, count: 7 - column.count))
                return column
            }
            return ExerciseMonthData(name: name, columns: columns)
        }
    }
}
