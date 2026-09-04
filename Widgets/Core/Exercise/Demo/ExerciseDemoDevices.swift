//
//  ExerciseDemoDevices.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

// A device Apple Health has seen write heart rate or workouts for this user.
nonisolated struct ExerciseTrackingDevice: Identifiable, Hashable {
    enum Kind: Hashable {
        case watch
        case strap
        case ring
        case sportsWatch

        var symbol: String {
            switch self {
            case .watch: "applewatch"
            case .strap: "heart.text.square"
            case .ring: "circle.circle"
            case .sportsWatch: "watch.analog"
            }
        }

        var tint: Color {
            switch self {
            case .watch: .defaultPink
            case .strap: .defaultRed
            case .ring: .defaultBrightViolet
            case .sportsWatch: .defaultSkyBlue
            }
        }
    }

    let id: String
    let name: String
    let kind: Kind
    // The app that wrote the samples, as Health reports it.
    let sourceApp: String
    let sessionCount: Int
    let lastUsed: Date
    let readsHeartRate: Bool
}

enum ExerciseDemoDevices {
    // The paired watch the phone can reach right now.
    static let pairedWatch = ExerciseTrackingDevice(
        id: "apple-watch-s10",
        name: "Apple Watch Series 10",
        kind: .watch,
        sourceApp: "Bright",
        sessionCount: 8,
        lastUsed: .now.addingTimeInterval(-2 * 86_400),
        readsHeartRate: true
    )

    static let isWatchReachable = true

    static let history: [ExerciseTrackingDevice] = [
        pairedWatch,
        ExerciseTrackingDevice(
            id: "polar-h10",
            name: "Polar H10",
            kind: .strap,
            sourceApp: "Strava",
            sessionCount: 3,
            lastUsed: .now.addingTimeInterval(-9 * 86_400),
            readsHeartRate: true
        ),
        ExerciseTrackingDevice(
            id: "garmin-fr265",
            name: "Garmin Forerunner 265",
            kind: .sportsWatch,
            sourceApp: "Garmin Connect",
            sessionCount: 12,
            lastUsed: .now.addingTimeInterval(-23 * 86_400),
            readsHeartRate: true
        ),
        ExerciseTrackingDevice(
            id: "oura-gen3",
            name: "Oura Ring Gen 3",
            kind: .ring,
            sourceApp: "Oura",
            sessionCount: 0,
            lastUsed: .now.addingTimeInterval(-86_400),
            readsHeartRate: false
        ),
    ]
}
