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

struct ExerciseSession: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let timestamp: String
    let type: ExerciseDayType
    let summary: String
    let detail: ExerciseSessionDetail
    var hasRoute = false

    static func == (lhs: ExerciseSession, rhs: ExerciseSession) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
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
                ExerciseSessionGoal(icon: "arrow.up.heart", iconColor: .defaultRed, label: "Zone", value: "3"),
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

    // MARK: - Session planner

    static let plannerTemplates: [ExercisePlannedSession] = [
        ExercisePlannedSession(title: "Back & Biceps", subtitle: "10 exercises", kind: .strength),
        ExercisePlannedSession(title: "Chest & Legs", subtitle: "10 exercises", kind: .strength),
        ExercisePlannedSession(title: "Back & Core", subtitle: "6 exercises", kind: .strength),
        ExercisePlannedSession(title: "3K Run", subtitle: "Target: Zone 2", kind: .run),
        ExercisePlannedSession(title: "10K Run", subtitle: "Target: Zone 3", kind: .run),
        ExercisePlannedSession(title: "20K Cycle", subtitle: "Target: Zone 2", kind: .cycle),
        ExercisePlannedSession(title: "Rest Day", subtitle: "", kind: .rest),
    ]

    static var plannerWeek: [ExercisePlanDay] {
        [
            ExercisePlanDay(name: "Mon", sessions: [plannerTemplates[0].duplicated]),
            ExercisePlanDay(name: "Tue", sessions: [plannerTemplates[1].duplicated]),
            ExercisePlanDay(name: "Wed", sessions: [plannerTemplates[6].duplicated]),
            ExercisePlanDay(name: "Thu", sessions: [plannerTemplates[4].duplicated]),
            ExercisePlanDay(name: "Fri", sessions: [plannerTemplates[2].duplicated, plannerTemplates[3].duplicated]),
            ExercisePlanDay(name: "Sat", sessions: [plannerTemplates[6].duplicated]),
            ExercisePlanDay(name: "Sun", sessions: [plannerTemplates[5].duplicated]),
        ]
    }

    static var plannerEmptyWeek: [ExercisePlanDay] {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map {
            ExercisePlanDay(name: $0, sessions: [])
        }
    }

    // MARK: - Exercise detail

    static let detailStats: [ExerciseStatTile] = [
        ExerciseStatTile(label: "Personal Best", value: "120", unit: "KG", symbol: "trophy.fill", color: .defaultYellow),
        ExerciseStatTile(label: "EST. 1RM", value: "120", unit: "KG", symbol: "dial.high.fill", color: .defaultRed),
        ExerciseStatTile(label: "Total Sessions", value: "54", unit: "Sessions", symbol: "text.line.3.summary", color: .defaultGreen),
        ExerciseStatTile(label: "AVG weekly sets", value: "12", unit: "sets", symbol: "chart.line.flattrend.xyaxis", color: .defaultSkyBlue),
    ]

    static let detailProgression: [ExerciseProgressionSample] = (0 ..< 365).map { day in
        let t = Double(day) / 364
        let base = 30 + 50 * t
        let spike = 45 * exp(-pow((t - 0.93) / 0.045, 2))
        let dip = 18 * exp(-pow((t - 0.97) / 0.02, 2))
        let noise = sin(Double(day) * 7.3) * 2.5 + sin(Double(day) * 2.1) * 2 + sin(Double(day) * 0.37) * 3
        return ExerciseProgressionSample(id: day, value: max(5, base + spike - dip + noise))
    }

    static let detailImpact = CycleTrackingImpactData(
        items: [
            CycleTrackingImpactItem(text: "Develops lower body strength", isPositive: true),
            CycleTrackingImpactItem(text: "Increases athletic ability overtime", isPositive: true),
            CycleTrackingImpactItem(text: "Reduce risk of osteoporosis", isPositive: true),
            CycleTrackingImpactItem(text: "Requires good form and technique", isPositive: false),
            CycleTrackingImpactItem(text: "High fatigue exercise", isPositive: false),
        ],
        description: nil
    )

    static let detailHistory: [ExerciseHistorySession] = [
        ExerciseHistorySession(date: "Mon, 18 Jul, 2026", prLabel: "Weight PR", sets: [
            ExerciseHistorySet(label: nil, reps: "6 reps", weight: "60 KG"),
            ExerciseHistorySet(label: "1", reps: "4 reps", weight: "80 KG"),
            ExerciseHistorySet(label: "2", reps: "6 reps", weight: "60 KG"),
            ExerciseHistorySet(label: "3", reps: "4 reps", weight: "80 KG"),
        ]),
        ExerciseHistorySession(date: "Thu, 14 Jul, 2026", sets: [
            ExerciseHistorySet(label: nil, reps: "6 reps", weight: "60 KG"),
            ExerciseHistorySet(label: "1", reps: "4 reps", weight: "80 KG"),
            ExerciseHistorySet(label: "2", reps: "6 reps", weight: "60 KG"),
            ExerciseHistorySet(label: "3", reps: "4 reps", weight: "80 KG"),
        ]),
        ExerciseHistorySession(date: "Mon, 11 Jul, 2026", prLabel: "Rep PR", sets: [
            ExerciseHistorySet(label: nil, reps: "8 reps", weight: "50 KG"),
            ExerciseHistorySet(label: "1", reps: "6 reps", weight: "75 KG"),
            ExerciseHistorySet(label: "2", reps: "6 reps", weight: "75 KG"),
            ExerciseHistorySet(label: "3", reps: "5 reps", weight: "75 KG"),
        ]),
        ExerciseHistorySession(date: "Thu, 7 Jul, 2026", sets: [
            ExerciseHistorySet(label: nil, reps: "6 reps", weight: "50 KG"),
            ExerciseHistorySet(label: "1", reps: "5 reps", weight: "75 KG"),
            ExerciseHistorySet(label: "2", reps: "5 reps", weight: "72.5 KG"),
            ExerciseHistorySet(label: "3", reps: "4 reps", weight: "72.5 KG"),
        ]),
        ExerciseHistorySession(date: "Mon, 4 Jul, 2026", sets: [
            ExerciseHistorySet(label: nil, reps: "6 reps", weight: "50 KG"),
            ExerciseHistorySet(label: "1", reps: "5 reps", weight: "70 KG"),
            ExerciseHistorySet(label: "2", reps: "4 reps", weight: "70 KG"),
            ExerciseHistorySet(label: "3", reps: "4 reps", weight: "70 KG"),
        ]),
    ]

    // MARK: - Live session

    static let activeExercises: [ExerciseActiveExercise] = [
        ExerciseActiveExercise(name: "Bench Press (Barbell)", sets: [
            ExerciseActiveSet(weight: "40", reps: "12", previous: "40 \u{00D7} 12", isWarmup: true, isDone: true),
            ExerciseActiveSet(weight: "80", reps: "10", previous: "77.5 \u{00D7} 10", isDone: true),
            ExerciseActiveSet(weight: "90", reps: "8", previous: "87.5 \u{00D7} 8"),
            ExerciseActiveSet(weight: "100", reps: "5", previous: "97.5 \u{00D7} 5", isRecord: true),
        ]),
        ExerciseActiveExercise(name: "Incline Press (Dumbbell)", sets: [
            ExerciseActiveSet(weight: "26", reps: "12", previous: "26 \u{00D7} 11"),
            ExerciseActiveSet(weight: "30", reps: "10", previous: "30 \u{00D7} 9"),
            ExerciseActiveSet(weight: "30", reps: "9", previous: "30 \u{00D7} 8"),
        ]),
        ExerciseActiveExercise(name: "Seated Row (Cable)", sets: [
            ExerciseActiveSet(weight: "55", reps: "12", previous: "55 \u{00D7} 12"),
            ExerciseActiveSet(weight: "65", reps: "10", previous: "65 \u{00D7} 10"),
            ExerciseActiveSet(weight: "70", reps: "10", previous: "70 \u{00D7} 9"),
        ]),
        ExerciseActiveExercise(name: "Bicep Curl (EZ-Bar)", sets: [
            ExerciseActiveSet(weight: "30", reps: "12", previous: "30 \u{00D7} 12"),
            ExerciseActiveSet(weight: "35", reps: "10", previous: "35 \u{00D7} 10"),
            ExerciseActiveSet(weight: "40", reps: "8", previous: "37.5 \u{00D7} 8", isRecord: true),
        ]),
    ]
}
