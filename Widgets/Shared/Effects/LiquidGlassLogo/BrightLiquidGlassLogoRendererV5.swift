//
//  BrightLiquidGlassLogoRendererV5.swift
//  Widgets
//
//  Created by Dom Montalto on 23/10/2026.
//
//  Adapted from ReactDrops Liquid Glass Logo, see THIRD_PARTY_LICENSES.md.
//

import MetalKit
import QuartzCore
import simd
import UIKit

struct BrightLiquidGlassLogoConfigV5 {
    var logoSize: Float = 80
    var logoScale: Float = 0.72
    var finalLogoScale: Float = 1
    var tileColor = SIMD3<Float>(0, 7, 20) / 255
    var background = SIMD3<Float>(0, 0, 0)
    var tile = true
    var depth: Float = 0.7
    var dispersion: Float = 2.2
    var relief: Float = 1
    var caustics: Float = 1.65
    var highlights: Float = 1.35
    var bloom: Float = 0.55
    var dropStrength: Float = 1.8
    var echoTint: Float = 0.31
    var innerWallFocus: Float = 0.14
    var speed: Float = 1
    var maxScale: CGFloat = 2
}

private struct BrightLiquidGlassLogoRenderUniforms {
    var tile: SIMD4<Float>
    var resolution: SIMD2<Float>
    var logoBox: SIMD2<Float>
    var dpr: Float
    var unit: Float
    var time: Float
    var settle: Float
    var artScale: Float
    var tileEnabled: Float
    var pageLight: Float
    var depth: Float
    var dispersion: Float
    var relief: Float
    var caustics: Float
    var highlights: Float
    var echoTint: Float
    var innerWallFocus: Float
    var dropStrength: Float
}

private struct BrightLiquidGlassLogoCompositeUniforms {
    var resolution: SIMD2<Float>
    var dpr: Float
    var unit: Float
    var settle: Float
    var bloom: Float
    var time: Float
    var finish: Float
    var pageLight: Float
    var page: SIMD4<Float>
}

private enum BrightLiquidGlassLogoTimeline {
    static let finishTime: Float = 1.8
    static let maxFrameStep: Double = 0.05

    // Artwork size under the glass relative to its resting size, as [time, scale] keys.
    static let artworkScale: [(Float, Float)] = [
        (0.12, 1.4), (0.33, 1.45), (0.46, 1.44), (0.63, 1.33), (0.79, 1.24), (0.96, 1.2),
        (1.13, 1.11), (1.25, 1.0), (1.335, 0.865), (1.376, 0.81), (1.418, 0.735), (1.46, 0.41),
    ]

    // Catmull-Rom through unevenly spaced keys.
    static func track(_ keys: [(Float, Float)], _ t: Float) -> Float {
        guard let first = keys.first, let last = keys.last else { return 0 }
        if t <= first.0 { return first.1 }
        if t >= last.0 { return last.1 }
        var i = 0
        while t > keys[i + 1].0 { i += 1 }
        let (t1, v1) = keys[i]
        let (t2, v2) = keys[i + 1]
        let (t0, v0) = i > 0 ? keys[i - 1] : (t1 - (t2 - t1), v1)
        let (t3, v3) = i + 2 < keys.count ? keys[i + 2] : (t2 + (t2 - t1), v2)
        let span = t2 - t1
        let m1 = (v2 - v0) / (t2 - t0) * span
        let m2 = (v3 - v1) / (t3 - t1) * span
        let x = (t - t1) / span
        let x2 = x * x
        let x3 = x2 * x
        return (2 * x3 - 3 * x2 + 1) * v1 + (x3 - 2 * x2 + x) * m1 + (-2 * x3 + 3 * x2) * v2 + (x3 - x2) * m2
    }

    static func smooth(_ from: Float, _ to: Float, _ value: Float) -> Float {
        let x = min(1, max(0, (value - from) / (to - from)))
        return x * x * (3 - 2 * x)
    }

    static func clamp01(_ value: Float) -> Float { min(1, max(0, value)) }
}

// Sphere-to-tile glass entrance over the logo: a spectral scene pass into a
// mipmapped offscreen texture, then a bloom and grain composite onto black.
@MainActor
final class BrightLiquidGlassLogoRendererV5: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let renderPipeline: MTLRenderPipelineState
    private let compositePipeline: MTLRenderPipelineState
    private let logoTexture: MTLTexture
    private var sceneTexture: MTLTexture?
    private let config: BrightLiquidGlassLogoConfigV5

    var reduceMotion: Bool
    private var clock: Double = 0
    private var lastFrame: CFTimeInterval = 0

    init?(view: MTKView, logo: UIImage, config: BrightLiquidGlassLogoConfigV5, reduceMotion: Bool) {
        guard let device = view.device,
              let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary() else { return nil }

        func pipeline(_ fragment: String, format: MTLPixelFormat) -> MTLRenderPipelineState? {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: "brightLiquidGlassLogoVertex")
            descriptor.fragmentFunction = library.makeFunction(name: fragment)
            descriptor.colorAttachments[0].pixelFormat = format
            return try? device.makeRenderPipelineState(descriptor: descriptor)
        }

        guard let renderPipeline = pipeline("brightLiquidGlassLogoRender", format: .rgba8Unorm),
              let compositePipeline = pipeline("brightLiquidGlassLogoComposite", format: view.colorPixelFormat),
              let logoTexture = Self.makeLogoTexture(device: device, queue: queue, logo: logo, config: config)
        else { return nil }

        self.device = device
        self.queue = queue
        self.renderPipeline = renderPipeline
        self.compositePipeline = compositePipeline
        self.logoTexture = logoTexture
        self.config = config
        self.reduceMotion = reduceMotion
        super.init()
    }

    // The logo fills logoScale of a square texture one plate edge wide, premultiplied like the WebGL upload.
    private static func makeLogoTexture(device: MTLDevice, queue: MTLCommandQueue, logo: UIImage,
                                        config: BrightLiquidGlassLogoConfigV5) -> MTLTexture? {
        let wanted = CGFloat(config.logoSize) * config.maxScale * 2
        let size = min(2048, Int(pow(2, ceil(log2(max(2, wanted))))))
        let bytesPerRow = size * 4
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * size)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: size, height: size,
                                          bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return false }
            context.translateBy(x: 0, y: CGFloat(size))
            context.scaleBy(x: 1, y: -1)
            context.interpolationQuality = .high
            let imageSize = logo.size
            let fit = CGFloat(size) * CGFloat(config.logoScale) / max(imageSize.width, imageSize.height, 1)
            let w = imageSize.width * fit
            let h = imageSize.height * fit
            UIGraphicsPushContext(context)
            logo.draw(in: CGRect(x: (CGFloat(size) - w) / 2, y: (CGFloat(size) - h) / 2, width: w, height: h))
            UIGraphicsPopContext()
            return true
        }
        guard drawn else { return nil }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: size,
                                                                  height: size, mipmapped: true)
        descriptor.usage = [.shaderRead]
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        pixels.withUnsafeBytes { buffer in
            if let base = buffer.baseAddress {
                texture.replace(region: MTLRegionMake2D(0, 0, size, size), mipmapLevel: 0,
                                withBytes: base, bytesPerRow: bytesPerRow)
            }
        }
        guard let cmd = queue.makeCommandBuffer(), let blit = cmd.makeBlitCommandEncoder() else { return nil }
        blit.generateMipmaps(for: texture)
        blit.endEncoding()
        cmd.commit()
        return texture
    }

    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        MainActor.assumeIsolated { self.resize(size) }
    }

    nonisolated func draw(in view: MTKView) {
        MainActor.assumeIsolated { self.render(view) }
    }

    private func resize(_ size: CGSize) {
        let width = max(Int(size.width), 1)
        let height = max(Int(size.height), 1)
        if let sceneTexture, sceneTexture.width == width, sceneTexture.height == height { return }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width,
                                                                  height: height, mipmapped: true)
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        sceneTexture = device.makeTexture(descriptor: descriptor)
    }

    private func render(_ view: MTKView) {
        let points = view.bounds.size
        let drawableSize = view.drawableSize
        guard points.width > 0, points.height > 0, drawableSize.width > 0 else { return }
        resize(drawableSize)
        guard let sceneTexture,
              let drawable = view.currentDrawable,
              let finalPass = view.currentRenderPassDescriptor,
              let cmd = queue.makeCommandBuffer() else { return }

        let now = CACurrentMediaTime()
        let delta = lastFrame == 0 ? 0 : min(BrightLiquidGlassLogoTimeline.maxFrameStep, now - lastFrame)
        lastFrame = now
        if !reduceMotion { clock += delta * Double(config.speed) }

        let finishTime = BrightLiquidGlassLogoTimeline.finishTime
        let sequenceTime = reduceMotion ? finishTime : Float(clock)
        let displayTime = min(finishTime, sequenceTime)

        let width = Float(points.width)
        let height = Float(points.height)
        // Room for the side reflections as they travel away from the plate.
        let scale = min(1, width / (config.logoSize * 1.9), height / (config.logoSize * 1.5))
        let unit = config.logoSize * scale
        let dpr = Float(drawableSize.width) / width
        let resolution = SIMD2<Float>(Float(drawableSize.width), Float(drawableSize.height))

        let settle = BrightLiquidGlassLogoTimeline.clamp01((sequenceTime - 1.16) / (1.4 - 1.16))
        let artworkSettle = BrightLiquidGlassLogoTimeline.smooth(1.13, 1.28, sequenceTime)
        let artScale = sequenceTime > 1.13
            ? BrightLiquidGlassLogoTimeline.track(BrightLiquidGlassLogoTimeline.artworkScale, 1.13) * (1 - artworkSettle)
                + config.finalLogoScale * artworkSettle
            : BrightLiquidGlassLogoTimeline.track(BrightLiquidGlassLogoTimeline.artworkScale, displayTime)
        let page = config.background
        let pageLuma = 0.299 * page.x + 0.587 * page.y + 0.114 * page.z
        let pageLight = BrightLiquidGlassLogoTimeline.clamp01((pageLuma - 0.35) / 0.4)
        let finish = BrightLiquidGlassLogoTimeline.clamp01((sequenceTime - 1.05) / (finishTime - 1.05))

        var renderUniforms = BrightLiquidGlassLogoRenderUniforms(
            tile: SIMD4(config.tileColor, 1), resolution: resolution, logoBox: SIMD2(repeating: unit),
            dpr: dpr, unit: unit, time: displayTime, settle: settle, artScale: artScale,
            tileEnabled: config.tile ? 1 : 0, pageLight: pageLight, depth: config.depth,
            dispersion: config.dispersion, relief: config.relief, caustics: config.caustics,
            highlights: config.highlights, echoTint: config.echoTint, innerWallFocus: config.innerWallFocus,
            dropStrength: config.dropStrength
        )
        var compositeUniforms = BrightLiquidGlassLogoCompositeUniforms(
            resolution: resolution, dpr: dpr, unit: unit, settle: settle, bloom: config.bloom,
            time: displayTime, finish: finish, pageLight: pageLight, page: SIMD4(config.background, 1)
        )

        let scenePass = MTLRenderPassDescriptor()
        scenePass.colorAttachments[0].texture = sceneTexture
        scenePass.colorAttachments[0].loadAction = .clear
        scenePass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
        scenePass.colorAttachments[0].storeAction = .store
        if let encoder = cmd.makeRenderCommandEncoder(descriptor: scenePass) {
            encoder.setRenderPipelineState(renderPipeline)
            encoder.setFragmentTexture(logoTexture, index: 0)
            encoder.setFragmentBytes(&renderUniforms, length: MemoryLayout<BrightLiquidGlassLogoRenderUniforms>.stride, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.endEncoding()
        }

        // The mip pyramid supplies soft light at several scales without a blur kernel.
        if let blit = cmd.makeBlitCommandEncoder() {
            blit.generateMipmaps(for: sceneTexture)
            blit.endEncoding()
        }

        if let encoder = cmd.makeRenderCommandEncoder(descriptor: finalPass) {
            encoder.setRenderPipelineState(compositePipeline)
            encoder.setFragmentTexture(sceneTexture, index: 0)
            encoder.setFragmentBytes(&compositeUniforms, length: MemoryLayout<BrightLiquidGlassLogoCompositeUniforms>.stride, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.endEncoding()
        }

        cmd.present(drawable)
        cmd.commit()

        if sequenceTime >= finishTime {
            holdFinalFrame(view)
        }
    }

    // Once the logo rests, only resizes redraw it.
    private func holdFinalFrame(_ view: MTKView) {
        guard !view.isPaused else { return }
        view.isPaused = true
        view.enableSetNeedsDisplay = true
        lastFrame = 0
    }
}
