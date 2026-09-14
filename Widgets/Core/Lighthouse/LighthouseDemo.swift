//
//  LighthouseDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

nonisolated struct LighthouseHistoryEntry: Identifiable {
    let id = UUID()
    let title: String
    let when: String
}

nonisolated struct LighthouseCheckIn: Identifiable {
    let id = UUID()
    let title: String
    let repeats: String
    let detail: String
    var isOn: Bool
}

// Hard-coded Lighthouse content — a sleep reply, past chats and check-ins — so
// the screens fill without a backend.
// One step of a reply's reasoning. `depth` nests it under the step before,
// and the waypoint is the goal the chain arrives at.
nonisolated struct LighthouseThoughtStep: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    // What the model was doing at this step, in its own words.
    let detail: String
    var depth = 0
    var isWaypoint = false
}

enum LighthouseDemo {
    static let thoughtSteps = [
        LighthouseThoughtStep(
            symbol: "rays",
            title: "Evaluating next steps",
            detail: "You've asked how to get fitter for the football season. Before I answer I'm working out what a good answer needs: your current training, how long the season is, and what fitness means for your position."
        ),
        LighthouseThoughtStep(
            symbol: "globe",
            title: "Researching effectiveness",
            detail: "I'm checking what the evidence says about pre-season conditioning for amateur footballers, with an eye on programmes that mix strength, repeated sprints and aerobic base work."
        ),
        LighthouseThoughtStep(
            symbol: "globe",
            title: "Researching effectiveness",
            detail: "Now I'm comparing how much of each quality to train each week, and how recent studies balance intensity against recovery over a six-week block."
        ),
        LighthouseThoughtStep(
            symbol: "brain",
            title: "Defining Goal",
            detail: "Right now, I'm focusing on your question about getting fit for football. I've pinpointed repeated-sprint ability as the biggest gap between where you are and match fitness. My next step will be to lay out a plan that builds it without dropping your strength work."
        ),
        LighthouseThoughtStep(
            symbol: "filemenu.and.selection",
            title: "Generating Plan",
            detail: "I'm shaping a six-week plan: two strength sessions, two conditioning sessions and one easy run each week, with load rising for three weeks before a lighter one.",
            depth: 1
        ),
        LighthouseThoughtStep(
            symbol: "figure.strengthtraining.traditional",
            title: "Generating Upper Body workout",
            detail: "I'm writing the upper-body session around pressing, pulling and trunk work, kept short so it doesn't eat into recovery for the running days.",
            depth: 1
        ),
        LighthouseThoughtStep(
            symbol: "figure.strengthtraining.traditional",
            title: "Generating Lower Body workout",
            detail: "I'm building the lower-body session around squats, hinges and single-leg work, with a plyometric finisher to carry the strength over to sprinting.",
            depth: 1
        ),
        LighthouseThoughtStep(
            symbol: "arrow.up",
            title: "Creating Waypoint",
            detail: "Everything comes together as a waypoint: match-fit by the first game, with the plan and both workouts attached so progress can be tracked week to week.",
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
            title: "Weekly Climbing Review",
            repeats: "Repeat: Sun, 6:00 PM",
            detail: "Check in on your weekly progress, finger health, and any plateaus you've encountered.",
            isOn: true
        ),
        LighthouseCheckIn(
            title: "Weekly Nutrition Review",
            repeats: "Repeat: Sun, 6:00 PM",
            detail: "Check in on how the week's meals lined up with your targets and where the gaps were.",
            isOn: true
        ),
        LighthouseCheckIn(
            title: "Monthly Sleep Review",
            repeats: "Repeat: 1st, 8:00 AM",
            detail: "A monthly look at your sleep trends and what has been moving them.",
            isOn: false
        ),
    ]

    static let sleepPartOne = "Notice how few REM stages of sleep you had?"

    static let sleepItems: [LighthouseStoryItem] = [
        LighthouseStoryItem(text: "You barely reached REM last night. Your deep and REM stages were short and broken up."),
        LighthouseStoryItem(text: "Your heart rate was high while you poorly slept, meaning your body didn't have time to rest."),
        LighthouseStoryItem(text: "And now it's 11am and you haven't properly rested."),
    ]
}
