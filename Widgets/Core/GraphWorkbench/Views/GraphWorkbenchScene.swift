//
//  GraphWorkbenchScene.swift
//  Widgets
//
//  Created by Dom Montalto on 28/9/2026.
//

import RealityKit
import SwiftUI

// Owns every RealityKit entity in the constellation. SwiftUI state lands in
// `apply(_:)` as goals; `step(deltaTime:camera:)` runs each frame and eases
// scale, opacity and thickness toward them, so selection, search and the
// opening build-up all animate instead of snapping.
final class GraphWorkbenchScene {
    // How much bigger a node draws than its layout radius, and how much the
    // selected one grows. The labels and tap picking size themselves by these.
    static let nodeScale: Float = 1.6
    static let selectedScale: Float = 1.5

    let root = Entity()
    var subscription: EventSubscription?

    private let cameraEntity = Entity()
    private let stars = Entity()
    private let boundaryRoot = Entity()
    private var nodes: [String: NodeVisual] = [:]
    private var links: [LinkVisual] = []
    private var boundaryKey = ""
    private var boundaries: [BoundaryVisual] = []
    private var elapsed: Float = 0

    private let rimMesh = GraphWorkbenchScene.ringMesh(inner: Constants.rimInner, outer: 1)
    private let fillMesh = GraphWorkbenchScene.ringMesh(inner: 0, outer: Constants.rimInner)
    private let glowMesh = GraphWorkbenchScene.ringMesh(inner: 1, outer: Constants.glowOuter)
    private let edgeMesh = MeshResource.generateCylinder(height: 1, radius: 1)
    private let edgeMaterial = UnlitMaterial(color: UIColor(Color.defaultWhite))
    private let heroMaterial = UnlitMaterial(color: UIColor(Color.genomePRSCyan))
    private let selectedRimMaterial = UnlitMaterial(color: UIColor(Color.defaultLighthouseBlue))
    private let selectedGlowMaterial = GraphWorkbenchScene.translucent(.defaultLighthouseBlue, opacity: .minimalOpacity)

    init(layout: GraphLayout, fieldOfView: Float) {
        cameraEntity.components.set(PerspectiveCameraComponent(near: Constants.near, far: Constants.far, fieldOfViewInDegrees: fieldOfView))
        root.addChild(cameraEntity)
        root.addChild(makeSpace())
        root.addChild(stars)
        stars.addChild(makeStars())
        root.addChild(boundaryRoot)

        let order = layout.admissionOrder
        let rank = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, Float($0)) })
        let count = Float(max(order.count, 1))

        for node in layout.nodes {
            let color = node.entity.color
            let visual = NodeVisual(
                node: node,
                meshes: (rimMesh, fillMesh, glowMesh),
                rim: UnlitMaterial(color: UIColor(color)),
                fill: Self.translucent(color, opacity: .veryMinimalOpacity),
                glow: Self.translucent(color, opacity: .ultraLowOpacity),
                admitAt: Constants.admitDelay + (rank[node.id] ?? 0) / count * Constants.admitDuration
            )
            nodes[node.id] = visual
            root.addChild(visual.entity)
        }

        // The top tenth of relationships by weight carry the Workbench's
        // "energy" edges, which pulse.
        let weights = layout.links.map(\.relationship.weight).sorted()
        let heroThreshold = weights.isEmpty ? Int.max : weights[min(weights.count - 1, Int(Float(weights.count) * 0.9))]

        for link in layout.links {
            guard let source = nodes[link.sourceID], let target = nodes[link.targetID] else { continue }
            let visual = LinkVisual(
                link: link,
                from: source.position,
                to: target.position,
                mesh: edgeMesh,
                isHero: link.relationship.weight >= heroThreshold,
                admitAt: max(source.admitAt, target.admitAt)
            )
            visual.entity.model?.materials = [visual.isHero ? heroMaterial : edgeMaterial]
            links.append(visual)
            root.addChild(visual.entity)
        }
    }

    func apply(_ model: GraphWorkbenchModel) {
        let matches = model.matchingIDs
        let isolated = model.isolatedEntityIDs
        let selectedID = model.selectedID

        for (id, visual) in nodes {
            let isShown = matches?.contains(id) ?? true
            let isSelected = id == selectedID
            let isInside = isolated?.contains(id) ?? true
            visual.goalScale = isShown ? visual.radius * Self.nodeScale * (isSelected ? Self.selectedScale : 1) : 0
            visual.goalOpacity = isInside ? 1 : Float(Double.veryLowOpacity)
            visual.rim.model?.materials = [isSelected ? selectedRimMaterial : visual.rimMaterial]
            visual.glow.model?.materials = [isSelected ? selectedGlowMaterial : visual.glowMaterial]
        }

        for visual in links {
            let source = visual.link.sourceID
            let target = visual.link.targetID
            let isShown = (matches?.contains(source) ?? true) && (matches?.contains(target) ?? true)
            let isTouching = selectedID != nil && (source == selectedID || target == selectedID)
            let isInside = isolated.map { $0.contains(source) && $0.contains(target) } ?? true

            if !isShown {
                visual.goalOpacity = 0
            } else if isTouching {
                visual.goalOpacity = Float(Double.veryHighOpacity)
            } else if isInside {
                visual.goalOpacity = Float(visual.isHero ? Double.lowOpacity : Double.veryLowOpacity)
            } else {
                visual.goalOpacity = Float(Double.ultraLowOpacity)
            }
            visual.goalThickness = isTouching ? Constants.highlightThickness : 1
            visual.entity.model?.materials = [isTouching || !visual.isHero ? edgeMaterial : heroMaterial]
        }

        updateBoundaries(model)
    }

    func step(deltaTime: Float, camera: GraphWorkbenchCamera) {
        elapsed += deltaTime
        camera.step(deltaTime: deltaTime)
        let facing = camera.orientation
        cameraEntity.transform = Transform(scale: .one, rotation: facing, translation: camera.eye)

        let blend = 1 - exp(-Constants.easing * deltaTime)
        for visual in nodes.values {
            let isAdmitted = elapsed >= visual.admitAt
            visual.scale += ((isAdmitted ? visual.goalScale : 0) - visual.scale) * blend
            visual.opacity += (visual.goalOpacity - visual.opacity) * blend
            visual.entity.isEnabled = visual.scale > Constants.hiddenThreshold
            // The rings are flat, so they turn to face the camera like the
            // Workbench's billboarded nodes.
            visual.entity.transform = Transform(scale: SIMD3(repeating: visual.scale), rotation: facing, translation: visual.position)
            visual.entity.components.set(OpacityComponent(opacity: visual.opacity))
            let pulse = sin(elapsed * Constants.pulseSpeed + visual.phase) * Constants.glowPulse
            visual.glow.scale = SIMD3(repeating: 1 + pulse)
        }

        for visual in links {
            let isAdmitted = elapsed >= visual.admitAt
            var goal = isAdmitted ? visual.goalOpacity : 0
            if visual.isHero, visual.goalThickness == 1 {
                goal *= 1 - Constants.heroPulse + sin(elapsed * Constants.pulseSpeed * 2 + visual.phase) * Constants.heroPulse
            }
            visual.opacity += (goal - visual.opacity) * blend
            visual.thickness += (visual.goalThickness - visual.thickness) * blend
            visual.entity.isEnabled = visual.opacity > Constants.hiddenThreshold
            visual.entity.components.set(OpacityComponent(opacity: visual.opacity))
            let radius = visual.radius * visual.thickness
            visual.entity.scale = SIMD3(radius, visual.length, radius)
        }

        for boundary in boundaries {
            boundary.opacity += (boundary.goalOpacity - boundary.opacity) * blend
            boundary.entity.components.set(OpacityComponent(opacity: boundary.opacity))
        }

        stars.orientation = simd_quatf(angle: elapsed * Constants.starDrift, axis: SIMD3(0, 1, 0))
    }

    // The wireframe boxes around the isolated community tree, coloured by
    // their relation to the selected entity's community.
    private func updateBoundaries(_ model: GraphWorkbenchModel) {
        let communities = model.isolatedCommunities
        let key = communities.map { "\($0.id):\(model.role(of: $0))" }.joined(separator: ",")
        guard key != boundaryKey else { return }
        boundaryKey = key

        for child in Array(boundaryRoot.children) {
            child.removeFromParent()
        }
        boundaries = communities.compactMap { community in
            guard let bounds = model.layout.communityBounds[community.id] else { return nil }
            let role = model.role(of: community)
            let opacity: Double = switch role {
            case .selected: .veryHighOpacity
            case .parent, .child: .mediumOpacity
            case .related: .lowOpacity
            }
            let visual = BoundaryVisual(
                bounds: bounds,
                level: community.level,
                mesh: edgeMesh,
                material: UnlitMaterial(color: UIColor(role.color)),
                goalOpacity: Float(opacity)
            )
            boundaryRoot.addChild(visual.entity)
            return visual
        }
    }

    private func makeSpace() -> Entity {
        guard let mesh = try? MeshResource.generate(from: [Self.domeDescriptor(radius: Constants.spaceRadius)]) else { return Entity() }
        return ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: UIColor(Color.defaultBlack))])
    }

    // The Workbench's galaxy: a faint, distant, slightly tilted band of dust
    // that sits well behind the graph.
    private func makeStars() -> Entity {
        var random = SystemRandomNumberGenerator()
        var positions: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        let corners: [SIMD3<Float>] = [SIMD3(1, 0, 0), SIMD3(-1, 0, 0), SIMD3(0, 1, 0), SIMD3(0, -1, 0), SIMD3(0, 0, 1), SIMD3(0, 0, -1)]
        let faces: [(UInt32, UInt32, UInt32)] = [(0, 2, 4), (2, 1, 4), (1, 3, 4), (3, 0, 4), (2, 0, 5), (1, 2, 5), (3, 1, 5), (0, 3, 5)]
        let tilt = simd_quatf(angle: Constants.starTilt, axis: SIMD3(0, 0, 1))

        for _ in 0..<Constants.starCount {
            let angle = Float.random(in: 0...(2 * .pi), using: &random)
            let radius = Float.random(in: Constants.starDistance, using: &random)
            let height = Float.random(in: -Constants.starBandHeight...Constants.starBandHeight, using: &random)
            let center = tilt.act(SIMD3(radius * cos(angle), height, radius * sin(angle)))
            let size = Float.random(in: Constants.starSize, using: &random)
            let base = UInt32(positions.count)
            positions += corners.map { center + $0 * size }
            // Both windings, so the stars draw whichever way the faces cull.
            for (a, b, c) in faces {
                indices += [base + a, base + b, base + c, base + a, base + c, base + b]
            }
        }

        var descriptor = MeshDescriptor(name: "stars")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.primitives = .triangles(indices)
        guard let mesh = try? MeshResource.generate(from: [descriptor]) else { return Entity() }
        return ModelEntity(mesh: mesh, materials: [Self.translucent(.defaultSkyBlue, opacity: .semiLowOpacity)])
    }

    // A flat, double-sided ring in the XY plane, facing +Z. An inner radius of
    // zero makes a disc.
    private static func ringMesh(inner: Float, outer: Float) -> MeshResource {
        let segments = Constants.ringSegments
        var positions: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        for segment in 0...segments {
            let angle = 2 * Float.pi * Float(segment) / Float(segments)
            let direction = SIMD3(cos(angle), sin(angle), 0)
            positions += [direction * inner, direction * outer]
        }
        for segment in 0..<segments {
            let a = UInt32(segment * 2)
            indices += [a, a + 1, a + 3, a, a + 3, a + 2, a, a + 3, a + 1, a, a + 2, a + 3]
        }
        var descriptor = MeshDescriptor(name: "ring")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.primitives = .triangles(indices)
        return (try? MeshResource.generate(from: [descriptor])) ?? MeshResource.generatePlane(width: outer * 2, height: outer * 2)
    }

    private static func domeDescriptor(radius: Float) -> MeshDescriptor {
        let rings = 16
        let segments = 32
        var positions: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        for ring in 0...rings {
            let theta = Float.pi * Float(ring) / Float(rings)
            for segment in 0...segments {
                let phi = 2 * Float.pi * Float(segment) / Float(segments)
                positions.append(SIMD3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi)) * radius)
            }
        }
        for ring in 0..<rings {
            for segment in 0..<segments {
                let a = UInt32(ring * (segments + 1) + segment)
                let b = a + UInt32(segments + 1)
                indices += [a, b, a + 1, a + 1, b, b + 1, a, a + 1, b, a + 1, b + 1, b]
            }
        }
        var descriptor = MeshDescriptor(name: "space")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.primitives = .triangles(indices)
        return descriptor
    }

    fileprivate static func translucent(_ color: Color, opacity: Double) -> UnlitMaterial {
        var material = UnlitMaterial(color: UIColor(color))
        material.blending = .transparent(opacity: .init(scale: Float(opacity)))
        return material
    }

    fileprivate enum Constants {
        static let near: Float = 0.5
        static let far: Float = 10000
        static let rimInner: Float = 0.62
        static let glowOuter: Float = 2.2
        static let ringSegments = 40
        static let glowPulse: Float = 0.1
        static let pulseSpeed: Float = 1.5
        static let heroPulse: Float = 0.3
        static let highlightThickness: Float = 2
        static let easing: Float = 9
        static let hiddenThreshold: Float = 0.01
        static let admitDelay: Float = 0.25
        static let admitDuration: Float = 0.9
        static let edgeRadius: Float = 0.12
        static let edgeWeightRadius: Float = 0.012
        static let boundaryRadius: Float = 0.16
        static let spaceRadius: Float = 5000
        static let starCount = 900
        static let starDistance: ClosedRange<Float> = 1600...2400
        static let starBandHeight: Float = 150
        static let starTilt: Float = 0.2
        static let starSize: ClosedRange<Float> = 0.8...1.8
        static let starDrift: Float = 0.005
    }
}

private final class NodeVisual {
    let entity = Entity()
    let rim: ModelEntity
    let glow: ModelEntity
    let rimMaterial: UnlitMaterial
    let glowMaterial: UnlitMaterial
    let position: SIMD3<Float>
    let radius: Float
    let admitAt: Float
    let phase = Float.random(in: 0...(2 * .pi))
    var scale: Float = 0
    var opacity: Float = 1
    var goalScale: Float
    var goalOpacity: Float = 1

    init(
        node: GraphNode,
        meshes: (rim: MeshResource, fill: MeshResource, glow: MeshResource),
        rim rimMaterial: UnlitMaterial,
        fill fillMaterial: UnlitMaterial,
        glow glowMaterial: UnlitMaterial,
        admitAt: Float
    ) {
        position = node.position
        radius = node.radius
        self.rimMaterial = rimMaterial
        self.glowMaterial = glowMaterial
        self.admitAt = admitAt
        goalScale = node.radius * GraphWorkbenchScene.nodeScale
        rim = ModelEntity(mesh: meshes.rim, materials: [rimMaterial])
        glow = ModelEntity(mesh: meshes.glow, materials: [glowMaterial])
        entity.position = node.position
        entity.scale = .zero
        entity.addChild(ModelEntity(mesh: meshes.fill, materials: [fillMaterial]))
        entity.addChild(glow)
        entity.addChild(rim)
    }
}

private final class LinkVisual {
    let link: GraphLink
    let entity: ModelEntity
    let isHero: Bool
    let length: Float
    let radius: Float
    let admitAt: Float
    let phase = Float.random(in: 0...(2 * .pi))
    var opacity: Float = 0
    var goalOpacity: Float = 0
    var thickness: Float = 1
    var goalThickness: Float = 1

    init(link: GraphLink, from start: SIMD3<Float>, to end: SIMD3<Float>, mesh: MeshResource, isHero: Bool, admitAt: Float) {
        self.link = link
        self.isHero = isHero
        self.admitAt = admitAt
        let span = end - start
        length = simd_length(span)
        radius = GraphWorkbenchScene.Constants.edgeRadius
            + Float(link.relationship.weight) * GraphWorkbenchScene.Constants.edgeWeightRadius
        entity = ModelEntity(mesh: mesh, materials: [])
        entity.position = (start + end) / 2
        if length > 0 {
            entity.orientation = simd_quatf(from: SIMD3(0, 1, 0), to: span / length)
        }
        entity.isEnabled = false
    }
}

private final class BoundaryVisual {
    let entity = Entity()
    let goalOpacity: Float
    var opacity: Float = 0

    init(bounds: GraphBounds, level: Int, mesh: MeshResource, material: UnlitMaterial, goalOpacity: Float) {
        self.goalOpacity = goalOpacity
        let half = bounds.size / 2
        let radius = GraphWorkbenchScene.Constants.boundaryRadius
        // A nudge per level keeps nested boxes from z-fighting.
        entity.position = bounds.center + SIMD3(0, 0, Float(level) * 0.1)
        entity.components.set(OpacityComponent(opacity: 0))

        for axis in 0..<3 {
            let other = [(axis + 1) % 3, (axis + 2) % 3]
            for signs in [(-1, -1), (-1, 1), (1, -1), (1, 1)] as [(Float, Float)] {
                var offset = SIMD3<Float>.zero
                offset[other[0]] = half[other[0]] * signs.0
                offset[other[1]] = half[other[1]] * signs.1
                var scale = SIMD3<Float>(radius, radius, radius)
                scale.y = bounds.size[axis]
                let edge = ModelEntity(mesh: mesh, materials: [material])
                edge.position = offset
                edge.scale = scale
                if axis == 0 {
                    edge.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3(0, 0, 1))
                } else if axis == 2 {
                    edge.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3(1, 0, 0))
                }
                entity.addChild(edge)
            }
        }
    }
}
