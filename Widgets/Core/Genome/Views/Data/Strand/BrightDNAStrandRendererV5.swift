//
//  BrightDNAStrandRendererV5.swift
//  Widgets
//
//  Created by Dom Montalto on 21/10/2026.
//

import MetalKit
import simd

private struct BrightDNAStrandUniforms {
    var mvp: simd_float4x4
    var cameraPos: simd_float3
    var time: Float
    var height: Float
    var focusY: Float
    var focusWidth: Float
}

// Orbit camera, rolled 30° and looking up 30° so the strand leans back, over
// the instanced bead strand: HDR scene pass, an eased lit zone, 4-level bloom,
// a soft blur over both ends, ACES composite, idle auto-rotation, and per-frame
// rung projection for the annotations and tap picking.
@MainActor
final class BrightDNAStrandRendererV5: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let queue: MTLCommandQueue

    private var scenePipeline: MTLRenderPipelineState!
    private var brightPipeline: MTLRenderPipelineState!
    private var blurPipeline: MTLRenderPipelineState!
    private var compositePipeline: MTLRenderPipelineState!
    private var depthWrite: MTLDepthStencilState!

    private struct MeshBuffers {
        let sphere: MTLBuffer
        let sphereIndices: MTLBuffer
        let beads: MTLBuffer

        init?(device: MTLDevice, mesh: BrightDNAStrandMeshV5) {
            guard let sphere = device.makeBuffer(bytes: mesh.sphereVertices,
                                                 length: MemoryLayout<Float>.stride * mesh.sphereVertices.count),
                  let sphereIndices = device.makeBuffer(bytes: mesh.sphereIndices,
                                                        length: MemoryLayout<UInt16>.stride * mesh.sphereIndices.count),
                  let beads = device.makeBuffer(bytes: mesh.instances,
                                                length: MemoryLayout<Float>.stride * mesh.instances.count)
            else { return nil }
            self.sphere = sphere
            self.sphereIndices = sphereIndices
            self.beads = beads
        }
    }

    private var buffers: MeshBuffers
    private var builtRungCount: Int

    private var sceneColor: MTLTexture!
    private var sceneDepth: MTLTexture!
    private var b2: MTLTexture!, t2: MTLTexture!    // 1/2
    private var b4: MTLTexture!, t4: MTLTexture!    // 1/4
    private var b8: MTLTexture!, t8: MTLTexture!    // 1/8
    private var b16: MTLTexture!, t16: MTLTexture!  // 1/16
    private var lens: MTLTexture!, lensTemp: MTLTexture!   // 1/4 blurred scene for the ends

    private var mesh: BrightDNAStrandMeshV5
    private let state: GenomeState

    private let autoSpin: Float = -0.16   // anti-clockwise, matching drag
    private let restDistance: Float = 3.0
    private let focusDistance: Float = 2.55
    private let cameraTilt: Float = -.pi / 6
    private let cameraRoll: Float = -.pi / 6
    // Selected-rung height, as a fraction of the view's half-height above centre.
    private let selectedFocusLift: Float = 0.35
    private let focusWidth: Float = BrightDNAStrandBuilderV5.rungSpacing * 2.6
    private let bloomThreshold: Float = 0.5
    private let bloomIntensity: Float = 1.85
    private let bloomSpread = 2
    // Blur over the ends: starts at the centre, full by this distance along the strand.
    private let blurBand = SIMD2<Float>(0, 0.35)
    // Past any point on screen, so no part of the strand is blurred.
    private static let noBlurBand = SIMD2<Float>(100, 101)
    private let blurFrost: Float = 0.005
    private let blurGlowHold: Float = 0.3
    private var smoothPanY: Float = 0
    private var focusY: Float?
    private var lastFrame: CFTimeInterval = CACurrentMediaTime()
    // Entrance: the strand twists up from below the screen into place.
    private var introStart: CFTimeInterval?
    private let introDuration: CFTimeInterval = 2.4
    private let introTwist: Float = 2.6

    init?(view: MTKView, state: GenomeState) {
        guard let device = view.device ?? MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary() else { return nil }
        self.device = device
        self.queue = queue
        self.state = state

        let rungCount = state.markers.isEmpty ? BrightDNAStrandBuilderV5.fallbackRungCount : state.markers.count
        let mesh = BrightDNAStrandBuilderV5.build(rungCount: rungCount)
        guard let buffers = MeshBuffers(device: device, mesh: mesh) else { return nil }
        self.mesh = mesh
        self.buffers = buffers
        self.builtRungCount = rungCount

        super.init()
        state.contentHeight = mesh.labelledHeight
        buildPipelines(view: view, library: library)
    }

    private func rebuildMesh(rungCount: Int) {
        let mesh = BrightDNAStrandBuilderV5.build(rungCount: rungCount)
        guard let buffers = MeshBuffers(device: device, mesh: mesh) else { return }
        self.mesh = mesh
        self.buffers = buffers
        self.builtRungCount = rungCount
        state.contentHeight = mesh.labelledHeight
    }

    private func buildPipelines(view: MTKView, library: MTLLibrary) {
        let hdr: MTLPixelFormat = .rgba16Float

        let scene = MTLRenderPipelineDescriptor()
        scene.vertexFunction = library.makeFunction(name: "brightDNAStrandBeadVertex")
        scene.fragmentFunction = library.makeFunction(name: "brightDNAStrandBeadFragment")
        scene.colorAttachments[0].pixelFormat = hdr
        scene.depthAttachmentPixelFormat = .depth32Float
        scenePipeline = try? device.makeRenderPipelineState(descriptor: scene)

        func fullscreen(_ fragment: String, format: MTLPixelFormat) -> MTLRenderPipelineState? {
            let d = MTLRenderPipelineDescriptor()
            d.vertexFunction = library.makeFunction(name: "brightDNAStrandFullscreenVertex")
            d.fragmentFunction = library.makeFunction(name: fragment)
            d.colorAttachments[0].pixelFormat = format
            return try? device.makeRenderPipelineState(descriptor: d)
        }
        brightPipeline = fullscreen("brightDNAStrandBrightPass", format: hdr)
        blurPipeline = fullscreen("brightDNAStrandBlurPass", format: hdr)
        compositePipeline = fullscreen("brightDNAStrandComposite", format: view.colorPixelFormat)

        let dw = MTLDepthStencilDescriptor()
        dw.depthCompareFunction = .less
        dw.isDepthWriteEnabled = true
        depthWrite = device.makeDepthStencilState(descriptor: dw)
    }

    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        MainActor.assumeIsolated { self.resize(size) }
    }
    nonisolated func draw(in view: MTKView) {
        MainActor.assumeIsolated { self.render(view) }
    }

    private func resize(_ size: CGSize) {
        let w = max(Int(size.width), 1), h = max(Int(size.height), 1)
        func make(_ format: MTLPixelFormat, _ width: Int, _ height: Int) -> MTLTexture? {
            let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: format, width: max(width, 1), height: max(height, 1), mipmapped: false)
            d.usage = [.renderTarget, .shaderRead]
            d.storageMode = .private
            return device.makeTexture(descriptor: d)
        }
        sceneColor = make(.rgba16Float, w, h)
        sceneDepth = make(.depth32Float, w, h)
        b2 = make(.rgba16Float, w / 2, h / 2); t2 = make(.rgba16Float, w / 2, h / 2)
        b4 = make(.rgba16Float, w / 4, h / 4); t4 = make(.rgba16Float, w / 4, h / 4)
        b8 = make(.rgba16Float, w / 8, h / 8); t8 = make(.rgba16Float, w / 8, h / 8)
        b16 = make(.rgba16Float, w / 16, h / 16); t16 = make(.rgba16Float, w / 16, h / 16)
        lens = make(.rgba16Float, w / 4, h / 4); lensTemp = make(.rgba16Float, w / 4, h / 4)
    }

    private func render(_ view: MTKView) {
        guard let drawable = view.currentDrawable,
              let finalPass = view.currentRenderPassDescriptor,
              sceneColor != nil, b16 != nil,
              let cmd = queue.makeCommandBuffer() else { return }

        let wantRungs = state.markers.count
        if wantRungs > 0, wantRungs != builtRungCount { rebuildMesh(rungCount: wantRungs) }

        let now = CACurrentMediaTime()
        let dt = Float(min(now - lastFrame, 1.0 / 30.0))
        lastFrame = now

        if state.isInteracting {
            // Drag in progress: the gesture owns yaw/panY.
        } else if let sel = state.selectedRung, sel < mesh.rungs.count {
            // Focus mode: ease the selected rung flat to the camera, just above the mini sheet.
            state.spinVelocity = 0
            state.panVelocity = 0
            let rung = mesh.rungs[sel]
            let ease = min(1, dt * 4)

            // The rung reads horizontal at two yaws 180° apart — take the nearer.
            var delta = (-atan2(rung.endA.z, rung.endA.x) - state.yaw)
                .truncatingRemainder(dividingBy: .pi)
            if delta > .pi / 2 { delta -= .pi }
            if delta < -.pi / 2 { delta += .pi }
            state.yaw += delta * ease

            let focusOffset = selectedFocusLift * state.distance * tan(Float.pi * 25.0 / 180.0)
            let targetPan = rung.center.y - focusOffset
            state.panY += (targetPan - state.panY) * ease
            state.distance += (focusDistance - state.distance) * ease
        } else {
            state.distance += (restDistance - state.distance) * min(1, dt * 4)
            state.yaw += autoSpin * dt

            if state.spinVelocity != 0 {
                state.yaw += state.spinVelocity * dt
                state.spinVelocity *= pow(Float(0.93), dt * 60)
                if abs(state.spinVelocity) < 0.002 { state.spinVelocity = 0 }
            }

            if state.panVelocity != 0 {
                state.panY += state.panVelocity * dt
                state.panVelocity *= pow(Float(0.93), dt * 60)
                let limit = mesh.labelledHeight / 2 + 1
                if state.panY >= limit { state.panY = limit; state.panVelocity = 0 }
                else if state.panY <= -limit { state.panY = -limit; state.panVelocity = 0 }
                else if abs(state.panVelocity) < 0.01 { state.panVelocity = 0 }
            }
        }

        smoothPanY += (state.panY - smoothPanY) * min(1, dt * 22)

        // Per-rung selection fades that drive the annotation overlay's animation.
        let fadeStep = min(1, dt * 6)
        if let sel = state.selectedRung {
            let current = state.selectionFade[sel] ?? 0
            state.selectionFade[sel] = current + (1 - current) * fadeStep
        }
        for (index, value) in state.selectionFade where index != state.selectedRung {
            let next = value - value * fadeStep
            state.selectionFade[index] = next < 0.01 ? nil : next
        }

        let halfView = state.distance * tan(Float.pi * 25.0 / 180.0)
        let targetFocus = state.selectedRung.flatMap { $0 < mesh.rungs.count ? mesh.rungs[$0].center.y : nil }
            ?? smoothPanY
        let focus = (focusY ?? targetFocus) + (targetFocus - (focusY ?? targetFocus)) * min(1, dt * 5)
        focusY = focus

        let viewport = view.bounds.size
        let aspect = Float(max(viewport.width, 1) / max(viewport.height, 1))
        let proj = GenomeMetalMath.perspective(fovYRadians: 50 * .pi / 180, aspect: aspect, near: 0.1, far: 400)
        if introStart == nil, state.isOnScreen { introStart = now }
        let introProgress = introStart.map { Float(min(1, (now - $0) / introDuration)) } ?? 0
        let introRemaining = pow(1 - introProgress, 3)
        let yaw = state.yaw + introTwist * introRemaining, dist = state.distance
        // Looking from above where the strand will settle puts it below the screen, then it rises in.
        let center = SIMD3<Float>(0, smoothPanY + halfView * 2.4 * introRemaining, 0)
        let eye = center + SIMD3<Float>(dist * sin(yaw) * cos(cameraTilt),
                                        dist * sin(cameraTilt),
                                        dist * cos(yaw) * cos(cameraTilt))
        let forward = simd_normalize(center - eye)
        let right = simd_normalize(simd_cross(forward, SIMD3(0, 1, 0)))
        let up = simd_cross(right, forward) * cos(cameraRoll) + right * sin(cameraRoll)
        let mvp = proj * GenomeMetalMath.lookAt(eye: eye, center: center, up: up)
        let tt = Float(now.truncatingRemainder(dividingBy: 3600))

        var uniforms = BrightDNAStrandUniforms(mvp: mvp, cameraPos: eye, time: tt, height: mesh.height,
                                               focusY: focus, focusWidth: focusWidth)

        let scenePass = MTLRenderPassDescriptor()
        scenePass.colorAttachments[0].texture = sceneColor
        scenePass.colorAttachments[0].loadAction = .clear
        scenePass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
        scenePass.colorAttachments[0].storeAction = .store
        scenePass.depthAttachment.texture = sceneDepth
        scenePass.depthAttachment.loadAction = .clear
        scenePass.depthAttachment.clearDepth = 1.0
        scenePass.depthAttachment.storeAction = .dontCare

        if let enc = cmd.makeRenderCommandEncoder(descriptor: scenePass) {
            enc.setRenderPipelineState(scenePipeline)
            enc.setDepthStencilState(depthWrite)
            enc.setCullMode(.none)
            let reach = halfView * 1.8 + 0.6
            let spacing = BrightDNAStrandBuilderV5.rungSpacing
            let firstRung = Int(((smoothPanY - reach + mesh.height / 2) / spacing).rounded(.down))
            let lastRung = Int(((smoothPanY + reach + mesh.height / 2) / spacing).rounded(.up))
            let starts = mesh.rungInstanceStart
            let firstBead = starts[min(max(firstRung, 0), starts.count - 1)]
            let endBead = starts[min(max(lastRung + 1, 0), starts.count - 1)]
            enc.setVertexBuffer(buffers.sphere, offset: 0, index: 0)
            enc.setVertexBytes(&uniforms, length: MemoryLayout<BrightDNAStrandUniforms>.stride, index: 1)
            enc.setVertexBuffer(buffers.beads, offset: firstBead * 5 * MemoryLayout<Float>.stride, index: 2)
            enc.setFragmentBytes(&uniforms, length: MemoryLayout<BrightDNAStrandUniforms>.stride, index: 0)
            if endBead > firstBead {
                enc.drawIndexedPrimitives(type: .triangle, indexCount: mesh.sphereIndices.count,
                                          indexType: .uint16, indexBuffer: buffers.sphereIndices,
                                          indexBufferOffset: 0, instanceCount: endBead - firstBead)
            }
            enc.endEncoding()
        }

        let isLight = view.traitCollection.userInterfaceStyle == .light
        let glow: Float = isLight ? 0 : bloomIntensity
        if glow > 0 {
            var threshold = bloomThreshold
            runFullscreen(cmd, brightPipeline, output: b2) { enc in
                enc.setFragmentTexture(self.sceneColor, index: 0)
                enc.setFragmentBytes(&threshold, length: MemoryLayout<Float>.stride, index: 0)
            }
            blur(cmd, from: b2, temp: t2, out: b2)
            blur(cmd, from: b2, temp: t4, out: b4)
            blur(cmd, from: b4, temp: t8, out: b8)
            blur(cmd, from: b8, temp: t16, out: b16)
            for _ in 0..<bloomSpread {
                blur(cmd, from: b8, temp: t8, out: b8, step: 3)
                blur(cmd, from: b16, temp: t16, out: b16, step: 4)
            }
        }

        // A heavily blurred copy of the scene, shown over both ends of the strand; light mode reads it as haze, so it's off there.
        if !isLight {
            blur(cmd, from: sceneColor, temp: lensTemp, out: lens)
            for step: Float in [2, 3, 5, 7, 9] {
                blur(cmd, from: lens, temp: lensTemp, out: lens, step: step)
            }
        }

        let (axisLow, _) = GenomeMetalMath.projectFront(center - SIMD3(0, 1, 0), mvp: mvp, viewport: viewport)
        let (axisHigh, _) = GenomeMetalMath.projectFront(center + SIMD3(0, 1, 0), mvp: mvp, viewport: viewport)
        var strandDir = SIMD2(Float((axisHigh.x - axisLow.x) / max(viewport.width, 1)) * aspect,
                              Float((axisHigh.y - axisLow.y) / max(viewport.height, 1)))
        strandDir = simd_length(strandDir) > 1e-4 ? simd_normalize(strandDir) : SIMD2(0, 1)
        var comp = CompositeParams(bloomIntensity: glow, saturation: 1.12, strandDir: strandDir,
                                   aspect: aspect, frost: blurFrost, glowHold: blurGlowHold,
                                   band: isLight ? Self.noBlurBand : blurBand)
        if let enc = cmd.makeRenderCommandEncoder(descriptor: finalPass) {
            enc.setRenderPipelineState(compositePipeline)
            enc.setFragmentTexture(sceneColor, index: 0)
            enc.setFragmentTexture(b2, index: 1)
            enc.setFragmentTexture(b4, index: 2)
            enc.setFragmentTexture(b8, index: 3)
            enc.setFragmentTexture(b16, index: 4)
            enc.setFragmentTexture(lens, index: 5)
            enc.setFragmentBytes(&comp, length: MemoryLayout<CompositeParams>.stride, index: 0)
            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            enc.endEncoding()
        }

        cmd.present(drawable)
        cmd.commit()
        publishProjections(mvp: mvp, viewport: viewport)
    }

    private struct BlurDir { var dir: SIMD2<Float> }
    private struct CompositeParams {
        var bloomIntensity: Float
        var saturation: Float
        var strandDir: SIMD2<Float>
        var aspect: Float
        var frost: Float
        var glowHold: Float
        var _pad: Float = 0
        var band: SIMD2<Float>
    }

    // Separable blur `from` -> `temp` (H) -> `out` (V); a smaller target also downsamples.
    private func blur(_ cmd: MTLCommandBuffer, from src: MTLTexture, temp: MTLTexture, out: MTLTexture,
                      step: Float = 1) {
        var dirH = BlurDir(dir: SIMD2(step / Float(temp.width), 0))
        runFullscreen(cmd, blurPipeline, output: temp) { enc in
            enc.setFragmentTexture(src, index: 0)
            enc.setFragmentBytes(&dirH, length: MemoryLayout<BlurDir>.stride, index: 0)
        }
        var dirV = BlurDir(dir: SIMD2(0, step / Float(out.height)))
        runFullscreen(cmd, blurPipeline, output: out) { enc in
            enc.setFragmentTexture(temp, index: 0)
            enc.setFragmentBytes(&dirV, length: MemoryLayout<BlurDir>.stride, index: 0)
        }
    }

    private func runFullscreen(_ cmd: MTLCommandBuffer, _ pipeline: MTLRenderPipelineState,
                               output: MTLTexture, configure: (MTLRenderCommandEncoder) -> Void) {
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = output
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        pass.colorAttachments[0].storeAction = .store
        guard let enc = cmd.makeRenderCommandEncoder(descriptor: pass) else { return }
        enc.setRenderPipelineState(pipeline)
        configure(enc)
        enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        enc.endEncoding()
    }

    private func publishProjections(mvp: simd_float4x4, viewport: CGSize) {
        var hits: [ProjectedRung] = []
        hits.reserveCapacity(mesh.rungs.count)
        for rung in mesh.rungs {
            let (screen, onScreen) = GenomeMetalMath.project(rung.center, mvp: mvp, viewport: viewport)
            let (screenA, aInFront) = GenomeMetalMath.projectFront(rung.endA, mvp: mvp, viewport: viewport)
            let (screenB, bInFront) = GenomeMetalMath.projectFront(rung.endB, mvp: mvp, viewport: viewport)
            hits.append(ProjectedRung(
                index: rung.index,
                screen: screen,
                screenA: screenA,
                screenB: screenB,
                visible: onScreen || (aInFront && bInFront)
            ))
        }
        state.rungs = hits
    }
}
