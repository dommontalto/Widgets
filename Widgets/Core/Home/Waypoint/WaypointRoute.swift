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
    // Lighthouse's way back onto the plan.
    let correction: [CGPoint]
    // The rest of the way to the goal.
    let ahead: [CGPoint]

    let user: CGPoint
    let correctionCallout: CGPoint
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
        let correctionStart = CGPoint(x: -44, y: 106)
        let correctionBend = CGPoint(x: -35, y: 123.4)
        let correctionStraight = CGPoint(x: -19.6, y: 133.6)

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

        var correction = [correctionStart]
        correction += WaypointTrack.line(from: correctionStart, to: correctionBend)
        correction += WaypointTrack.curve(
            from: correctionBend,
            control1: CGPoint(x: -31.9, y: 129.2),
            control2: CGPoint(x: -26.1, y: 133.1),
            to: correctionStraight
        )
        correction += WaypointTrack.line(from: correctionStraight, to: milestone)

        return WaypointRoute(
            trail: trail,
            planned: planned,
            drift: drift,
            correction: correction,
            ahead: ahead,
            user: CGPoint(x: 0, y: -38),
            correctionCallout: CGPoint(x: -36, y: 136),
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
