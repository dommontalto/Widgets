//
//  WaypointRoute.swift
//  Widgets
//
//  Created by Dom Montalto on 24/11/2026.
//

import SwiftUI

struct WaypointMarker: Identifiable, Equatable {
    enum Kind {
        case milestone
        case checkpoint
        case strain
        case goal
    }

    let id: String
    let kind: Kind
    let title: String
    let subtitle: String
    // Shown under the label once the marker is tapped.
    let detail: String
    let position: CGPoint
}

// What Lighthouse can do about the load to get back on the plan.
enum WaypointCorrection: CaseIterable, Identifiable {
    case decrease
    case maintain
    case increase

    var id: Self { self }

    var title: String {
        switch self {
        case .decrease: "Decrease load"
        case .maintain: "Maintain load"
        case .increase: "Increase load"
        }
    }

    var symbol: String {
        switch self {
        case .decrease: "arrow.down"
        case .maintain: "equal"
        case .increase: "arrow.up"
        }
    }

    var color: Color {
        switch self {
        case .decrease: .defaultCyan
        case .maintain: .defaultYellow
        case .increase: .defaultRed
        }
    }

    // Easing off bends gently back to the milestone, holding the load carries on
    // the way the drift was heading and misses it, and pushing harder cuts straight
    // across.
    var path: [CGPoint] {
        switch self {
        case .decrease: Self.easedPath
        case .maintain: Self.heldPath
        case .increase: Self.pushedPath
        }
    }

    // Where the pill's leader line touches down beside the path.
    var callout: CGPoint {
        switch self {
        case .decrease: CGPoint(x: -36, y: 136)
        case .maintain: CGPoint(x: -55, y: 140)
        case .increase: CGPoint(x: -30, y: 122)
        }
    }

    var bearing: WaypointBearing {
        switch self {
        case .decrease: .north
        case .maintain: .northWest
        case .increase: .northEast
        }
    }

    var milestoneSubtitle: String {
        switch self {
        case .decrease: "10 KM in 40 mins · 3 weeks"
        case .maintain: "Out of reach at this pace"
        case .increase: "10 KM in 40 mins · 1 week"
        }
    }

    var strainTitle: String {
        switch self {
        case .decrease, .maintain: "High Strain"
        case .increase: "Very High Strain"
        }
    }

    var strainSubtitle: String {
        switch self {
        case .decrease: "Not hitting pace"
        case .maintain: "Still not hitting pace"
        case .increase: "Injury risk rising"
        }
    }

    var strainColor: Color {
        switch self {
        case .decrease, .maintain: .defaultYellow
        case .increase: .defaultRed
        }
    }

    // Where the bar over the map puts its pill: 0 is the middle, 1 the excessive end.
    var barLoad: Double {
        switch self {
        case .decrease: 0.14
        case .maintain: 0.5
        case .increase: 0.86
        }
    }

    private static let start = CGPoint(x: -44, y: 106)
    private static let milestone = CGPoint(x: 23, y: 137)

    private static let easedPath: [CGPoint] = {
        let bend = CGPoint(x: -35, y: 123.4)
        let straight = CGPoint(x: -19.6, y: 133.6)
        var path = [start]
        path += WaypointTrack.line(from: start, to: bend)
        path += WaypointTrack.curve(
            from: bend,
            control1: CGPoint(x: -31.9, y: 129.2),
            control2: CGPoint(x: -26.1, y: 133.1),
            to: straight
        )
        path += WaypointTrack.line(from: straight, to: milestone)
        return path
    }()

    private static let heldPath: [CGPoint] = {
        let end = CGPoint(x: -66, y: 196)
        var path = [start]
        path += WaypointTrack.curve(
            from: start,
            control1: CGPoint(x: -44, y: 136),
            control2: CGPoint(x: -56, y: 166),
            to: end
        )
        return path
    }()

    private static let pushedPath: [CGPoint] = [start] + WaypointTrack.line(from: start, to: milestone)
}

// Everything drawn on the map, in world points with the user at the origin and
// north up.
struct WaypointRoute {
    // Where the user has come from.
    let trail: [CGPoint]
    // The straight line the plan had them on.
    let planned: [CGPoint]
    // Where they actually went.
    let drift: [CGPoint]
    // The rest of the way to the goal.
    let ahead: [CGPoint]

    let user: CGPoint
    let markers: [WaypointMarker]
}

extension WaypointRoute {
    static let demo: WaypointRoute = {
        let origin = CGPoint.zero
        let milestone = CGPoint(x: 23, y: 137)
        let goal = CGPoint(x: 4, y: 266)
        let lineEnd = CGPoint(x: 4, y: 241)

        let driftBend = CGPoint(x: -37.3, y: 25.8)
        let driftStraight = CGPoint(x: -45.5, y: 41.5)

        let trailStart = CGPoint(x: 0, y: -6)
        let trail = [trailStart] + WaypointTrack.line(from: trailStart, to: CGPoint(x: 0, y: -75))
        let planned = [origin] + WaypointTrack.line(from: origin, to: milestone)
        let ahead = [milestone] + WaypointTrack.line(from: milestone, to: lineEnd)

        var drift = [origin]
        drift += WaypointTrack.line(from: origin, to: driftBend)
        drift += WaypointTrack.curve(
            from: driftBend,
            control1: CGPoint(x: -42.4, y: 29.4),
            control2: CGPoint(x: -45.5, y: 35.2),
            to: driftStraight
        )
        drift += WaypointTrack.line(from: driftStraight, to: CGPoint(x: -45.5, y: 65.5))

        return WaypointRoute(
            trail: trail,
            planned: planned,
            drift: drift,
            ahead: ahead,
            user: CGPoint(x: 0, y: -38),
            markers: [
                WaypointMarker(
                    id: "milestone1",
                    kind: .milestone,
                    title: "Milestone 1",
                    subtitle: "10 KM in 40 mins",
                    detail: "Best so far: 10 KM in 46 mins",
                    position: milestone
                ),
                WaypointMarker(
                    id: "milestone2",
                    kind: .checkpoint,
                    title: "Milestone 2",
                    subtitle: "15 KM in 65 mins",
                    detail: "Unlocks after Milestone 1",
                    position: CGPoint(x: 16.7, y: 171.7)
                ),
                WaypointMarker(
                    id: "milestone3",
                    kind: .checkpoint,
                    title: "Milestone 3",
                    subtitle: "18 KM in 85 mins",
                    detail: "Unlocks after Milestone 2",
                    position: CGPoint(x: 10.3, y: 206.3)
                ),
                WaypointMarker(
                    id: "strain",
                    kind: .strain,
                    title: "High Strain",
                    subtitle: "Not hitting pace",
                    detail: "RPE 9 on 3 of your last 4 runs",
                    position: CGPoint(x: -46, y: 88)
                ),
                WaypointMarker(
                    id: "goal",
                    kind: .goal,
                    title: "21 KM under 2 hours",
                    subtitle: "3 Milestones away",
                    detail: "On pace for 2 h 9 min today",
                    position: goal
                ),
            ]
        )
    }()
}

// Breaks a stretch of route into short steps, so it can be drawn part-way and
// follow the ground as it rises. Each returns the points after `from`.
private enum WaypointTrack {
    static func line(from: CGPoint, to: CGPoint) -> [CGPoint] {
        (1 ... Constants.steps).map { step in
            let progress = Double(step) / Double(Constants.steps)
            return CGPoint(
                x: Double(from.x) + Double(to.x - from.x) * progress,
                y: Double(from.y) + Double(to.y - from.y) * progress
            )
        }
    }

    static func curve(from: CGPoint, control1: CGPoint, control2: CGPoint, to: CGPoint) -> [CGPoint] {
        (1 ... Constants.steps).map { step in
            let progress = Double(step) / Double(Constants.steps)
            let rest = 1 - progress
            let a = rest * rest * rest
            let b = 3 * rest * rest * progress
            let c = 3 * rest * progress * progress
            let d = progress * progress * progress
            return CGPoint(
                x: a * Double(from.x) + b * Double(control1.x) + c * Double(control2.x) + d * Double(to.x),
                y: a * Double(from.y) + b * Double(control1.y) + c * Double(control2.y) + d * Double(to.y)
            )
        }
    }

    private enum Constants {
        static let steps = 12
    }
}
