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
    // Week columns of 7 weekday slots (Monday first); nil = day outside this month.
    let columns: [[ExerciseDayType?]]
}

struct ExerciseWeekLoad {
    let name: String
    // Fractions of the row's bar track, so the pair leaves a gap where they meet.
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
    let stress: Int
    let strain: Int
}

struct ExerciseMuscleGroup {
    let name: String
    let sets: Int
    let status: String
}

struct ExerciseWorkout: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let timestamp: String
    let type: ExerciseDayType
    let summary: String
    let detail: ExerciseWorkoutDetail
    var hasRoute = false
    // The parts a mixed workout holds, in the order they were logged. Left
    // empty, the workout is the single part its type implies.
    var parts: [ExerciseWorkoutCategory] = []
    // Imported rather than run in the app, so the log marks it as read-only.
    var isFromAppleHealth = false

    static func == (lhs: ExerciseWorkout, rhs: ExerciseWorkout) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ExerciseWorkoutGoal {
    let icon: String
    var iconColor: Color = .textColor
    let label: String
    let value: String
}

struct ExerciseUpcomingWorkout {
    let name: String
    let time: String
    let type: ExerciseDayType
    let goals: [ExerciseWorkoutGoal]
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
            case .work: .defaultGreen
            case .rest: .defaultCyan
            }
        }
    }

    let id = UUID()
    let kind: Kind
}

struct ExerciseLiveWorkout {
    let currentPace: String
    let distance: String
    let heartRate: String
    let heartRateZone: String
    let averagePace: String
    let splitPace: String
    // Signed difference between the split and the average pace, in seconds.
    let splitDelta: String
    let intervalName: String
    let intervalRemaining: String
    let intervalKind: ExerciseIntervalSegment.Kind
    let segments: [ExerciseIntervalSegment]

    var intervalColor: Color { intervalKind.color }
}

enum ExerciseDemoData {
    static let liveWorkout = ExerciseLiveWorkout(
        currentPace: "3\u{2019}23 / KM",
        distance: "5.24 KM",
        heartRate: "136",
        heartRateZone: "Z2",
        averagePace: "5\u{2019}21",
        splitPace: "5\u{2019}19",
        splitDelta: "-2",
        intervalName: "RUN",
        intervalRemaining: "2:49",
        intervalKind: .work,
        segments: [
            ExerciseIntervalSegment(kind: .rest),
            ExerciseIntervalSegment(kind: .work),
            ExerciseIntervalSegment(kind: .rest),
            ExerciseIntervalSegment(kind: .work),
        ]
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
        bullets: ["+ 1km to your run.", "Increasing weights in gym workouts."]
    )

    static let scores = ExerciseScores(recovery: 92, stress: 34, strain: 84)

    static let muscleGroups = [
        ExerciseMuscleGroup(name: "Shoulders", sets: 5, status: "Optimal"),
        ExerciseMuscleGroup(name: "Chest", sets: 5, status: "Low"),
        ExerciseMuscleGroup(name: "Back", sets: 8, status: "High"),
        ExerciseMuscleGroup(name: "Arms", sets: 12, status: "Optimal"),
        ExerciseMuscleGroup(name: "Core", sets: 3, status: "Optimal"),
        ExerciseMuscleGroup(name: "Legs", sets: 10, status: "Optimal"),
    ]

    static let strengthDetail = ExerciseWorkoutDetail(
        tiles: [
            ExerciseStatTile(label: "Personal Best", value: "100", unit: "KG", symbol: "trophy.fill", color: .defaultYellow),
            ExerciseStatTile(label: "EST. 1RM", value: "112", unit: "KG", symbol: "dial.high.fill", color: .defaultRed),
            ExerciseStatTile(label: "Total volume", value: "12,480", unit: "kg", symbol: "text.line.3.summary", color: .defaultGreen),
            ExerciseStatTile(label: "Total sets", value: "21", unit: "sets", symbol: "chart.line.flattrend.xyaxis", color: .defaultSkyBlue),
            ExerciseStatTile(label: "AVG heart rate", value: "121", unit: "bpm", symbol: "heart.fill", color: .defaultRed),
            ExerciseStatTile(label: "Calories", value: "412", unit: "kcal", symbol: "flame.fill", color: .defaultOrange),
        ],
        exercises: [
            ExerciseLoggedExercise(name: "Bench Press (Barbell)", sets: [
                ExerciseLoggedSet(weight: "60", reps: "12", kind: .warmUp),
                ExerciseLoggedSet(weight: "80", reps: "10"),
                ExerciseLoggedSet(weight: "90", reps: "8"),
                ExerciseLoggedSet(weight: "100", reps: "5", isRecord: true),
                ExerciseLoggedSet(weight: "70", reps: "8", kind: .dropSet),
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
                ExerciseLoggedSet(weight: "30", reps: "12", kind: .warmUp),
                ExerciseLoggedSet(weight: "35", reps: "10"),
                ExerciseLoggedSet(weight: "40", reps: "8", isRecord: true),
            ]),
        ],
        splits: [],
        note: "Push volume is up 8% on your last mesocycle. Bench press hit a new 5-rep max."
    )

    static let cardioDetail = ExerciseWorkoutDetail(
        tiles: [
            ExerciseStatTile(label: "Distance", value: "5.02", unit: "km", symbol: "figure.run", color: .defaultSkyBlue),
            ExerciseStatTile(label: "AVG pace", value: "4\u{2019}58\u{201D}", unit: "/km", symbol: "dial.high.fill", color: .defaultRed),
            ExerciseStatTile(label: "Time", value: "24:56", unit: "", symbol: "text.line.3.summary", color: .defaultGreen),
            ExerciseStatTile(label: "Elevation", value: "42", unit: "m", symbol: "chart.line.flattrend.xyaxis", color: .defaultSkyBlue),
            ExerciseStatTile(label: "AVG heart rate", value: "158", unit: "bpm", symbol: "heart.fill", color: .defaultRed),
            ExerciseStatTile(label: "Calories", value: "386", unit: "kcal", symbol: "flame.fill", color: .defaultOrange),
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

    // A run the flow has just finished, for it to hand to the summary. Named
    // parts so the summary's picker shows a lifting leg alongside the run when
    // the session held both.
    static func loggedCardio(name: String, afterStrength: Bool) -> ExerciseWorkout {
        ExerciseWorkout(
            name: name,
            timestamp: "Just now",
            type: afterStrength ? .both : .cardio,
            summary: "5.02 km \u{2022} 4\u{2019}58\u{201D} /km",
            detail: cardioDetail,
            hasRoute: true,
            parts: afterStrength ? [.gym, .cardio] : [.cardio]
        )
    }

    static let workoutHistory = [
        ExerciseWorkout(name: "Push day", timestamp: "6:00 PM, 23 Jul", type: .strength, summary: "58:24 • 12,480 kg • 21 sets", detail: strengthDetail),
        ExerciseWorkout(name: "5K run", timestamp: "6:40 AM, 22 Jul", type: .cardio, summary: "5.02 km • 4’58” /km", detail: cardioDetail, hasRoute: true),
        ExerciseWorkout(name: "Push & run", timestamp: "5:30 PM, 21 Jul", type: .both, summary: "1:12:05 • 9,240 kg • 4.1 km", detail: strengthDetail),
        ExerciseWorkout(name: "Gym, run & footy", timestamp: "4:15 PM, 20 Jul", type: .both, summary: "2:04:18 • 7,900 kg • 3.2 km", detail: strengthDetail, parts: [.gym, .cardio, .sports]),
        ExerciseWorkout(name: "Pull day", timestamp: "6:10 PM, 21 Jul", type: .strength, summary: "52:10 • 11,160 kg • 19 sets", detail: strengthDetail),
        ExerciseWorkout(name: "Functional strength", timestamp: "12:20 PM, 20 Jul", type: .strength, summary: "34:02 • 4,120 kg • 12 sets", detail: strengthDetail, isFromAppleHealth: true),
        ExerciseWorkout(name: "Tempo run", timestamp: "7:05 AM, 19 Jul", type: .cardio, summary: "6.10 km • 4’41” /km", detail: cardioDetail, hasRoute: true),
        ExerciseWorkout(name: "Outdoor walk", timestamp: "1:10 PM, 19 Jul", type: .cardio, summary: "3.40 km • 11’02” /km", detail: cardioDetail, isFromAppleHealth: true),
        ExerciseWorkout(name: "Leg day", timestamp: "5:45 PM, 18 Jul", type: .strength, summary: "61:33 • 14,820 kg • 22 sets", detail: strengthDetail),
        ExerciseWorkout(name: "Recovery run", timestamp: "6:30 AM, 17 Jul", type: .cardio, summary: "4.00 km • 5’42” /km", detail: cardioDetail, hasRoute: true),
        ExerciseWorkout(name: "Push day", timestamp: "6:05 PM, 15 Jul", type: .strength, summary: "55:40 • 12,120 kg • 20 sets", detail: strengthDetail),
        ExerciseWorkout(name: "Interval run", timestamp: "6:35 AM, 14 Jul", type: .cardio, summary: "6 × 400m • 3’58” /km", detail: cardioDetail, hasRoute: true),
        ExerciseWorkout(name: "Pull day", timestamp: "6:15 PM, 12 Jul", type: .strength, summary: "50:22 • 10,940 kg • 18 sets", detail: strengthDetail),
        ExerciseWorkout(name: "Long run", timestamp: "7:10 AM, 11 Jul", type: .cardio, summary: "12.4 km • 5’18” /km", detail: cardioDetail, hasRoute: true),
        ExerciseWorkout(name: "Leg day", timestamp: "5:50 PM, 9 Jul", type: .strength, summary: "63:05 • 15,110 kg • 23 sets", detail: strengthDetail),
        ExerciseWorkout(name: "Recovery run", timestamp: "6:25 AM, 8 Jul", type: .cardio, summary: "4.20 km • 5’38” /km", detail: cardioDetail, hasRoute: true),
        ExerciseWorkout(name: "Full body", timestamp: "6:00 PM, 5 Jul", type: .strength, summary: "48:15 • 9,860 kg • 16 sets", detail: strengthDetail),
        ExerciseWorkout(name: "Tempo run", timestamp: "7:00 AM, 3 Jul", type: .cardio, summary: "8.00 km • 4’35” /km", detail: cardioDetail, hasRoute: true),
        ExerciseWorkout(name: "Push day", timestamp: "6:10 PM, 1 Jul", type: .strength, summary: "57:48 • 12,300 kg • 21 sets", detail: strengthDetail),
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

    // MARK: - Exercise detail

    static let detailStats: [ExerciseStatTile] = [
        ExerciseStatTile(label: "Personal Best", value: "120", unit: "KG", symbol: "trophy.fill", color: .defaultYellow),
        ExerciseStatTile(label: "EST. 1RM", value: "120", unit: "KG", symbol: "dial.high.fill", color: .defaultRed),
        ExerciseStatTile(label: "Total Workouts", value: "54", unit: "Workouts", symbol: "text.line.3.summary", color: .defaultGreen),
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

    static let activeExercises: [ExerciseActiveExercise] = [
        ExerciseActiveExercise(name: "Bench Press (Barbell)", sets: [
            ExerciseActiveSet(weight: "40", reps: "12", previous: "40 \u{00D7} 12", kind: .warmUp, isDone: true),
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
