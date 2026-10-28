//
//  BrightDNAStrandGeometryV5.swift
//  Widgets
//
//  Created by Dom Montalto on 21/10/2026.
//

import Foundation
import simd

struct BrightDNAStrandRungV5 {
    let index: Int
    let center: SIMD3<Float>
    let endA: SIMD3<Float>
    let endB: SIMD3<Float>
}

struct BrightDNAStrandMeshV5 {
    let sphereVertices: [Float]
    let sphereIndices: [UInt16]
    // 5 floats per bead: center.xyz, radius, pairIndex (-1 for backbone).
    let instances: [Float]
    // First bead of each rung plus a final end index, for drawing only the rungs in view.
    let rungInstanceStart: [Int]
    let rungs: [BrightDNAStrandRungV5]
    // Full strand height, including the unlabelled padding at each end.
    let height: Float
    // Height of the labelled rungs, centred in the strand.
    let labelledHeight: Float

    var beadCount: Int { instances.count / 5 }
}

// The bead model from BrightDNAStrandBeads.bin, cut into one-rung units in a
// local frame (rung along +x at y = 0). Built from the sculpted OBJ by
// DNA/tools/build_balls_strand.py.
struct BrightDNAStrandBeadLayoutV5 {
    struct Unit {
        let beads: [SIMD4<Float>]
        let isRung: [Bool]
    }

    let units: [Unit]
    let rungSpacing: Float
    let twistPerRung: Float
    let railRadius: Float

    static let shared: BrightDNAStrandBeadLayoutV5 = {
        guard let url = Bundle.main.url(forResource: "BrightDNAStrandBeads", withExtension: "bin"),
              let data = try? Data(contentsOf: url),
              let layout = BrightDNAStrandBeadLayoutV5(data: data)
        else { fatalError("BrightDNAStrandBeads.bin missing or malformed") }
        return layout
    }()

    init?(data: Data) {
        guard data.count >= 24, data.prefix(4) == Data("BALL".utf8) else { return nil }
        func u32(_ offset: Int) -> UInt32 { data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self) } }
        func f32(_ offset: Int) -> Float { data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: Float.self) } }

        let unitCount = Int(u32(8))
        rungSpacing = f32(12)
        twistPerRung = f32(16)
        railRadius = f32(20)
        var offset = 24 + unitCount * 4
        var units: [Unit] = []
        for u in 0..<unitCount {
            let count = Int(u32(24 + u * 4))
            guard data.count >= offset + count * 20 else { return nil }
            var beads: [SIMD4<Float>] = []
            var isRung: [Bool] = []
            beads.reserveCapacity(count)
            isRung.reserveCapacity(count)
            for _ in 0..<count {
                beads.append(SIMD4(f32(offset), f32(offset + 4), f32(offset + 8), f32(offset + 12)))
                isRung.append(f32(offset + 16) > 0.5)
                offset += 20
            }
            units.append(Unit(beads: beads, isRung: isRung))
        }
        guard !units.isEmpty else { return nil }
        self.units = units
    }
}

enum BrightDNAStrandBuilderV5 {
    static let fallbackRungCount = 100
    // Unlabelled rungs added beyond each end, so the vapour dissolve happens
    // past the last labelled rung rather than through it.
    static let endPadding = 8
    static let beadScale: Float = 1.45
    static var rungSpacing: Float { BrightDNAStrandBeadLayoutV5.shared.rungSpacing }

    static var turnPitch: Float {
        let layout = BrightDNAStrandBeadLayoutV5.shared
        return layout.rungSpacing * 2 * .pi / abs(layout.twistPerRung)
    }

    static func height(for rungCount: Int) -> Float { Float(rungCount) * rungSpacing }

    // Stacks one bead unit per rung, turning each by the model's twist so the
    // strand runs any length without a seam.
    static func build(rungCount requested: Int) -> BrightDNAStrandMeshV5 {
        let layout = BrightDNAStrandBeadLayoutV5.shared
        let rungCount = max(requested, 1)
        let totalRungs = rungCount + 2 * endPadding
        let height = height(for: totalRungs)

        var instances: [Float] = []
        var starts: [Int] = []
        var rungs: [BrightDNAStrandRungV5] = []
        instances.reserveCapacity(totalRungs * (layout.units[0].beads.count + 16) * 5)
        starts.reserveCapacity(totalRungs + 1)
        rungs.reserveCapacity(rungCount)

        for k in 0..<totalRungs {
            let unit = layout.units[k % layout.units.count]
            let a = Float(k) * layout.twistPerRung
            let c = cos(a), s = sin(a)
            let y = (Float(k) + 0.5) * layout.rungSpacing - height / 2
            starts.append(instances.count / 5)
            for (bead, isRung) in zip(unit.beads, unit.isRung) {
                instances.append(bead.x * c - bead.z * s)
                instances.append(bead.y + y)
                instances.append(bead.x * s + bead.z * c)
                instances.append(bead.w * beadScale)
                instances.append(isRung ? Float(k) : -1)
            }
            let endA = SIMD3<Float>(layout.railRadius * c, y, layout.railRadius * s)
            let endB = SIMD3<Float>(-layout.railRadius * c, y, -layout.railRadius * s)
            if (endPadding..<endPadding + rungCount).contains(k) {
                rungs.append(BrightDNAStrandRungV5(index: k - endPadding, center: SIMD3(0, y, 0), endA: endA, endB: endB))
            }
        }
        starts.append(instances.count / 5)

        let sphere = icosphere(subdivisions: 2)
        return BrightDNAStrandMeshV5(sphereVertices: sphere.vertices, sphereIndices: sphere.indices,
                                     instances: instances, rungInstanceStart: starts,
                                     rungs: rungs, height: height,
                                     labelledHeight: Self.height(for: rungCount))
    }

    // Unit icosphere; positions double as normals.
    private static func icosphere(subdivisions: Int) -> (vertices: [Float], indices: [UInt16]) {
        let t: Float = (1 + Float(5).squareRoot()) / 2
        let corners: [SIMD3<Float>] = [
            [-1, t, 0], [1, t, 0], [-1, -t, 0], [1, -t, 0],
            [0, -1, t], [0, 1, t], [0, -1, -t], [0, 1, -t],
            [t, 0, -1], [t, 0, 1], [-t, 0, -1], [-t, 0, 1],
        ]
        var points = corners.map { simd_normalize($0) }
        var faces: [(Int, Int, Int)] = [
            (0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11),
            (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8),
            (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9),
            (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1),
        ]
        for _ in 0..<subdivisions {
            var midpoints: [UInt64: Int] = [:]
            func midpoint(_ a: Int, _ b: Int) -> Int {
                let key = UInt64(min(a, b)) << 32 | UInt64(max(a, b))
                if let i = midpoints[key] { return i }
                points.append(simd_normalize((points[a] + points[b]) / 2))
                midpoints[key] = points.count - 1
                return points.count - 1
            }
            faces = faces.flatMap { a, b, c -> [(Int, Int, Int)] in
                let ab = midpoint(a, b), bc = midpoint(b, c), ca = midpoint(c, a)
                return [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
            }
        }
        return (points.flatMap { [$0.x, $0.y, $0.z] },
                faces.flatMap { [UInt16($0.0), UInt16($0.1), UInt16($0.2)] })
    }
}
