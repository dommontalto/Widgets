//
//  GraphWorkbenchCamera.swift
//  Widgets
//
//  Created by Dom Montalto on 28/9/2026.
//

import SwiftUI
import simd

// An orbit camera the scene eases toward every frame. Gestures move the goal;
// the rendered values chase it, so drags, pinches and focus changes all glide.
// It also projects world points to the view, which the labels and tap picking
// both rely on.
@Observable
final class GraphWorkbenchCamera {
    private(set) var yaw: Float
    private(set) var pitch: Float
    private(set) var distance: Float
    private(set) var target: SIMD3<Float>
    var viewSize: CGSize = .zero

    @ObservationIgnored private var goalYaw: Float
    @ObservationIgnored private var goalPitch: Float
    @ObservationIgnored private var goalDistance: Float
    @ObservationIgnored private var goalTarget: SIMD3<Float>
    @ObservationIgnored private var isAutoOrbiting = true
    @ObservationIgnored private var gestureStartDistance: Float?
    @ObservationIgnored private let home: SIMD3<Float>
    @ObservationIgnored private let homeDistance: Float

    let fieldOfView: Float = Constants.fieldOfView

    init(layout: GraphLayout) {
        home = layout.center
        homeDistance = max(layout.extent * Constants.fitFactor, Constants.minimumHomeDistance)
        yaw = Constants.startYaw
        pitch = Constants.startPitch
        distance = homeDistance * Constants.introZoom
        target = layout.center
        goalYaw = Constants.startYaw
        goalPitch = Constants.startPitch
        goalDistance = homeDistance
        goalTarget = layout.center
    }

    var eye: SIMD3<Float> {
        target + SIMD3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw)) * distance
    }

    var orientation: simd_quatf {
        let forward = simd_normalize(target - eye)
        let right = simd_normalize(simd_cross(forward, SIMD3(0, 1, 0)))
        let up = simd_cross(right, forward)
        return simd_quatf(simd_float3x3(columns: (right, up, -forward)))
    }

    func step(deltaTime: Float) {
        if isAutoOrbiting {
            goalYaw += Constants.autoOrbitSpeed * deltaTime
        }
        let blend = 1 - exp(-Constants.easing * deltaTime)
        yaw += (goalYaw - yaw) * blend
        pitch += (goalPitch - pitch) * blend
        distance += (goalDistance - distance) * blend
        target += (goalTarget - target) * blend
    }

    func orbit(by translation: CGSize) {
        isAutoOrbiting = false
        goalYaw -= Float(translation.width) * Constants.orbitSensitivity
        goalPitch = min(max(goalPitch + Float(translation.height) * Constants.orbitSensitivity, -Constants.pitchLimit), Constants.pitchLimit)
    }

    func zoom(by magnification: CGFloat) {
        isAutoOrbiting = false
        let start = gestureStartDistance ?? goalDistance
        gestureStartDistance = start
        goalDistance = min(max(start / Float(magnification), Constants.minimumDistance), homeDistance * Constants.maximumZoomOut)
    }

    func endZoom() {
        gestureStartDistance = nil
    }

    func focus(on point: SIMD3<Float>) {
        isAutoOrbiting = false
        goalTarget = point
        goalDistance = min(goalDistance, homeDistance * Constants.focusZoom)
    }

    func recenter() {
        goalTarget = home
        goalDistance = homeDistance
        goalPitch = Constants.startPitch
    }

    // The view point and depth of a world point, or nil when it's behind the camera.
    func project(_ point: SIMD3<Float>) -> (point: CGPoint, depth: Float)? {
        guard viewSize.width > 0, viewSize.height > 0 else { return nil }
        let forward = simd_normalize(target - eye)
        let right = simd_normalize(simd_cross(forward, SIMD3(0, 1, 0)))
        let up = simd_cross(right, forward)
        let offset = point - eye
        let depth = simd_dot(offset, forward)
        guard depth > Constants.nearPlane else { return nil }

        let focal = Float(viewSize.height) / 2 / tan(fieldOfView * .pi / 360)
        let x = Float(viewSize.width) / 2 + simd_dot(offset, right) / depth * focal
        let y = Float(viewSize.height) / 2 - simd_dot(offset, up) / depth * focal
        return (CGPoint(x: CGFloat(x), y: CGFloat(y)), depth)
    }

    // Points on screen per world unit at a given depth.
    func scale(atDepth depth: Float) -> CGFloat {
        CGFloat(Float(viewSize.height) / 2 / tan(fieldOfView * .pi / 360) / depth)
    }

    private enum Constants {
        static let fieldOfView: Float = 50
        static let fitFactor: Float = 2.6
        static let minimumHomeDistance: Float = 200
        static let introZoom: Float = 1.8
        static let startYaw: Float = 0.7
        static let startPitch: Float = 0.35
        static let pitchLimit: Float = 1.45
        static let autoOrbitSpeed: Float = 0.05
        static let easing: Float = 7
        static let orbitSensitivity: Float = 0.006
        static let minimumDistance: Float = 25
        static let maximumZoomOut: Float = 2.5
        static let focusZoom: Float = 0.55
        static let nearPlane: Float = 1
    }
}
