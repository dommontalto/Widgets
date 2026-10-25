//
//  BrightSandRendererV5.swift
//  Widgets
//

import Foundation
import Metal
import MetalKit
import simd

private final class BrightSandMTKViewMarkerV5: NSObject {}

final class BrightSandRendererV5: NSObject, MTKViewDelegate {

    var settings: BrightSandSettingsV5 {
        didSet {
            if let view, view.isPaused { view.draw() }
        }
    }

    private weak var view: MTKView?
    private let queue: MTLCommandQueue
    private let addPipeline: MTLRenderPipelineState
    private let subtractPipeline: MTLRenderPipelineState
    private let touchBuffer: MTLBuffer

    private var targetBuffer: MTLBuffer?
    private var count = 0
    private var buildKey = ""

    private var startedAt = CACurrentMediaTime()
    private var lastT = CACurrentMediaTime()
    private var pausedFor = 0.0
    private var pauseBegan = 0.0
    private var angle: Float = 0

    private struct Touch {
        var x: Float
        var y: Float
        var born: Double
    }
    private var touches: [Touch] = []

    @discardableResult
    private static func no(_ what: String) -> Bool {
        print("[BrightSandV5] cannot start: \(what)")
        return false
    }

    init?(view: MTKView, settings: BrightSandSettingsV5) {
        guard let device = view.device ?? MTLCreateSystemDefaultDevice() else {
            Self.no("this device has no Metal support")
            return nil
        }
        guard let queue = device.makeCommandQueue() else {
            Self.no("Metal would not give out a command queue")
            return nil
        }
        guard
            let library = (try? device.makeDefaultLibrary(bundle: Bundle(for: BrightSandMTKViewMarkerV5.self)))
                ?? (try? device.makeDefaultLibrary(bundle: Bundle.main))
                ?? device.makeDefaultLibrary()
        else {
            Self.no("BrightSandShadersV5.metal is not compiled into the app — add it to the target's Compile Sources, not Copy Bundle Resources")
            return nil
        }
        guard
            let vfn = library.makeFunction(name: "brightSandVertexV5"),
            let ffn = library.makeFunction(name: "brightSandFragmentV5")
        else {
            Self.no("the shader functions are not in the compiled Metal library — BrightSandShadersV5.metal is in the wrong build phase")
            return nil
        }
        guard
            let touchBuffer = device.makeBuffer(
                length: MemoryLayout<SIMD4<Float>>.stride * brightSandTouchSlotsV5,
                options: .storageModeShared)
        else {
            Self.no("Metal would not give out the touch buffer")
            return nil
        }

        func pipeline(_ op: MTLBlendOperation) -> MTLRenderPipelineState? {
            let d = MTLRenderPipelineDescriptor()
            d.vertexFunction = vfn
            d.fragmentFunction = ffn
            guard let a = d.colorAttachments[0] else { return nil }
            a.pixelFormat = view.colorPixelFormat
            a.isBlendingEnabled = true
            a.rgbBlendOperation = op
            a.alphaBlendOperation = op
            a.sourceRGBBlendFactor = .one
            a.destinationRGBBlendFactor = .one
            a.sourceAlphaBlendFactor = .one
            a.destinationAlphaBlendFactor = .one
            a.writeMask = .all
            return try? device.makeRenderPipelineState(descriptor: d)
        }
        guard let add = pipeline(.add), let sub = pipeline(.reverseSubtract) else {
            Self.no("the render pipeline would not build — the shaders compiled but do not match this view's pixel format")
            return nil
        }

        self.view = view
        self.queue = queue
        self.addPipeline = add
        self.subtractPipeline = sub
        self.touchBuffer = touchBuffer
        self.settings = settings
        super.init()
    }

    private func syncTargets(_ device: MTLDevice) {
        let wanted = max(1, Int(settings.particleCount.rounded()))
        let image = settings.shape == "Logo" ? BrightSandImagesV5.cgImage(settings.logo) : nil
        let key = "\(wanted)|\(image == nil ? "Text" : "Logo")|\(settings.shapeText)|\(settings.logo)|\(settings.seed)"
        if key == buildKey, targetBuffer != nil { return }
        buildKey = key
        count = wanted
        let data = BrightSandMaskV5.render(text: settings.shapeText, image: image)
        let targets = BrightSandMaskV5.targets(count: wanted, data: data, seed: settings.seed)
        targetBuffer = targets.withUnsafeBytes {
            device.makeBuffer(bytes: $0.baseAddress!, length: $0.count, options: .storageModeShared)
        }
    }

    func touch(x: Float, y: Float) {
        touches.append(Touch(x: x * 2 - 1, y: 1 - y * 2, born: CACurrentMediaTime()))
        if touches.count > brightSandTouchSlotsV5 {
            touches.removeFirst(touches.count - brightSandTouchSlotsV5)
        }
        if let view, view.isPaused { view.draw() }
    }

    func setPaused(_ paused: Bool) {
        guard let view, view.isPaused != paused else { return }
        if paused {
            pauseBegan = CACurrentMediaTime()
            view.isPaused = true
            view.draw()
        } else {
            pausedFor += CACurrentMediaTime() - pauseBegan
            lastT = CACurrentMediaTime()
            view.isPaused = false
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        if view.isPaused { view.draw() }
    }

    func draw(in view: MTKView) {
        // A held finger is pressed in afresh every frame, so the grains stay parted under it.
        if let sand = view as? BrightSandMTKViewV5 {
            for point in sand.heldPoints.values { touch(x: point.x, y: point.y) }
        }
        let ground = BrightSandMaskV5.rgb(settings.bg)
        // Over a transparent ground the grains just add up in their own colour.
        let onLight = !settings.transparent && BrightSandMaskV5.onLight(ground)
        view.clearColor = settings.transparent
            ? MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            : MTLClearColor(red: Double(ground.x), green: Double(ground.y), blue: Double(ground.z), alpha: 1)

        guard let device = view.device else { return }
        syncTargets(device)
        guard let targetBuffer else { return }

        guard
            let drawable = view.currentDrawable,
            let pass = view.currentRenderPassDescriptor,
            let buffer = queue.makeCommandBuffer()
        else { return }

        let now = CACurrentMediaTime()
        let dt = min(0.05, max(0, now - lastT))
        lastT = now
        let t = (view.isPaused ? pauseBegan : now) - startedAt - pausedFor

        touches.removeAll { now - $0.born >= Double(settings.touchLife) }

        let morph = BrightSandMaskV5.morphAt(
            t, scatterHold: settings.scatterHold, gatherTime: settings.gatherTime,
            shapeHold: settings.shapeHold, disperseTime: settings.disperseTime,
            loop: settings.loop)

        if !view.isPaused && settings.rotate {
            angle += settings.spin * Float(dt) * (1 - morph)
            angle = atan2(sin(angle), cos(angle))
        }
        if !settings.rotate {
            angle = 0
        }
        let swing = settings.rotate
            ? BrightSandMaskV5.swingAt(
                t, scatterHold: settings.scatterHold, gatherTime: settings.gatherTime,
                shapeHold: settings.shapeHold, disperseTime: settings.disperseTime,
                iconSpin: Double(settings.iconSpin), loop: settings.loop)
            : 0

        let pixels = view.drawableSize
        let dpr = Float(view.contentScaleFactor)
        let minSide = Float(min(pixels.width, pixels.height))

        func ink(_ hex: String) -> SIMD4<Float> {
            let c = BrightSandMaskV5.rgb(hex)
            let v = onLight ? ground - c : c
            return SIMD4(v.x, v.y, v.z, 1)
        }

        var u = BrightSandUniformsV5()
        u.uBackColor = ink(settings.backColor)
        u.uGlowColor = ink(settings.glowColor)
        u.uFrontColor = ink(settings.frontColor)
        u.uRotation = angle * (1 - morph)
        u.uSpin = 0
        u.uRadius = settings.radius
        u.uStrength = settings.strength
        u.uDecay = settings.decay
        u.uTurbulence = settings.turbulence
        u.uPointSizeScale = settings.pointSizeScale
        u.uAspect = Float(pixels.width) / Float(max(1, pixels.height))
        u.uPointScale = max(1, (minSide / 900) * dpr * 1.4)
        u.uTime = Float(t)
        u.uMorph = morph
        u.uIconScale = settings.iconScale
        u.uIconDepth = settings.iconDepth
        u.uIconScatter = settings.iconScatter
        u.uIconDrift = settings.iconDrift
        u.uIconTilt = settings.iconTilt
        u.uIconGlow = settings.iconGlow
        u.uIconStagger = settings.iconStagger
        u.uIconSize = settings.iconSize
        u.uIconAngle = swing * settings.iconSwing
        u.uIconWobble = settings.rotate ? settings.iconWobble : 0
        u.uTouchStrength = settings.touchStrength
        u.uTouchRadius = settings.touchRadius
        u.uTouchFade = settings.touchFade
        u.uTouchNoise = settings.touchNoise
        u.uTouchOnIcon = settings.touchOnIcon
        u.uTouchCount = Int32(touches.count)

        let slots = touchBuffer.contents().bindMemory(
            to: SIMD4<Float>.self, capacity: brightSandTouchSlotsV5)
        for i in 0..<brightSandTouchSlotsV5 {
            slots[i] =
                i < touches.count
                ? SIMD4(touches[i].x, touches[i].y, Float(now - touches[i].born), 0)
                : SIMD4(repeating: 0)
        }

        guard let encoder = buffer.makeRenderCommandEncoder(descriptor: pass) else { return }
        encoder.setRenderPipelineState(onLight ? subtractPipeline : addPipeline)
        encoder.setVertexBuffer(targetBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&u, length: MemoryLayout<BrightSandUniformsV5>.stride, index: 1)
        encoder.setVertexBuffer(touchBuffer, offset: 0, index: 2)
        encoder.setFragmentBytes(&u, length: MemoryLayout<BrightSandUniformsV5>.stride, index: 1)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: count)
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }
}

enum BrightSandImagesV5 {
    // "symbol:map" shapes the sand from an SF Symbol instead of an image in the bundle.
    static let symbolPrefix = "symbol:"

    private static var cache: [String: CGImage?] = [:]

    private static func symbol(_ name: String) -> CGImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 400, weight: .regular)
        guard let glyph = UIImage(systemName: name, withConfiguration: config)?
            .withTintColor(.black, renderingMode: .alwaysOriginal) else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: glyph.size, format: format).image { _ in
            glyph.draw(at: .zero)
        }.cgImage
    }

    static func cgImage(_ name: String) -> CGImage? {
        if name.isEmpty { return nil }
        if let hit = cache[name] { return hit }
        let base = (name as NSString).deletingPathExtension
        let image = name.hasPrefix(symbolPrefix)
            ? symbol(String(name.dropFirst(symbolPrefix.count)))
            : UIImage(named: name)?.cgImage ?? UIImage(named: base)?.cgImage
        cache[name] = image
        return image
    }
}
