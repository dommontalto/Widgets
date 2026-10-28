//
//  GenomeMetalMath.swift
//  DNA
//
//  SIMD matrix helpers for the Metal chrome-helix renderer.
//

import simd
import CoreGraphics

private extension SIMD4 where Scalar == Float {
    var xyz: SIMD3<Float> { SIMD3(x, y, z) }
}

enum GenomeMetalMath {
    static func perspective(fovYRadians fovY: Float, aspect: Float, near: Float, far: Float) -> float4x4 {
        let ys = 1 / tan(fovY * 0.5)
        let xs = ys / aspect
        let zs = far / (near - far)
        return float4x4(columns: (
            SIMD4<Float>(xs, 0, 0, 0),
            SIMD4<Float>(0, ys, 0, 0),
            SIMD4<Float>(0, 0, zs, -1),
            SIMD4<Float>(0, 0, zs * near, 0)
        ))
    }

    static func lookAt(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) -> float4x4 {
        let f = simd_normalize(center - eye)
        let s = simd_normalize(simd_cross(f, up))
        let u = simd_cross(s, f)
        return float4x4(columns: (
            SIMD4<Float>(s.x, u.x, -f.x, 0),
            SIMD4<Float>(s.y, u.y, -f.y, 0),
            SIMD4<Float>(s.z, u.z, -f.z, 0),
            SIMD4<Float>(-simd_dot(s, eye), -simd_dot(u, eye), simd_dot(f, eye), 1)
        ))
    }

    static func projectFront(_ p: SIMD3<Float>, mvp: float4x4, viewport: CGSize) -> (CGPoint, Bool) {
        let clip = mvp * SIMD4<Float>(p, 1)
        guard clip.w > 0 else { return (.zero, false) }
        let ndc = clip.xyz / clip.w
        let x = (ndc.x * 0.5 + 0.5) * Float(viewport.width)
        let y = (1 - (ndc.y * 0.5 + 0.5)) * Float(viewport.height)
        let inFront = ndc.z >= 0 && ndc.z <= 1
        return (CGPoint(x: Double(x), y: Double(y)), inFront)
    }

    static func project(_ p: SIMD3<Float>, mvp: float4x4, viewport: CGSize) -> (CGPoint, Bool) {
        let clip = mvp * SIMD4<Float>(p, 1)
        guard clip.w > 0 else { return (.zero, false) }
        let ndc = clip.xyz / clip.w
        let x = (ndc.x * 0.5 + 0.5) * Float(viewport.width)
        let y = (1 - (ndc.y * 0.5 + 0.5)) * Float(viewport.height)
        let onScreen = ndc.x >= -1 && ndc.x <= 1 && ndc.y >= -1 && ndc.y <= 1 && ndc.z >= 0 && ndc.z <= 1
        return (CGPoint(x: Double(x), y: Double(y)), onScreen)
    }
}
