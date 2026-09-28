//
//  GraphWorkbenchLayout.swift
//  Widgets
//
//  Created by Dom Montalto on 28/9/2026.
//

import Foundation
import simd

struct GraphNode: Identifiable {
    let entity: GraphEntity
    let position: SIMD3<Float>
    let radius: Float
    let communityID: String?

    var id: String {
        entity.id
    }
}

struct GraphLink: Identifiable {
    let relationship: GraphRelationship
    let sourceID: String
    let targetID: String

    var id: String {
        relationship.id
    }

    func other(than id: String) -> String {
        sourceID == id ? targetID : sourceID
    }
}

struct GraphBounds {
    let center: SIMD3<Float>
    let size: SIMD3<Float>
}

struct GraphLayout {
    let nodes: [GraphNode]
    let links: [GraphLink]
    let communityBounds: [String: GraphBounds]
    let center: SIMD3<Float>
    let extent: Float

    // Centre-out, busiest first, so the constellation fills from its core.
    var admissionOrder: [String] {
        nodes.sorted {
            let a = simd_length_squared($0.position)
            let b = simd_length_squared($1.position)
            return a == b ? $0.entity.degree > $1.entity.degree : a < b
        }
        .map(\.id)
    }
}

// The Workbench's d3-force-3d layout: a "knowledge universe" where the most
// connected entities sit at the core, each community is pulled toward its own
// point on a shell, and charge, links and collision settle the rest.
enum GraphForceLayout {
    static func make(from data: GraphWorkbenchData) -> GraphLayout {
        var random = SeededRandom(seed: Constants.seed)
        let entities = data.entities
        let count = entities.count

        // The finest community wins, matching GraphRAG's leaf assignment.
        var communityByEntity: [String: GraphCommunity] = [:]
        for community in data.communities {
            for entityID in community.entityIDs {
                if let current = communityByEntity[entityID], current.level >= community.level { continue }
                communityByEntity[entityID] = community
            }
        }

        let scores: [Float] = entities.map { entity in
            Float(entity.degree) + Float(entity.frequency) * 0.5
        }
        let minScore = scores.min() ?? 0
        let maxScore = scores.max() ?? 0
        let abstraction: [Float] = scores.map { score in
            maxScore > minScore ? (score - minScore) / (maxScore - minScore) : 0.5
        }

        let targetRadius: [Float] = entities.indices.map { index in
            let level = Float(communityByEntity[entities[index].id]?.level ?? 0)
            return shellRadius(abstraction: abstraction[index]) + level * Constants.levelSpacing * 0.3
        }

        var positions: [SIMD3<Float>] = entities.indices.map { index in
            let jitter: Float = 0.9 + random.nextFloat() * 0.2
            return fibonacciPoint(index: index, count: count) * targetRadius[index] * jitter
        }
        var velocities = [SIMD3<Float>](repeating: .zero, count: count)
        let radii: [Float] = entities.map { nodeRadius(degree: $0.degree, frequency: $0.frequency) }

        let indexByID = Dictionary(uniqueKeysWithValues: entities.enumerated().map { ($1.id, $0) })
        let links = data.relationships.compactMap { relationship -> (Int, Int, GraphRelationship)? in
            guard let source = indexByID[relationship.source], let target = indexByID[relationship.target] else { return nil }
            return (source, target, relationship)
        }
        var linkCounts = [Float](repeating: 0, count: count)
        for (source, target, _) in links {
            linkCounts[source] += 1
            linkCounts[target] += 1
        }

        var communityCenters: [String: SIMD3<Float>] = [:]
        for (index, community) in data.communities.enumerated() {
            let members = entities.indices.filter { communityByEntity[entities[$0].id]?.id == community.id }
            guard !members.isEmpty else { continue }
            let average = members.map { abstraction[$0] }.reduce(0, +) / Float(members.count)
            let radius = shellRadius(abstraction: average) + Float(community.level) * Constants.levelSpacing * 0.2
            communityCenters[community.id] = fibonacciPoint(index: index, count: data.communities.count) * radius
        }

        var alpha: Float = 1
        for _ in 0..<Constants.maxIterations where alpha >= Constants.alphaMin {
            alpha += (0 - alpha) * Constants.alphaDecay

            for (source, target, relationship) in links {
                let weight = Float(relationship.weight)
                let distance = Constants.linkDistance / (weight * 0.05 + 1)
                let strength = min(weight * 0.05, Constants.linkStrength)
                var delta = positions[target] + velocities[target] - positions[source] - velocities[source]
                let length = max(simd_length(delta), Constants.epsilon)
                delta *= (length - distance) / length * alpha * strength
                let bias = linkCounts[source] / (linkCounts[source] + linkCounts[target])
                velocities[target] -= delta * bias
                velocities[source] += delta * (1 - bias)
            }

            for i in 0..<count {
                for j in 0..<count where i != j {
                    let delta = positions[j] - positions[i]
                    let lengthSquared = max(simd_length_squared(delta), 1)
                    let strength = Constants.chargeStrength - Float(entities[j].degree) * 5
                    velocities[i] += delta * strength * alpha / lengthSquared
                }
            }

            let mean = positions.reduce(SIMD3<Float>.zero, +) / Float(count)
            let shift = mean * Constants.centerStrength
            for i in 0..<count {
                positions[i] -= shift
            }

            for i in 0..<count {
                let ri = Constants.collisionRadius + radii[i]
                for j in (i + 1)..<count {
                    let rj = Constants.collisionRadius + radii[j]
                    var delta = (positions[i] + velocities[i]) - (positions[j] + velocities[j])
                    let reach = ri + rj
                    let lengthSquared = simd_length_squared(delta)
                    guard lengthSquared < reach * reach else { continue }
                    let length = max(sqrt(lengthSquared), Constants.epsilon)
                    delta *= (reach - length) / length
                    let share = (rj * rj) / (ri * ri + rj * rj)
                    velocities[i] += delta * share
                    velocities[j] -= delta * (1 - share)
                }
            }

            for i in 0..<count {
                if let id = communityByEntity[entities[i].id]?.id, let center = communityCenters[id] {
                    velocities[i] += (center - positions[i]) * Constants.communityStrength
                }

                let distance = simd_length(positions[i])
                if distance > 0 {
                    velocities[i] += positions[i] / distance * (targetRadius[i] - distance) * Constants.sphericalConstraint
                }
            }

            for i in 0..<count {
                velocities[i] *= Constants.velocityRetention
                positions[i] += velocities[i]
            }
        }

        let nodes = entities.indices.map { index in
            GraphNode(
                entity: entities[index],
                position: positions[index],
                radius: radii[index],
                communityID: communityByEntity[entities[index].id]?.id
            )
        }

        let positionByID = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.position) })
        var communityBounds: [String: GraphBounds] = [:]
        for community in data.communities {
            let points = community.entityIDs.compactMap { positionByID[$0] }
            guard let first = points.first else { continue }
            let lower = points.reduce(first) { simd_min($0, $1) }
            let upper = points.reduce(first) { simd_max($0, $1) }
            communityBounds[community.id] = GraphBounds(
                center: (lower + upper) / 2,
                size: upper - lower + SIMD3(repeating: Constants.boundsPadding)
            )
        }

        let lower = positions.reduce(positions.first ?? .zero) { simd_min($0, $1) }
        let upper = positions.reduce(positions.first ?? .zero) { simd_max($0, $1) }
        let center = (lower + upper) / 2
        let extent = positions.map { simd_distance($0, center) }.max() ?? Constants.spread

        return GraphLayout(
            nodes: nodes,
            links: links.map { GraphLink(relationship: $0.2, sourceID: $0.2.source, targetID: $0.2.target) },
            communityBounds: communityBounds,
            center: center,
            extent: extent
        )
    }

    // Abstract entities (high degree and frequency) near the core, specific ones at the rim.
    private static func shellRadius(abstraction: Float) -> Float {
        let minRadius = Constants.spread * 0.1
        return minRadius + (1 - abstraction) * (Constants.spread - minRadius)
    }

    private static func fibonacciPoint(index: Int, count: Int) -> SIMD3<Float> {
        let goldenAngle = Float.pi * (3 - sqrt(5))
        let phi = acos(1 - 2 * (Float(index) / Float(max(count, 1))))
        let theta = goldenAngle * Float(index)
        return SIMD3(sin(phi) * cos(theta), sin(phi) * sin(theta), cos(phi))
    }

    private static func nodeRadius(degree: Int, frequency: Int) -> Float {
        min(0.8 + (Float(degree) + Float(frequency) * 0.1) * 0.15, 4)
    }

    private enum Constants {
        static let seed: UInt64 = 1969
        static let maxIterations = 500
        static let alphaMin: Float = 0.001
        static let alphaDecay: Float = 0.03
        // d3's velocityDecay of 0.4.
        static let velocityRetention: Float = 0.6
        static let chargeStrength: Float = -100
        static let linkDistance: Float = 30
        static let linkStrength: Float = 0.2
        static let collisionRadius: Float = 6
        static let communityStrength: Float = 0.2
        static let centerStrength: Float = 0.02
        static let spread: Float = 150
        static let levelSpacing: Float = 40
        static let sphericalConstraint: Float = 0.05
        static let boundsPadding: Float = 35
        static let epsilon: Float = 0.0001
    }
}

// Fixed seed, so the demo constellation lands the same way every launch.
private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func nextFloat() -> Float {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Float(z >> 40) / Float(1 << 24)
    }
}
