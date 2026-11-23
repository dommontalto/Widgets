//
//  WaypointTerrain.swift
//  Widgets
//
//  Created by Dom Montalto on 24/11/2026.
//

import SwiftUI

// Where the map is looked at from. Heading is degrees clockwise from north, pitch
// is 0 looking straight down, lift is how far the terrain has risen off the page,
// reveal is how much of the route has been drawn and focus is the spot on the
// ground the camera is held over, which is the user until the map is dragged.
struct WaypointCamera: Equatable {
    typealias Pose = AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<Double, AnimatablePair<Double, Double>>>
    typealias AnimatableData = AnimatablePair<Pose, AnimatablePair<Double, Double>>

    var heading: Double
    var pitch: Double
    var lift: Double
    var zoom: Double
    var reveal: Double
    var focusX: Double = 0
    var focusY: Double = 0

    var animatableData: AnimatableData {
        get {
            AnimatablePair(
                AnimatablePair(AnimatablePair(heading, pitch), AnimatablePair(lift, AnimatablePair(zoom, reveal))),
                AnimatablePair(focusX, focusY)
            )
        }
        set {
            heading = newValue.first.first.first
            pitch = newValue.first.first.second
            lift = newValue.first.second.first
            zoom = newValue.first.second.second.first
            reveal = newValue.first.second.second.second
            focusX = newValue.second.first
            focusY = newValue.second.second
        }
    }

    static let flat = WaypointCamera(heading: 0, pitch: 0, lift: 0, zoom: 1, reveal: 1)
    static let raised = WaypointCamera(heading: 0, pitch: 52, lift: 1, zoom: 1.15, reveal: 1)
    static let intro = WaypointCamera(heading: -50, pitch: 52, lift: 0, zoom: 1.15, reveal: 0)
}

// Turns a point on the ground into a point on screen. World units are points on the
// flat map: x runs east, y runs north, and the origin is where the user stands. The
// camera's focus stays pinned to `anchor` however it turns or tilts.
struct WaypointProjection {
    private let anchorX: Double
    private let anchorY: Double
    private let cosHeading: Double
    private let sinHeading: Double
    private let cosPitch: Double
    private let sinPitch: Double
    private let zoom: Double
    private let relief: Double
    private let focusX: Double
    private let focusY: Double

    init(camera: WaypointCamera, anchor: CGPoint) {
        let heading = camera.heading * .pi / 180
        let pitch = camera.pitch * .pi / 180
        anchorX = Double(anchor.x)
        anchorY = Double(anchor.y)
        cosHeading = cos(heading)
        sinHeading = sin(heading)
        cosPitch = cos(pitch)
        sinPitch = sin(pitch)
        zoom = camera.zoom
        relief = camera.lift * Constants.relief
        focusX = camera.focusX
        focusY = camera.focusY
    }

    // `height` is relative to the ground under the user, in the terrain's 0...1 range.
    func point(_ x: Double, _ y: Double, height: Double) -> CGPoint {
        let offsetX = x - focusX
        let offsetY = y - focusY
        let turnedX = offsetX * cosHeading - offsetY * sinHeading
        let turnedY = offsetX * sinHeading + offsetY * cosHeading
        let raised = height * relief
        let up = turnedY * cosPitch + raised * sinPitch
        let depth = turnedY * sinPitch - raised * cosPitch
        let scale = zoom * Constants.eyeDistance / max(Constants.eyeDistance + depth, Constants.nearPlane)
        return CGPoint(x: anchorX + turnedX * scale, y: anchorY - up * scale)
    }

    // How far across the ground a drag on screen reaches, so the map can be moved by
    // the same amount and stay under the finger. Tilted, a drag up the screen covers
    // more ground than one across it.
    func groundDistance(dragged: CGSize) -> CGPoint {
        let turnedX = Double(dragged.width) / zoom
        let turnedY = -Double(dragged.height) / (zoom * max(cosPitch, Constants.steepestLean))
        return CGPoint(
            x: turnedX * cosHeading + turnedY * sinHeading,
            y: turnedY * cosHeading - turnedX * sinHeading
        )
    }

    private enum Constants {
        static let steepestLean: Double = 0.3
        static let relief: Double = 70
        static let eyeDistance: Double = 700
        static let nearPlane: Double = 120
    }
}

// A made-up landscape that climbs towards the goal. `height(x:y:)` is the one
// definition of the ground: the contours are slices of it, taken once so each frame
// only has to project them, and everything else drawn on the map asks it how high
// to sit.
struct WaypointTerrain {
    struct Level {
        let height: Double
        // x0, y0, x1, y1 for each piece of the contour.
        let segments: [Double]
    }

    let levels: [Level]
    let originHeight: Double

    static let demo = WaypointTerrain()

    init() {
        let count = Constants.cells + 1
        var samples = [Double](repeating: 0, count: count * count)
        for row in 0 ..< count {
            for column in 0 ..< count {
                samples[row * count + column] = Self.height(x: Self.coordinate(column), y: Self.coordinate(row))
            }
        }

        var levels: [Level] = []
        var height = Constants.lowestLevel
        while height < Constants.highestLevel {
            levels.append(Level(height: height, segments: Self.contour(at: height, samples: samples, count: count)))
            height += Constants.levelStep
        }
        self.levels = levels
        originHeight = Self.height(x: 0, y: 0)
    }

    static func height(x: Double, y: Double) -> Double {
        var total = 0.0
        var range = 0.0
        var amplitude = 1.0
        var frequency = 1 / Constants.wavelength
        for octave in 0 ..< Constants.octaves {
            let shift = Double(octave) * Constants.octaveShift
            total += amplitude * noise(x * frequency + shift, y * frequency - shift)
            range += amplitude
            amplitude /= 2
            frequency *= 2
        }
        let rolling = min(max((total / range - 0.5) * Constants.contrast + 0.5, 0), 1)
        let climb = fade(min(max((y - Constants.climbStart) / Constants.climbLength, 0), 1))
        return rolling * (1 - Constants.climbShare) + climb * Constants.climbShare
    }

    private static func coordinate(_ index: Int) -> Double {
        Double(index) * Constants.step - Constants.radius
    }

    // Marching squares: each grid cell the level passes through gives one or two
    // straight pieces of the contour.
    private static func contour(at level: Double, samples: [Double], count: Int) -> [Double] {
        var segments: [Double] = []
        let step = Constants.step

        for row in 0 ..< count - 1 {
            for column in 0 ..< count - 1 {
                let x0 = coordinate(column)
                let y0 = coordinate(row)
                let centreX = x0 + step / 2
                let centreY = y0 + step / 2
                guard centreX * centreX + centreY * centreY < Constants.radius * Constants.radius else { continue }

                let southWest = samples[row * count + column]
                let southEast = samples[row * count + column + 1]
                let northEast = samples[(row + 1) * count + column + 1]
                let northWest = samples[(row + 1) * count + column]

                var corners = 0
                if southWest > level { corners |= 1 }
                if southEast > level { corners |= 2 }
                if northEast > level { corners |= 4 }
                if northWest > level { corners |= 8 }
                guard corners != 0, corners != 15 else { continue }

                let south = [x0 + crossing(level, southWest, southEast) * step, y0]
                let east = [x0 + step, y0 + crossing(level, southEast, northEast) * step]
                let north = [x0 + crossing(level, northWest, northEast) * step, y0 + step]
                let west = [x0, y0 + crossing(level, southWest, northWest) * step]

                switch corners {
                case 1, 14: segments += west + south
                case 2, 13: segments += south + east
                case 3, 12: segments += west + east
                case 4, 11: segments += east + north
                case 6, 9: segments += south + north
                case 7, 8: segments += west + north
                case 5: segments += west + north + south + east
                default: segments += west + south + east + north
                }
            }
        }
        return segments
    }

    private static func crossing(_ level: Double, _ from: Double, _ to: Double) -> Double {
        let span = to - from
        guard span != 0 else { return 0.5 }
        return min(max((level - from) / span, 0), 1)
    }

    private static func noise(_ x: Double, _ y: Double) -> Double {
        let floorX = x.rounded(.down)
        let floorY = y.rounded(.down)
        let column = Int(floorX)
        let row = Int(floorY)
        let blendX = fade(x - floorX)
        let blendY = fade(y - floorY)

        let south = lattice(column, row) + (lattice(column + 1, row) - lattice(column, row)) * blendX
        let north = lattice(column, row + 1) + (lattice(column + 1, row + 1) - lattice(column, row + 1)) * blendX
        return south + (north - south) * blendY
    }

    private static func lattice(_ x: Int, _ y: Int) -> Double {
        var hash = UInt32(truncatingIfNeeded: x &* 374_761_393 &+ y &* 668_265_263)
        hash = (hash ^ (hash >> 13)) &* 1_274_126_177
        hash ^= hash >> 16
        return Double(hash) / Double(UInt32.max)
    }

    private static func fade(_ value: Double) -> Double {
        value * value * value * (value * (value * 6 - 15) + 10)
    }

    private enum Constants {
        // Far enough out that the map never shows an edge, whichever way it's turned.
        static let radius: Double = 520
        static let cells = 65
        static let step: Double = radius * 2 / Double(cells)
        static let lowestLevel: Double = 0.14
        static let highestLevel: Double = 0.92
        static let levelStep: Double = 0.1
        static let wavelength: Double = 230
        static let octaves = 3
        static let octaveShift: Double = 17.3
        static let contrast: Double = 1.7
        static let climbStart: Double = -320
        static let climbLength: Double = 820
        static let climbShare: Double = 0.3
    }
}
