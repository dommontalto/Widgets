//
//  WaypointWeather.swift
//  Widgets
//
//  Created by Dom Montalto on 25/11/2026.
//

import SwiftUI

// The storm over the map, which is drawn into the map itself so it hangs over the
// terrain and turns with it: bolts coming down in pairs out of a drifting sky. How
// the rain under it looks is a `WaypointRainStyle`.
enum WaypointWeather {
    // How fast the clouds cross the map, in points of ground a second.
    static let drift: Double = 16
    // The seconds between chances of lightning, and the share of them that are
    // taken, so strikes don't come on a beat.
    static let strikeEvery: Double = 1.1
    static let strikeChance: Double = 0.9
    // How many bolts come down together.
    static let bolts = 2
}

// The clouds: altocumulus, a high field of small, evenly sized tufts, each a couple
// of soft puffs. Heights are in terrain heights, where the hills top out at 1;
// widths are in points of ground.
enum WaypointClouds {
    static let cloudCount = 120
    static let puffsPerCloud = 3
    // How high the bottom of a cloud sits, which is also where the lightning starts.
    static let base: Double = 3
    // How far the clouds differ from each other in height.
    static let layerDepth: Double = 0.2
    // How tall one cloud is from its base to its top.
    static let tower: Double = 0.1
    // How far a cloud's puffs spread along the wind at its base and at its top.
    static let baseSpread: Double = 10
    static let topSpread: Double = 10
    // How deep a cloud is across the wind, as a share of its spread along it.
    static let depthShare: Double = 0.8
    static let puffRadius: Double = 13
    // The share of a cloud, from its base up, that's the darker grey.
    static let darkShare: Double = 0.25
    static let opacity: Double = .veryHighOpacity
    // How much of a puff's width is solid before its edge starts to fade.
    static let core: Double = 0.5
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
    // Rain only under the clouds, falling in columns that drift along with them.
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
        case .streaks: 520
        case .sheets: 900
        case .mist: 1100
        case .heavyDrops: 260
        case .shafts: 700
        }
    }

    var dropLength: Double {
        switch self {
        case .streaks: 0.14
        case .sheets: 0.5
        case .mist: 0.02
        case .heavyDrops: 0.2
        case .shafts: 0.16
        }
    }

    var dropWidth: CGFloat {
        switch self {
        case .streaks, .sheets, .shafts: 1
        case .mist: 1.5
        case .heavyDrops: 2
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

    var fallsFromClouds: Bool { self == .shafts }

    private enum Constants {
        static let faint: Double = .semiLowOpacity
        static let light: Double = .lowOpacity
        static let strong: Double = .mediumOpacity
    }
}
