//
//  WaypointWeather.swift
//  Widgets
//
//  Created by Dom Montalto on 25/11/2026.
//

import SwiftUI

// The storm over the map, which is drawn into the map itself so it hangs over the
// terrain and turns with it: bolts coming down out of a drifting sky. How the rain
// under it looks is a `WaypointRainStyle`.
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

// The clouds that float low over the map itself, close enough to see their shadows
// right under them. The debug menu picks which kind.
enum WaypointFloatingClouds: CaseIterable, Identifiable {
    // A few thin scraps.
    case wisps
    // Small round cumulus, a handful of them.
    case puffs
    // A couple of big ones that tower.
    case heaps
    // Lots of little ones, like sheep.
    case flock
    // A low, broken layer that covers most of the map.
    case blanket

    var id: Self { self }

    var title: String {
        switch self {
        case .wisps: "Wisps"
        case .puffs: "Puffs"
        case .heaps: "Heaps"
        case .flock: "Flock"
        case .blanket: "Blanket"
        }
    }

    var symbol: String {
        switch self {
        case .wisps: "wind"
        case .puffs: "cloud"
        case .heaps: "cloud.fill"
        case .flock: "circle.grid.3x3"
        case .blanket: "cloud.fog"
        }
    }

    var count: Int {
        switch self {
        case .wisps: 6
        case .puffs: 8
        case .heaps: 4
        case .flock: 26
        case .blanket: 22
        }
    }

    // How far the clouds reach either side of the user before they wrap round.
    var reach: Double { 440 }

    var base: Double {
        switch self {
        case .wisps: 3.4
        case .puffs: 3
        case .heaps: 2.6
        case .flock: 3.2
        case .blanket: 2.4
        }
    }

    var radius: Double {
        switch self {
        case .wisps: 22
        case .puffs: 30
        case .heaps: 46
        case .flock: 15
        case .blanket: 52
        }
    }

    // How many caps are heaped on the underside, and how far up they're stacked.
    var caps: Int {
        switch self {
        case .wisps: 1
        case .puffs: 4
        case .heaps: 7
        case .flock: 3
        case .blanket: 3
        }
    }

    var tower: Double {
        switch self {
        case .wisps: 0.1
        case .puffs: 0.9
        case .heaps: 2.2
        case .flock: 0.5
        case .blanket: 0.4
        }
    }

    var opacity: Double {
        switch self {
        case .wisps: Constants.thin
        case .puffs, .heaps, .flock: Constants.full
        case .blanket: Constants.soft
        }
    }

    private enum Constants {
        static let thin: Double = .semiLowOpacity
        static let soft: Double = .lowOpacity
        static let full: Double = .mediumOpacity
    }
}

// The ways the debug menu can draw the rain. Lengths are in terrain heights and
// widths across the ground are in points of it.
enum WaypointRainStyle: CaseIterable, Identifiable {
    // Thin lines leaning with the wind.
    case streaks
    // Long, dense lines driven hard sideways, so the rain reads as sheets.
    case sheets
    // Slow specks hanging in the air.
    case mist
    // Fewer, fatter drops that leave a ring spreading on the ground where they land.
    case heavyDrops
    // Rain only under the thick cloud, falling in columns that drift along with it.
    case shafts

    var id: Self { self }

    var title: String {
        switch self {
        case .streaks: "Streaks"
        case .sheets: "Sheets"
        case .mist: "Mist"
        case .heavyDrops: "Heavy drops"
        case .shafts: "Rain shafts"
        }
    }

    var symbol: String {
        switch self {
        case .streaks: "cloud.rain"
        case .sheets: "cloud.heavyrain"
        case .mist: "cloud.drizzle"
        case .heavyDrops: "drop"
        case .shafts: "cloud.sun.rain"
        }
    }

    var dropCount: Int {
        switch self {
        case .streaks: 620
        case .sheets: 1000
        case .mist: 1200
        case .heavyDrops: 320
        case .shafts: 900
        }
    }

    var dropLength: Double {
        switch self {
        case .streaks: 0.1
        case .sheets: 0.3
        case .mist: 0.015
        case .heavyDrops: 0.035
        case .shafts: 0.11
        }
    }

    var dropWidth: CGFloat {
        switch self {
        case .streaks, .sheets, .shafts: 1
        case .mist: 1.5
        case .heavyDrops: 0.6
        }
    }

    // The seconds a drop takes from the clouds to the ground.
    var fallTime: Double {
        switch self {
        case .streaks: 0.9
        case .sheets: 0.6
        case .mist: 2.4
        case .heavyDrops: 1
        case .shafts: 0.8
        }
    }

    // How far the wind carries a drop sideways on its way down.
    var lean: Double {
        switch self {
        case .streaks: 14
        case .sheets: 30
        case .mist: 4
        case .heavyDrops: 8
        case .shafts: 10
        }
    }

    var opacity: Double {
        switch self {
        case .streaks, .shafts: Constants.light
        case .sheets, .mist: Constants.faint
        case .heavyDrops: Constants.strong
        }
    }

    var hasSplashes: Bool { self == .heavyDrops }

    // The share of drops that still fall where the sky is clear.
    var clearSkyShare: Double {
        self == .shafts ? 0 : 0.3
    }

    private enum Constants {
        static let faint: Double = .semiLowOpacity
        static let light: Double = .lowOpacity
        static let strong: Double = .mediumOpacity
    }
}
