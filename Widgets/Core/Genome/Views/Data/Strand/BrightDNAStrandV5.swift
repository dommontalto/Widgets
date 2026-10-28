//
//  BrightDNAStrandV5.swift
//  Widgets
//
//  Created by Dom Montalto on 21/10/2026.
//

import MetalKit
import SwiftUI
import UIKit

// Beaded aqua-gem DNA strand, tilted and leaning back. Drag to rotate, drag
// vertically to scroll, tap a rung to select it.
struct BrightDNAStrandV5: UIViewRepresentable {
    let state: GenomeState

    func makeCoordinator() -> Coordinator { Coordinator(state: state) }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.depthStencilPixelFormat = .invalid
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.preferredFramesPerSecond = 60
        view.isPaused = false
        view.enableSetNeedsDisplay = false

        if let renderer = BrightDNAStrandRendererV5(view: view, state: state) {
            context.coordinator.renderer = renderer
            view.delegate = renderer
            renderer.mtkView(view, drawableSizeWillChange: view.drawableSize)
        }

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject {
        var renderer: BrightDNAStrandRendererV5?
        private let state: GenomeState
        private var startYaw: Float = 0
        private var startPanY: Float = 0

        private static let deselectDistance: CGFloat = 80

        init(state: GenomeState) { self.state = state }

        @objc func handlePan(_ gr: UIPanGestureRecognizer) {
            let t = gr.translation(in: gr.view)
            switch gr.state {
            case .began:
                state.isInteracting = true
                state.panVelocity = 0
                state.spinVelocity = 0
                startYaw = state.yaw
                startPanY = state.panY
            case .changed:
                state.isInteracting = true
                if state.selectedRung != nil, abs(t.y) > Self.deselectDistance {
                    BrightHaptic.light.play()
                    state.selectedRung = nil
                }
                applyPan(t, in: gr.view)
            case .ended, .cancelled, .failed:
                applyPan(t, in: gr.view)
                // Carry the fling velocity into scroll + twist momentum.
                let vh = Float(gr.view?.bounds.height ?? 800)
                let worldPerPoint = (2.0 * state.distance * tan(Float.pi * 25.0 / 180.0)) / vh
                let v = gr.velocity(in: gr.view)
                state.panVelocity = Float(v.y) * worldPerPoint
                state.spinVelocity = -Float(v.x) * 0.01     // matches the -t.x * 0.01 drag mapping
                state.isInteracting = false          // resume spinning immediately
            default:
                break
            }
        }

        private func applyPan(_ t: CGPoint, in view: UIView?) {
            state.yaw = startYaw - Float(t.x) * 0.01
            let vh = Float(view?.bounds.height ?? 800)
            let worldPerPoint = (2.0 * state.distance * tan(Float.pi * 25.0 / 180.0)) / vh
            let limit = state.contentHeight / 2 + 1
            state.panY = min(max(startPanY + Float(t.y) * worldPerPoint, -limit), limit)
        }

        @objc func handleTap(_ gr: UITapGestureRecognizer) {
            // Without markers the rungs are decorative.
            guard !state.markers.isEmpty else { return }
            let p = gr.location(in: gr.view)
            var best: (index: Int, d: CGFloat)?
            for rung in state.rungs where rung.visible {
                let d = Self.distanceToAnnotation(p, rung)
                if d < 30, best == nil || d < best!.d {
                    best = (rung.index, d)
                }
            }
            if best != nil { BrightHaptic.light.play() }
            state.selectedRung = best?.index      // nil if tapped empty space
        }

        // Distance from the tap to the rung's whole annotation: the rail-to-rail
        // line extended past each end so the letters are tappable too.
        private static func distanceToAnnotation(_ p: CGPoint, _ rung: ProjectedRung) -> CGFloat {
            let a = rung.screenA
            let b = rung.screenB
            let dx = b.x - a.x
            let dy = b.y - a.y
            let length = hypot(dx, dy)
            guard length > 1 else { return hypot(p.x - rung.screen.x, p.y - rung.screen.y) }

            let ext: CGFloat = 35   // letter offset + glyph, past each rail point
            let ux = dx / length
            let uy = dy / length
            let start = CGPoint(x: a.x - ux * ext, y: a.y - uy * ext)
            let end = CGPoint(x: b.x + ux * ext, y: b.y + uy * ext)

            let vx = end.x - start.x
            let vy = end.y - start.y
            let t = max(0, min(1, ((p.x - start.x) * vx + (p.y - start.y) * vy) / (vx * vx + vy * vy)))
            let nearest = CGPoint(x: start.x + vx * t, y: start.y + vy * t)
            return hypot(p.x - nearest.x, p.y - nearest.y)
        }
    }
}
