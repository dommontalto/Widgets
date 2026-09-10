//
//  LighthouseDemo.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

// Hard-coded Lighthouse reply so a sleep question shows the opening line and
// three insights without a backend.
enum LighthouseDemo {
    static let sleepPartOne = "Notice how few REM stages of sleep you had?"

    static let sleepItems: [LighthouseStoryItem] = [
        LighthouseStoryItem(text: "You barely reached REM last night. Your deep and REM stages were short and broken up."),
        LighthouseStoryItem(text: "Your heart rate was high while you poorly slept, meaning your body didn't have time to rest."),
        LighthouseStoryItem(text: "And now it's 11am and you haven't properly rested."),
    ]
}
