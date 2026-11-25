//
//  WaypointWeather.swift
//  Widgets
//
//  Created by Dom Montalto on 25/11/2026.
//

import SwiftUI

// The storm over the map, which is drawn into the map itself so it hangs over the
// terrain and turns with it: bolts coming down out of a drifting sky.
enum WaypointWeather {
    // How fast the clouds cross the map, in points of ground a second.
    static let drift: Double = 16
    // The seconds between chances of lightning, and the share of them that are
    // taken, so strikes don't come on a beat.
    static let strikeEvery: Double = 2.2
    static let strikeChance: Double = 0.75
    static let strikeLength: Double = 0.55

    // Whether lightning strikes in the turn a moment falls in, and which turn that
    // is. The map draws from this and the thunder is timed from it, so they agree.
    static func strike(at time: TimeInterval) -> (index: Int, age: Double)? {
        let index = Int((time / strikeEvery).rounded(.down))
        guard WaypointTerrain.scatter(index, 14) < strikeChance else { return nil }
        return (index, time - Double(index) * strikeEvery)
    }
}

// Where the light comes from: the way to the sun along the ground, low in the west,
// and how far that throws a cloud's shadow from under it.
enum WaypointSun {
    static let x: Double = -0.8
    static let y: Double = 0.6
    static let shadowReach: Double = 110
}

// The clouds: altocumulus, a high field of small tufts that gathers into banks and
// thins into gaps. They sit well above the camera, so they fill the sky back to the
// horizon instead of lying over the map. Heights are in terrain heights, where the
// hills top out at 1; widths are in points of ground.
enum WaypointClouds {
    static let count = 1200
    // How far the field reaches either side of the user before it wraps round.
    static let reach: Double = 3400
    static let base: Double = 9
    // A second, higher layer, which the wind moves more slowly.
    static let layerGap: Double = 2.5
    static let upperDrift: Double = 0.6
    static let radius: Double = 62
    // How much bigger than the smallest the largest tufts are.
    static let variety: Double = 0.9
    // How much cover a spot needs before a tuft forms there.
    static let coverLine: Double = 0.38
    static let opacity: Double = .veryHighOpacity
    // How much of a tuft's width is solid before its edge starts to fade.
    static let core: Double = 0.35
    // The distance by which a tuft has all but gone into the haze.
    static let hazeReach: Double = 4200

    // Past the tufts, far fewer and far wider banks carry the cloud on to the
    // horizon, where it's seen edge on and runs together.
    static let bankCount = 150
    static let bankReach: Double = 9000
    static let bankRadius: Double = 420
    static let bankStart: Double = 3000

    // How many caps are heaped on a tuft's underside, and how far up they're stacked.
    static let caps = 3
    static let tower: Double = 0.9
}

// The clouds that float low over the map itself: a dark, broken layer close enough
// to see its shadows right under it.
enum WaypointFloatingClouds {
    static let count = 22
    // How far the clouds reach either side of the user before they wrap round.
    static let reach: Double = 440
    static let base: Double = 2.4
    static let radius: Double = 52
    // How many caps are heaped on the underside, and how far up they're stacked.
    static let caps = 3
    static let tower: Double = 0.4
    static let opacity: Double = .mediumOpacity
}

// The rain: thin, short drops that each leave a ring spreading on the ground where
// they land. Lengths are in terrain heights and distances across the ground are in
// points of it.
enum WaypointRain {
    static let dropCount = 320
    static let dropLength: Double = 0.035
    static let dropWidth: CGFloat = 0.6
    // The seconds a drop takes from the clouds to the ground.
    static let fallTime: Double = 1
    // How far the wind carries a drop sideways on its way down.
    static let lean: Double = 8
    static let opacity: Double = .mediumOpacity
    // The share of drops that still fall where the sky is clear.
    static let clearSkyShare: Double = 0.3
}
