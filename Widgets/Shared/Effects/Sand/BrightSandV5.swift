//
//  BrightSandV5.swift
//  Widgets
//

import MetalKit
import SwiftUI

public struct BrightSandSettingsV5 {
    public var shape         : String = "Logo"
    public var shapeText     : String = "ATLAS"
    public var logo          : String = ""
    public var loop          : Bool = false
    public var rotate        : Bool = false
    public var touchStrength : Float = 0.068
    public var touchRadius   : Float = 0.35
    public var touchLife     : Float = 2.8
    public var touchFade     : Float = 4.75
    public var touchNoise    : Float = 2.45
    public var touchOnIcon   : Float = 0.9
    public var iconScale     : Float = 1.03
    public var iconDepth     : Float = 0.28
    public var iconSwing     : Float = 0.6
    public var iconSpin      : Float = 0.45
    public var iconWobble    : Float = 0.05
    public var iconTilt      : Float = 0
    public var iconScatter   : Float = 0
    public var iconDrift     : Float = 0.045
    public var iconGlow      : Float = 0.95
    public var iconSize      : Float = 0.75
    public var iconStagger   : Float = 0.35
    public var scatterHold   : Double = 1.7
    public var gatherTime    : Double = 6.6
    public var shapeHold     : Double = 2.4
    public var disperseTime  : Double = 1.8
    public var particleCount : Float = 100000
    public var pointSizeScale: Float = 0.9
    public var radius        : Float = 0.69
    public var spin          : Float = 0.22
    public var turbulence    : Float = 0.7
    public var strength      : Float = 1.25
    public var decay         : Float = 1.2
    public var bg            : String = "#05060a"
    public var backColor     : String = "#FFFFFF"
    public var glowColor     : String = "#FFFFFF"
    public var frontColor    : String = "#FFFFFF"
    public var seed          : Int = 1
    public var transparent   : Bool = false

    public init() {}
}

public final class BrightSandMTKViewV5: MTKView {
    var onTouch: ((Float, Float) -> Void)?
    // Fingers still down, so a press-and-hold keeps pushing the grains away until it lifts.
    private(set) var heldPoints: [ObjectIdentifier: SIMD2<Float>] = [:]

    private func report(_ touches: Set<UITouch>) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        for t in touches {
            let p = t.location(in: self)
            onTouch?(Float(p.x / bounds.width), Float(p.y / bounds.height))
        }
    }

    private func hold(_ touches: Set<UITouch>) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        for t in touches {
            let p = t.location(in: self)
            heldPoints[ObjectIdentifier(t)] = SIMD2(Float(p.x / bounds.width), Float(p.y / bounds.height))
        }
    }

    private func release(_ touches: Set<UITouch>) {
        for t in touches { heldPoints[ObjectIdentifier(t)] = nil }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        hold(touches)
        report(touches)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        hold(touches)
        report(touches)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        release(touches)
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        release(touches)
    }
}

public struct BrightSandV5: UIViewRepresentable {
    public var settings: BrightSandSettingsV5

    public init(
        shape: String = "Logo",
        shapeText: String = "ATLAS",
        logo: String = "",
        loop: Bool = false,
        rotate: Bool = false,
        touchStrength: Float = 0.068,
        touchRadius: Float = 0.35,
        touchLife: Float = 2.8,
        touchFade: Float = 4.75,
        touchNoise: Float = 2.45,
        touchOnIcon: Float = 0.9,
        iconScale: Float = 1.03,
        iconDepth: Float = 0.28,
        iconSwing: Float = 0.6,
        iconSpin: Float = 0.45,
        iconWobble: Float = 0.05,
        iconTilt: Float = 0,
        iconScatter: Float = 0,
        iconDrift: Float = 0.045,
        iconGlow: Float = 0.95,
        iconSize: Float = 0.75,
        iconStagger: Float = 0.35,
        scatterHold: Double = 1.7,
        gatherTime: Double = 6.6,
        shapeHold: Double = 2.4,
        disperseTime: Double = 1.8,
        particleCount: Float = 100000,
        pointSizeScale: Float = 0.9,
        radius: Float = 0.69,
        spin: Float = 0.22,
        turbulence: Float = 0.7,
        strength: Float = 1.25,
        decay: Float = 1.2,
        bg: String = "#05060a",
        backColor: String = "#FFFFFF",
        glowColor: String = "#FFFFFF",
        frontColor: String = "#FFFFFF",
        seed: Int = 1,
        transparent: Bool = false
    ) {
        var s = BrightSandSettingsV5()
        s.shape          = shape
        s.shapeText      = shapeText
        s.logo           = logo
        s.loop           = loop
        s.rotate         = rotate
        s.touchStrength  = touchStrength
        s.touchRadius    = touchRadius
        s.touchLife      = touchLife
        s.touchFade      = touchFade
        s.touchNoise     = touchNoise
        s.touchOnIcon    = touchOnIcon
        s.iconScale      = iconScale
        s.iconDepth      = iconDepth
        s.iconSwing      = iconSwing
        s.iconSpin       = iconSpin
        s.iconWobble     = iconWobble
        s.iconTilt       = iconTilt
        s.iconScatter    = iconScatter
        s.iconDrift      = iconDrift
        s.iconGlow       = iconGlow
        s.iconSize       = iconSize
        s.iconStagger    = iconStagger
        s.scatterHold    = scatterHold
        s.gatherTime     = gatherTime
        s.shapeHold      = shapeHold
        s.disperseTime   = disperseTime
        s.particleCount  = particleCount
        s.pointSizeScale = pointSizeScale
        s.radius         = radius
        s.spin           = spin
        s.turbulence     = turbulence
        s.strength       = strength
        s.decay          = decay
        s.bg             = bg
        s.backColor      = backColor
        s.glowColor      = glowColor
        s.frontColor     = frontColor
        s.seed           = seed
        s.transparent    = transparent
        self.settings = s
    }

    public final class Coordinator {
        var renderer: BrightSandRendererV5?
    }

    public func makeCoordinator() -> Coordinator { Coordinator() }

    public func makeUIView(context: Context) -> BrightSandMTKViewV5 {
        let view = BrightSandMTKViewV5(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.colorPixelFormat = .bgra8Unorm
        view.framebufferOnly = true
        view.preferredFramesPerSecond = 60
        view.isMultipleTouchEnabled = true
        view.isOpaque = !settings.transparent
        view.backgroundColor = settings.transparent ? .clear : nil
        view.contentScaleFactor = min(UIScreen.main.scale, 2)
        let renderer = BrightSandRendererV5(view: view, settings: settings)
        view.delegate = renderer
        view.onTouch = { [weak renderer] x, y in renderer?.touch(x: x, y: y) }
        context.coordinator.renderer = renderer
        return view
    }

    public func updateUIView(_ view: BrightSandMTKViewV5, context: Context) {
        context.coordinator.renderer?.settings = settings
    }
}

#Preview {
    BrightSandV5()
        .ignoresSafeArea()
}
