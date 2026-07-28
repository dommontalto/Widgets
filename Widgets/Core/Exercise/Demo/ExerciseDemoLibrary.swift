//
//  ExerciseDemoLibrary.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import SwiftUI

enum ExerciseDemoLibrary {
    static let all: [ExerciseDefinition] = strength + cardio

    static func exercise(named name: String) -> ExerciseDefinition? {
        all.first { $0.name == name }
            ?? all.first { name.hasPrefix($0.name) || $0.name.hasPrefix(name) }
    }

    static let strength: [ExerciseDefinition] = [
        lift("Bench Press", .barbell, .chest, [.triceps, .shoulders], .push, base: 100, steps: [
            "Lie flat with your eyes under the bar and feet planted.",
            "Grip just outside shoulder width and unrack.",
            "Lower the bar to mid-chest with elbows at 45 degrees.",
            "Press back up to lockout without bouncing.",
        ]),
        lift("Incline Press", .dumbbell, .chest, [.shoulders, .triceps], .push, base: 34),
        lift("Decline Press", .barbell, .chest, [.triceps], .push, base: 90),
        lift("Chest Fly", .cable, .chest, [.shoulders], .push, base: 22),
        lift("Chest Press", .machine, .chest, [.triceps], .push, base: 70),
        lift("Push Up", .bodyweight, .chest, [.triceps, .core], .push, base: 30, metric: "Reps"),
        lift("Dips", .bodyweight, .chest, [.triceps, .shoulders], .push, base: 18, metric: "Reps"),
        lift("Overhead Press", .barbell, .shoulders, [.triceps, .core], .push, base: 60, steps: [
            "Stand with the bar at your collarbone, hands just outside shoulders.",
            "Brace your core and squeeze your glutes.",
            "Press straight up, moving your head back out of the path.",
            "Lock out overhead with biceps by your ears.",
        ]),
        lift("Shoulder Press", .dumbbell, .shoulders, [.triceps], .push, base: 28),
        lift("Arnold Press", .dumbbell, .shoulders, [.triceps], .push, base: 24),
        lift("Lateral Raise", .dumbbell, .shoulders, [], .push, base: 14),
        lift("Cable Lateral Raise", .cable, .shoulders, [], .push, base: 10),
        lift("Front Raise", .dumbbell, .shoulders, [], .push, base: 12),
        lift("Rear Delt Fly", .machine, .shoulders, [.back], .pull, base: 40),
        lift("Face Pull", .cable, .shoulders, [.back], .pull, base: 28),
        lift("Deadlift", .barbell, .back, [.hamstrings, .glutes, .forearms], .pull, base: 160, steps: [
            "Stand with the bar over mid-foot, shins an inch away.",
            "Hinge down and grip just outside your legs.",
            "Flatten your back and pull slack out of the bar.",
            "Drive the floor away and stand tall, bar close to your body.",
            "Hinge back down under control.",
        ]),
        lift("Romanian Deadlift", .barbell, .hamstrings, [.glutes, .back], .legs, base: 110),
        lift("Bent Over Row", .barbell, .back, [.biceps, .forearms], .pull, base: 85),
        lift("Single Arm Row", .dumbbell, .back, [.biceps], .pull, base: 38),
        lift("Seated Row", .cable, .back, [.biceps], .pull, base: 75),
        lift("Lat Pulldown", .cable, .back, [.biceps], .pull, base: 70),
        lift("Pull Up", .bodyweight, .back, [.biceps, .core], .pull, base: 12, metric: "Reps"),
        lift("Chin Up", .bodyweight, .back, [.biceps], .pull, base: 10, metric: "Reps"),
        lift("T-Bar Row", .machine, .back, [.biceps], .pull, base: 65),
        lift("Straight Arm Pulldown", .cable, .back, [.core], .pull, base: 32),
        lift("Shrug", .dumbbell, .back, [.forearms], .pull, base: 40),
        lift("Bicep Curl", .ezBarStandIn, .biceps, [.forearms], .pull, base: 40),
        lift("Hammer Curl", .dumbbell, .biceps, [.forearms], .pull, base: 18),
        lift("Incline Curl", .dumbbell, .biceps, [], .pull, base: 14),
        lift("Cable Curl", .cable, .biceps, [.forearms], .pull, base: 30),
        lift("Preacher Curl", .machine, .biceps, [], .pull, base: 35),
        lift("Tricep Pushdown", .cable, .triceps, [], .push, base: 35),
        lift("Overhead Extension", .cable, .triceps, [], .push, base: 26),
        lift("Skull Crusher", .ezBarStandIn, .triceps, [], .push, base: 32),
        lift("Close Grip Bench", .barbell, .triceps, [.chest], .push, base: 80),
        lift("Wrist Curl", .dumbbell, .forearms, [], .pull, base: 12),
        lift("Squat", .barbell, .quads, [.glutes, .hamstrings, .core], .legs, base: 140, steps: [
            "Set the bar on your upper back and stand out of the rack.",
            "Set your stance shoulder width, toes slightly out.",
            "Brace, sit down between your hips to below parallel.",
            "Drive up, keeping knees tracking over toes.",
        ]),
        lift("Front Squat", .barbell, .quads, [.core, .glutes], .legs, base: 100),
        lift("Goblet Squat", .kettlebell, .quads, [.glutes, .core], .legs, base: 32),
        lift("Leg Press", .machine, .quads, [.glutes], .legs, base: 220),
        lift("Hack Squat", .machine, .quads, [.glutes], .legs, base: 130),
        lift("Bulgarian Split Squat", .dumbbell, .quads, [.glutes], .legs, base: 24),
        lift("Walking Lunge", .dumbbell, .quads, [.glutes, .hamstrings], .legs, base: 20),
        lift("Leg Extension", .machine, .quads, [], .legs, base: 60),
        lift("Leg Curl", .machine, .hamstrings, [], .legs, base: 50),
        lift("Nordic Curl", .bodyweight, .hamstrings, [.core], .legs, base: 8, metric: "Reps"),
        lift("Hip Thrust", .barbell, .glutes, [.hamstrings], .legs, base: 150),
        lift("Glute Kickback", .cable, .glutes, [], .legs, base: 20),
        lift("Hip Abduction", .machine, .glutes, [], .legs, base: 55),
        lift("Calf Raise", .machine, .calves, [], .legs, base: 90),
        lift("Seated Calf Raise", .machine, .calves, [], .legs, base: 60),
        lift("Good Morning", .barbell, .hamstrings, [.back, .glutes], .legs, base: 60),
        lift("Kettlebell Swing", .kettlebell, .glutes, [.hamstrings, .core], .legs, base: 24),
        lift("Plank", .bodyweight, .core, [.shoulders], .core, base: 120, metric: "Seconds"),
        lift("Side Plank", .bodyweight, .core, [], .core, base: 75, metric: "Seconds"),
        lift("Hanging Leg Raise", .bodyweight, .core, [.forearms], .core, base: 15, metric: "Reps"),
        lift("Cable Crunch", .cable, .core, [], .core, base: 45),
        lift("Ab Wheel Rollout", .bodyweight, .core, [.shoulders], .core, base: 12, metric: "Reps"),
        lift("Russian Twist", .kettlebell, .core, [], .core, base: 12),
        lift("Dead Bug", .bodyweight, .core, [], .core, base: 20, metric: "Reps"),
        lift("Pallof Press", .band, .core, [.shoulders], .core, base: 15, metric: "Reps"),
        lift("Back Extension", .bodyweight, .back, [.glutes, .hamstrings], .core, base: 18, metric: "Reps"),
        lift("Farmer Carry", .kettlebell, .forearms, [.core, .fullBody], .core, base: 32),
    ]

    static let cardio: [ExerciseDefinition] = [
        run("Outdoor Run", best: "4\u{2019}46\u{201D} /km", longest: "12.4 km", base: 298),
        run("Tempo Run", best: "4\u{2019}22\u{201D} /km", longest: "8.0 km", base: 272),
        run("Interval Run", best: "3\u{2019}58\u{201D} /km", longest: "6.0 km", base: 248),
        run("Treadmill Run", best: "5\u{2019}05\u{201D} /km", longest: "10.0 km", base: 315),
        cardioEntry("Cycle", symbolName: "figure.outdoor.cycle", best: "28.4 km/h avg", longest: "46 km", base: 210, metricLabel: "Avg speed"),
        cardioEntry("Row", symbolName: "figure.rower", best: "1\u{2019}52\u{201D} /500m", longest: "8,000 m", base: 118, metricLabel: "Split"),
        cardioEntry("Swim", symbolName: "figure.pool.swim", best: "1\u{2019}58\u{201D} /100m", longest: "2,000 m", base: 124, metricLabel: "Pace"),
        cardioEntry("Hike", symbolName: "figure.hiking", best: "620 m gain", longest: "16 km", base: 400, metricLabel: "Elevation"),
        cardioEntry("Walk", symbolName: "figure.walk", best: "8\u{2019}40\u{201D} /km", longest: "11 km", base: 540, metricLabel: "Pace"),
    ]

    private static func lift(
        _ name: String,
        _ equipment: ExerciseEquipment,
        _ primary: ExerciseMuscle,
        _ secondary: [ExerciseMuscle],
        _ category: ExerciseLibraryCategory,
        base: Double,
        metric: String = "kg",
        steps: [String]? = nil
    ) -> ExerciseDefinition {
        let isWeight = metric == "kg"
        let oneRepMax = base * 1.12
        return ExerciseDefinition(
            name: name,
            equipment: equipment,
            primaryMuscle: primary,
            secondaryMuscles: secondary,
            category: category,
            instructions: steps ?? defaultSteps(for: category, equipment: equipment),
            records: isWeight
                ? [
                    ExerciseSessionStat(label: "Est 1RM", value: format(oneRepMax), unit: "kg"),
                    ExerciseSessionStat(label: "Best set", value: "\(format(base)) \u{00D7} 5"),
                    ExerciseSessionStat(label: "Best volume", value: format(base * 42), unit: "kg"),
                    ExerciseSessionStat(label: "Sessions", value: "\(sessionsCount(for: name))"),
                ]
                : [
                    ExerciseSessionStat(label: "Best", value: format(base), unit: metric.lowercased()),
                    ExerciseSessionStat(label: "Best set", value: "\(format(base * 0.9)) \(metric.lowercased())"),
                    ExerciseSessionStat(label: "Total \(metric.lowercased())", value: format(base * 38)),
                    ExerciseSessionStat(label: "Sessions", value: "\(sessionsCount(for: name))"),
                ],
            history: demoHistory(base: base, unit: isWeight ? "kg" : metric.lowercased()),
            progression: progressionSeries(base: base, seed: name.count),
            progressionMetric: isWeight ? "Est 1RM (kg)" : metric
        )
    }

    private static func run(_ name: String, best: String, longest: String, base: Double) -> ExerciseDefinition {
        cardioEntry(name, symbolName: "figure.run", best: best, longest: longest, base: base, metricLabel: "Pace")
    }

    private static func cardioEntry(
        _ name: String,
        symbolName _: String,
        best: String,
        longest: String,
        base: Double,
        metricLabel: String
    ) -> ExerciseDefinition {
        ExerciseDefinition(
            name: name,
            equipment: .bodyweight,
            primaryMuscle: .fullBody,
            secondaryMuscles: [.quads, .calves],
            category: .cardio,
            instructions: [
                "Warm up easy for 5\u{2013}10 minutes before working effort.",
                "Hold the target effort or pace for the main block.",
                "Keep cadence relaxed and breathing rhythmic.",
                "Cool down easy and stretch after finishing.",
            ],
            records: [
                ExerciseSessionStat(label: "Best \(metricLabel.lowercased())", value: best),
                ExerciseSessionStat(label: "Longest", value: longest),
                ExerciseSessionStat(label: "Avg HR", value: "156", unit: "bpm"),
                ExerciseSessionStat(label: "Sessions", value: "\(sessionsCount(for: name))"),
            ],
            history: [
                ExerciseHistoryEntry(date: "22 Jul", summary: "5.02 km \u{2022} 24:56", bestSet: "Best km 4\u{2019}46\u{201D}"),
                ExerciseHistoryEntry(date: "19 Jul", summary: "6.10 km \u{2022} 28:35", bestSet: "Best km 4\u{2019}31\u{201D}"),
                ExerciseHistoryEntry(date: "17 Jul", summary: "4.00 km \u{2022} 22:48", bestSet: "Best km 5\u{2019}22\u{201D}"),
            ],
            progression: progressionSeries(base: base, seed: name.count, improving: false),
            progressionMetric: "\(metricLabel) (sec)"
        )
    }

    private static func defaultSteps(for category: ExerciseLibraryCategory, equipment: ExerciseEquipment) -> [String] {
        [
            "Set up with the \(equipment.displayName.lowercased()) in a stable position.",
            "Brace your core and set your shoulders before each rep.",
            "Move through the full range under control, 2\u{2013}3s on the way down.",
            "Exhale as you drive through the working portion of the lift.",
        ]
    }

    private static func demoHistory(base: Double, unit: String) -> [ExerciseHistoryEntry] {
        [
            ExerciseHistoryEntry(date: "23 Jul", summary: "4 sets \u{2022} \(format(base * 33)) \(unit)", bestSet: "\(format(base)) \u{00D7} 5"),
            ExerciseHistoryEntry(date: "16 Jul", summary: "4 sets \u{2022} \(format(base * 31)) \(unit)", bestSet: "\(format(base * 0.95)) \u{00D7} 6"),
            ExerciseHistoryEntry(date: "9 Jul", summary: "3 sets \u{2022} \(format(base * 24)) \(unit)", bestSet: "\(format(base * 0.92)) \u{00D7} 6"),
            ExerciseHistoryEntry(date: "2 Jul", summary: "3 sets \u{2022} \(format(base * 23)) \(unit)", bestSet: "\(format(base * 0.9)) \u{00D7} 8"),
        ]
    }

    private static func progressionSeries(base: Double, seed: Int, improving: Bool = true) -> [ExerciseProgressionPoint] {
        (0 ..< 52).map { i in
            let weeksAgo = 51 - i
            let trend = Double(i) / 51 * base * 0.14 * (improving ? 1 : -1)
            let wobble = sin(Double(i + seed) * 0.9) * base * 0.02
            return ExerciseProgressionPoint(id: i, weeksAgo: weeksAgo, value: base * (improving ? 0.88 : 1.14) + trend + wobble)
        }
    }

    private static func sessionsCount(for name: String) -> Int {
        18 + (name.count * 7) % 41
    }

    private static func format(_ value: Double) -> String {
        Int(value.rounded()).formatted(.number.grouping(.automatic))
    }
}

private extension ExerciseEquipment {
    static let ezBarStandIn = ExerciseEquipment.barbell
}
