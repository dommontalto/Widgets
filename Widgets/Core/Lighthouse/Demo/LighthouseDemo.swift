//
//  LighthouseDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

// Hard-coded Lighthouse content — a sleep reply, past chats and check-ins — so
// the screens fill without a backend.
enum LighthouseDemo {
    static let thoughtSteps = [
        LighthouseThoughtStep(
            symbol: "rays",
            title: "Evaluating next steps",
            detail: "You've asked how to get fitter for the football season. Before I answer I'm working out what a good answer needs: your current training, how long the season is, and what fitness means for your position.",
            tint: .defaultOrange
        ),
        LighthouseThoughtStep(
            symbol: "globe",
            title: "Researching effectiveness",
            detail: "I'm checking what the evidence says about pre-season conditioning for amateur footballers, with an eye on programmes that mix strength, repeated sprints and aerobic base work.",
            tint: .defaultBlue
        ),
        LighthouseThoughtStep(
            symbol: "globe",
            title: "Researching effectiveness",
            detail: "Now I'm comparing how much of each quality to train each week, and how recent studies balance intensity against recovery over a six-week block.",
            tint: .defaultBlue
        ),
        LighthouseThoughtStep(
            symbol: "brain",
            title: "Defining Goal",
            detail: "Right now, I'm focusing on your question about getting fit for football. I've pinpointed repeated-sprint ability as the biggest gap between where you are and match fitness. My next step will be to lay out a plan that builds it without dropping your strength work.",
            tint: .defaultPink
        ),
        LighthouseThoughtStep(
            symbol: "filemenu.and.selection",
            title: "Generating Plan",
            detail: "I'm shaping a six-week plan: two strength sessions, two conditioning sessions and one easy run each week, with load rising for three weeks before a lighter one.",
            tint: .defaultGreen,
            depth: 1
        ),
        LighthouseThoughtStep(
            symbol: "figure.strengthtraining.traditional",
            title: "Generating Upper Body workout",
            detail: "I'm writing the upper-body session around pressing, pulling and trunk work, kept short so it doesn't eat into recovery for the running days.",
            tint: .defaultBrightViolet,
            depth: 1
        ),
        LighthouseThoughtStep(
            symbol: "figure.strengthtraining.traditional",
            title: "Generating Lower Body workout",
            detail: "I'm building the lower-body session around squats, hinges and single-leg work, with a plyometric finisher to carry the strength over to sprinting.",
            tint: .defaultBrightViolet,
            depth: 1
        ),
        LighthouseThoughtStep(
            symbol: "arrow.up",
            title: "Creating Waypoint",
            detail: "Everything comes together as a waypoint: match-fit by the first game, with the plan and both workouts attached so progress can be tracked week to week.",
            tint: .defaultCyan,
            depth: 2,
            isWaypoint: true
        ),
    ]


    static let history = [
        LighthouseHistoryEntry(title: "Optimising Your Nutrition Strategy", when: "4 min ago"),
        LighthouseHistoryEntry(title: "Pre-Season Football Strength & Conditioning", when: "23 h ago"),
        LighthouseHistoryEntry(title: "Dashboard Adjustment - Sleep Focus", when: "7 Sep"),
        LighthouseHistoryEntry(title: "Why Is My Resting Heart Rate Climbing?", when: "6 Sep"),
        LighthouseHistoryEntry(title: "Deload Week Planning", when: "4 Sep"),
        LighthouseHistoryEntry(title: "Protein Timing Around Evening Sessions", when: "2 Sep"),
        LighthouseHistoryEntry(title: "Reading My HRV Trend", when: "30 Aug"),
        LighthouseHistoryEntry(title: "Hip Mobility Routine for Squats", when: "28 Aug"),
        LighthouseHistoryEntry(title: "Caffeine Cut-Off and Deep Sleep", when: "25 Aug"),
        LighthouseHistoryEntry(title: "Zone 2 Volume for the Off-Season", when: "21 Aug"),
        LighthouseHistoryEntry(title: "Comparing Two Weeks of Recovery Scores", when: "18 Aug"),
        LighthouseHistoryEntry(title: "Travel Week: Keeping the Routine", when: "14 Aug"),
        LighthouseHistoryEntry(title: "First Look at My Genome Summary", when: "9 Aug"),
    ]

    static let checkIns = [
        LighthouseCheckIn(
            title: "Daily Training Readiness",
            frequency: .daily,
            weekday: .sunday,
            dayOfMonth: 1,
            time: time(hour: 7),
            detail: "A short morning read on whether today suits the session you have planned.",
            isOn: true
        ),
        LighthouseCheckIn(
            title: "Weekly Climbing Review",
            frequency: .weekly,
            weekday: .sunday,
            dayOfMonth: 1,
            time: time(hour: 18),
            detail: "Check in on your weekly progress, finger health, and any plateaus you've encountered.",
            isOn: true
        ),
        LighthouseCheckIn(
            title: "Weekly Nutrition Review",
            frequency: .weekly,
            weekday: .sunday,
            dayOfMonth: 1,
            time: time(hour: 18),
            detail: "Check in on how the week's meals lined up with your targets and where the gaps were.",
            isOn: true
        ),
        LighthouseCheckIn(
            title: "Monthly Sleep Review",
            frequency: .monthly,
            weekday: .sunday,
            dayOfMonth: 1,
            time: time(hour: 8),
            detail: "A monthly look at your sleep trends and what has been moving them.",
            isOn: false
        ),
    ]

    static func time(hour: Int, minute: Int = 0) -> Date {
        Calendar.autoupdatingCurrent.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
    }

    static let configurations = [
        LighthouseConfiguration(
            title: "Climbing S&C",
            created: "Created: 2 May",
            widgets: ["Intake", "Activity", "Sleep", "Recovery", "Fatigue", "Readiness"],
            isOn: true
        ),
        LighthouseConfiguration(
            title: "Weight loss focus",
            created: "Created: 24 Dec 2025",
            widgets: ["Intake", "Activity", "Steps", "Macros", "Zones"],
            isOn: false
        ),
    ]

    static let sleepPartOne = "Notice how few REM stages of sleep you had?"

    static let sleepItems: [LighthouseStoryItem] = [
        LighthouseStoryItem(text: "You barely reached REM last night. Your deep and REM stages were short and broken up."),
        LighthouseStoryItem(text: "Your heart rate was high while you poorly slept, meaning your body didn't have time to rest."),
        LighthouseStoryItem(text: "And now it's 11am and you haven't properly rested."),
    ]

    static let followUpOptions = [
        "No consistent workout routine",
        "Following a set weekly schedule with specific days and muscle groups",
        "Flexible with with my routine",
    ]

    static let replies = [
        "Your deep sleep dropped to 48 minutes last night, about 30% under your monthly average. The two late meals this week line up with the worst nights.",
        "Recovery is trending up. Keep the easy cardio on rest days and hold strength volume where it is for another week before adding load.",
        "Resting heart rate has been climbing since Tuesday. That usually shows up two days before you feel run down, so an early night tonight would help.",
    ]

    static let weeklyClimbingReview = LighthouseCheckInReview(
        title: "Weekly Climbing Review",
        summary: "This week shows a solid climbing block. You logged every session, though your training has leaned further into strength each week. Intake held steady at around 2,600 Cal a day, with dinner doing most of the work. Sleep averaged 7 hours 6 minutes, a little under your 28-day average, so recovery has lagged behind the load. Keep it up!",
        sections: [
            LighthouseCheckInReview.Section(kind: .workouts, findings: [
                .init(text: "12/12 sessions completed", detail: "Every planned session this week was logged, including both board sessions.", isOnTrack: true),
                .init(text: "Cardio has dropped to 22%", detail: "Your split has moved from 60/40 to 78/22 over four weeks as board sessions replaced easy runs.", isOnTrack: false),
                .init(text: "High Fatigue", detail: "Training load sits 18% above your four-week average.", isOnTrack: false),
                .init(text: "Low Readiness", detail: "Readiness has stayed under 60 since Thursday.", isOnTrack: false),
            ]),
            LighthouseCheckInReview.Section(kind: .nutrition, findings: [
                .init(text: "Meals are well spread through the day", detail: "Breakfast, lunch and dinner carry 78% of your 2,620 Cal daily average.", isOnTrack: true),
                .init(text: "Snacks make up 15% of intake", detail: "Snacks averaged 390 Cal a day, mostly in the evening after sessions.", isOnTrack: false),
            ]),
            LighthouseCheckInReview.Section(kind: .sleep, findings: [
                .init(text: "Sleep is 18 minutes under your average", detail: "You averaged 7 hours 6 minutes this week against 7 hours 24 minutes over the past 28 days.", isOnTrack: false),
                .init(text: "Tuesday was your shortest night", detail: "5 hours 54 minutes after a late board session, and readiness hasn't recovered since.", isOnTrack: false),
            ]),
        ],
        followUps: [
            "How can I adjust my schedule to improve results for next week?",
            "What are some adjustments I can make to increase my recovery",
            "Flexible with with my routine",
        ]
    )

    static let trainingLoad = ExerciseTrainingLoad(
        strengthPercent: 68,
        cardioPercent: 32,
        weeks: [
            ExerciseWeekLoad(name: "Week 1", strengthFraction: 0.60, cardioFraction: 0.40, ratio: "60/40"),
            ExerciseWeekLoad(name: "Week 2", strengthFraction: 0.64, cardioFraction: 0.36, ratio: "64/36"),
            ExerciseWeekLoad(name: "Week 3", strengthFraction: 0.70, cardioFraction: 0.30, ratio: "70/30"),
            ExerciseWeekLoad(name: "Week 4", strengthFraction: 0.78, cardioFraction: 0.22, ratio: "78/22"),
        ]
    )

    static var intakeBreakdown: IntakeBreakdownWidgetViewState {
        let breakdown = IntakeBreakdownResponseData()
        breakdown.breakfast = 520
        breakdown.lunch = 710
        breakdown.dinner = 820
        breakdown.snack = 390
        breakdown.drink = 180
        breakdown.unit = "kcal"
        return IntakeBreakdownWidgetViewState(title: "Daily average, past 7 days", breakdown: breakdown, showIntakeBar: true)
    }

    static let sleepSevenDays: [SleepSummaryDataPoint] = zip(
        ["2026-09-18", "2026-09-19", "2026-09-20", "2026-09-21", "2026-09-22", "2026-09-23", "2026-09-24"],
        [7.4, 7.6, 7.2, 7.0, 5.9, 7.3, 7.3]
    ).map { SleepSummaryDataPoint(date: $0, value: $1) }

    static let sleepTwentyEightDays: [SleepSummaryDataPoint] = zip(
        (0..<28).map { "2026-\($0 < 4 ? "08" : "09")-\(String(format: "%02d", $0 < 4 ? 28 + $0 : $0 - 3))" },
        [
            7.8, 7.5, 7.9, 7.4, 7.6, 7.2, 7.7,
            7.6, 7.3, 7.8, 7.1, 7.6, 7.4, 7.7,
            7.5, 7.2, 7.6, 7.3, 7.4, 7.6, 7.2,
            7.4, 7.6, 7.2, 7.0, 5.9, 7.3, 7.3,
        ]
    ).map { SleepSummaryDataPoint(date: $0, value: $1) }

    static let sleepWeeklyAverages = [
        WeeklyAverage(week: 1, value: 7.6),
        WeeklyAverage(week: 2, value: 7.5),
        WeeklyAverage(week: 3, value: 7.4),
        WeeklyAverage(week: 4, value: 7.1),
    ]
}
