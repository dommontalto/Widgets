//
//  ExerciseDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

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

struct ExerciseScores {
    let recovery: Int
    let fatigue: Int
    let readiness: Int
}

struct ExerciseMuscleGroup {
    let name: String
    let sets: Int
    let status: String
}

struct ExerciseSession: Identifiable {
    let id = UUID()
    let name: String
    let timestamp: String
    let type: ExerciseDayType
    let summary: String
    let detail: ExerciseSessionDetail
    var hasRoute = false
}

struct ExerciseSessionGoal {
    let icon: String
    var iconColor: Color = .textColor
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

struct ExerciseProgramStatus {
    let mesocycleWeek: Int
    let mesocycleLength: Int
    let macroLabel: String
    let macroProgress: Double
    let mesoCount: Int
    let mesoCompleted: Int
    let mesoCurrentProgress: Double
    let microWeeks: Int
    let microDaysPerWeek: Int
    let microCompletedDays: Int
    let note: String
    let bullets: [String]
}

struct ExerciseIntervalSegment: Identifiable {
    enum Kind {
        case work
        case rest

        var color: Color {
            switch self {
            case .work: .defaultBrightGreen
            case .rest: .defaultSkyBlue
            }
        }
    }

    let id = UUID()
    /// Relative share of the interval strip; normalised against the other segments.
    let weight: Double
    let kind: Kind
}

struct ExerciseLiveSession {
    let icon: String
    let distance: String
    let timeElapsed: String
    let averagePace: String
    let splitPace: String
    let sectionNumber: Int
    let sectionRemaining: String
    let segments: [ExerciseIntervalSegment]
    /// Position along the full interval strip, gaps included.
    let progress: Double
    let currentIntervalName: String
    let currentIntervalKind: ExerciseIntervalSegment.Kind

    var currentIntervalColor: Color { currentIntervalKind.color }
}

enum ExerciseDemoData {
    static let liveSession = ExerciseLiveSession(
        icon: "figure.run",
        distance: "5.25 KM",
        timeElapsed: "29:34:18",
        averagePace: "5\u{2019}38",
        splitPace: "5\u{2019}26",
        sectionNumber: 2,
        sectionRemaining: "43 SEC",
        segments: [
            ExerciseIntervalSegment(weight: 68, kind: .rest),
            ExerciseIntervalSegment(weight: 160, kind: .work),
            ExerciseIntervalSegment(weight: 26, kind: .rest),
            ExerciseIntervalSegment(weight: 91, kind: .work),
        ],
        progress: 0.596,
        currentIntervalName: "RUN",
        currentIntervalKind: .work
    )

    static let programStatus = ExerciseProgramStatus(
        mesocycleWeek: 2,
        mesocycleLength: 4,
        macroLabel: "24 weeks",
        macroProgress: 0.31,
        mesoCount: 4,
        mesoCompleted: 1,
        mesoCurrentProgress: 0.25,
        microWeeks: 4,
        microDaysPerWeek: 7,
        microCompletedDays: 9,
        note: "We\u{2019}re ramping up your training intensity this week.",
        bullets: ["+ 1km to your run.", "Increasing weights in gym sessions."]
    )

    static let scores = ExerciseScores(recovery: 92, fatigue: 34, readiness: 84)

    static let muscleGroups = [
        ExerciseMuscleGroup(name: "Shoulders", sets: 5, status: "Optimal"),
        ExerciseMuscleGroup(name: "Chest", sets: 5, status: "Low"),
        ExerciseMuscleGroup(name: "Back", sets: 8, status: "High"),
        ExerciseMuscleGroup(name: "Arms", sets: 12, status: "Optimal"),
        ExerciseMuscleGroup(name: "Core", sets: 3, status: "Optimal"),
        ExerciseMuscleGroup(name: "Legs", sets: 10, status: "Optimal"),
    ]

    static let upcomingSessions = [
        ExerciseUpcomingSession(
            name: "Gym session",
            time: "6:00 - 7:00 PM",
            type: .strength,
            goals: [
                ExerciseSessionGoal(icon: "text.append", iconColor: .defaultGreen, label: "Total sets", value: "20"),
                ExerciseSessionGoal(icon: "text.line.first.and.arrowtriangle.forward", iconColor: .defaultOrange, label: "Target RPE", value: "8"),
            ],
            note: "Based off your recovery and sleep, we recommend adjusting a lower RPE today."
        ),
        ExerciseUpcomingSession(
            name: "5K Run",
            time: "8:30 - 9:00 PM",
            type: .cardio,
            goals: [
                ExerciseSessionGoal(icon: "clock", iconColor: .defaultSkyBlue, label: "Pace", value: "4\u{2019}26"),
                ExerciseSessionGoal(icon: "arrow.up.heart", iconColor: .defaultWarningRed, label: "Zone", value: "3"),
            ],
            note: "Based off your recovery and sleep, we recommend adjusting for a slower run."
        ),
    ]

    static let strengthDetail = ExerciseSessionDetail(
        stats: [
            ExerciseSessionStat(label: "Duration", value: "58:24"),
            ExerciseSessionStat(label: "Volume", value: "12,480", unit: "kg"),
            ExerciseSessionStat(label: "Total sets", value: "21"),
            ExerciseSessionStat(label: "Records", value: "2", unit: "PRs"),
            ExerciseSessionStat(label: "Avg heart rate", value: "121", unit: "bpm"),
            ExerciseSessionStat(label: "Calories", value: "412", unit: "kcal"),
        ],
        exercises: [
            ExerciseLoggedExercise(name: "Bench Press (Barbell)", sets: [
                ExerciseLoggedSet(weight: "60", reps: "12"),
                ExerciseLoggedSet(weight: "80", reps: "10"),
                ExerciseLoggedSet(weight: "90", reps: "8"),
                ExerciseLoggedSet(weight: "100", reps: "5", isRecord: true),
            ]),
            ExerciseLoggedExercise(name: "Incline Press (Dumbbell)", sets: [
                ExerciseLoggedSet(weight: "26", reps: "12"),
                ExerciseLoggedSet(weight: "30", reps: "10"),
                ExerciseLoggedSet(weight: "30", reps: "9"),
            ]),
            ExerciseLoggedExercise(name: "Seated Row (Cable)", sets: [
                ExerciseLoggedSet(weight: "55", reps: "12"),
                ExerciseLoggedSet(weight: "65", reps: "10"),
                ExerciseLoggedSet(weight: "70", reps: "10"),
                ExerciseLoggedSet(weight: "75", reps: "8"),
            ]),
            ExerciseLoggedExercise(name: "Lat Pulldown (Cable)", sets: [
                ExerciseLoggedSet(weight: "60", reps: "12"),
                ExerciseLoggedSet(weight: "65", reps: "10"),
                ExerciseLoggedSet(weight: "70", reps: "8"),
            ]),
            ExerciseLoggedExercise(name: "Bicep Curl (EZ-Bar)", sets: [
                ExerciseLoggedSet(weight: "30", reps: "12"),
                ExerciseLoggedSet(weight: "35", reps: "10"),
                ExerciseLoggedSet(weight: "40", reps: "8", isRecord: true),
            ]),
        ],
        splits: [],
        note: "Push volume is up 8% on your last mesocycle. Bench press hit a new 5-rep max."
    )

    static let cardioDetail = ExerciseSessionDetail(
        stats: [
            ExerciseSessionStat(label: "Distance", value: "5.02", unit: "km"),
            ExerciseSessionStat(label: "Time", value: "24:56"),
            ExerciseSessionStat(label: "Avg pace", value: "4\u{2019}58\u{201D}", unit: "/km"),
            ExerciseSessionStat(label: "Avg heart rate", value: "158", unit: "bpm"),
            ExerciseSessionStat(label: "Elevation", value: "42", unit: "m"),
            ExerciseSessionStat(label: "Calories", value: "386", unit: "kcal"),
        ],
        exercises: [],
        splits: [
            ExerciseSplit(label: "1", pace: "5\u{2019}12\u{201D}", paceFraction: 0.78, heartRate: 148, elevation: "+4 m"),
            ExerciseSplit(label: "2", pace: "5\u{2019}02\u{201D}", paceFraction: 0.84, heartRate: 154, elevation: "+9 m"),
            ExerciseSplit(label: "3", pace: "4\u{2019}58\u{201D}", paceFraction: 0.87, heartRate: 159, elevation: "-2 m"),
            ExerciseSplit(label: "4", pace: "4\u{2019}51\u{201D}", paceFraction: 0.93, heartRate: 162, elevation: "+6 m"),
            ExerciseSplit(label: "5", pace: "4\u{2019}46\u{201D}", paceFraction: 1.0, heartRate: 166, elevation: "-3 m"),
        ],
        note: "Negative splits across the full 5K. Pacing control is improving week on week."
    )

    static let sessionHistory = [
        ExerciseSession(name: "Push day", timestamp: "6:00 PM, 23 Jul", type: .strength, summary: "58:24 • 12,480 kg • 21 sets", detail: strengthDetail),
        ExerciseSession(name: "5K run", timestamp: "6:40 AM, 22 Jul", type: .cardio, summary: "5.02 km • 4’58” /km", detail: cardioDetail, hasRoute: true),
        ExerciseSession(name: "Pull day", timestamp: "6:10 PM, 21 Jul", type: .strength, summary: "52:10 • 11,160 kg • 19 sets", detail: strengthDetail),
        ExerciseSession(name: "Tempo run", timestamp: "7:05 AM, 19 Jul", type: .cardio, summary: "6.10 km • 4’41” /km", detail: cardioDetail, hasRoute: true),
        ExerciseSession(name: "Leg day", timestamp: "5:45 PM, 18 Jul", type: .strength, summary: "61:33 • 14,820 kg • 22 sets", detail: strengthDetail),
        ExerciseSession(name: "Recovery run", timestamp: "6:30 AM, 17 Jul", type: .cardio, summary: "4.00 km • 5’42” /km", detail: cardioDetail, hasRoute: true),
        ExerciseSession(name: "Push day", timestamp: "6:05 PM, 15 Jul", type: .strength, summary: "55:40 • 12,120 kg • 20 sets", detail: strengthDetail),
        ExerciseSession(name: "Interval run", timestamp: "6:35 AM, 14 Jul", type: .cardio, summary: "6 × 400m • 3’58” /km", detail: cardioDetail, hasRoute: true),
        ExerciseSession(name: "Pull day", timestamp: "6:15 PM, 12 Jul", type: .strength, summary: "50:22 • 10,940 kg • 18 sets", detail: strengthDetail),
        ExerciseSession(name: "Long run", timestamp: "7:10 AM, 11 Jul", type: .cardio, summary: "12.4 km • 5’18” /km", detail: cardioDetail, hasRoute: true),
        ExerciseSession(name: "Leg day", timestamp: "5:50 PM, 9 Jul", type: .strength, summary: "63:05 • 15,110 kg • 23 sets", detail: strengthDetail),
        ExerciseSession(name: "Recovery run", timestamp: "6:25 AM, 8 Jul", type: .cardio, summary: "4.20 km • 5’38” /km", detail: cardioDetail, hasRoute: true),
        ExerciseSession(name: "Full body", timestamp: "6:00 PM, 5 Jul", type: .strength, summary: "48:15 • 9,860 kg • 16 sets", detail: strengthDetail),
        ExerciseSession(name: "Tempo run", timestamp: "7:00 AM, 3 Jul", type: .cardio, summary: "8.00 km • 4’35” /km", detail: cardioDetail, hasRoute: true),
        ExerciseSession(name: "Push day", timestamp: "6:10 PM, 1 Jul", type: .strength, summary: "57:48 • 12,300 kg • 21 sets", detail: strengthDetail),
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
