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
enum LighthouseDemo {
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
