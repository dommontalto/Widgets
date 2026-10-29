//
//  BrightLiquidGlassLogoV5.swift
//  Widgets
//
//  Created by Dom Montalto on 23/10/2026.
//
//  Adapted from ReactDrops Liquid Glass Logo, see THIRD_PARTY_LICENSES.md.
//

import MetalKit
import SwiftUI

// The Bright mark rises as a glass sphere, squares into a tile and clears to the plain logo on the page.
struct BrightLiquidGlassLogoV5: View {
    var config = BrightLiquidGlassLogoConfigV5()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.self) private var environment
    @State private var metalFailed = false

    // Metal takes plain values, so the page, tile and logo colours are resolved for the current appearance.
    private var themed: BrightLiquidGlassLogoConfigV5 {
        var themed = config
        themed.background = Self.rgb(Color.defaultBackground, in: environment)
        themed.tileColor = Self.rgb(Color.introLogoTile, in: environment)
        return themed
    }

    private var logo: UIImage? {
        let ink = UIColor(cgColor: Color.textColor.resolve(in: environment).cgColor)
        return UIImage(named: ImageNames.brightMarkWhiteV5)?.withTintColor(ink, renderingMode: .alwaysOriginal)
    }

    var body: some View {
        ZStack {
            Color.defaultBackground
            if metalFailed {
                fallback
            } else {
                BrightLiquidGlassLogoMetalViewV5(config: themed, logo: logo, reduceMotion: reduceMotion) {
                    metalFailed = true
                }
                // Rebuilt if the appearance flips, as the colours are baked into the renderer.
                .id(environment.colorScheme)
            }
        }
    }

    private var fallback: some View {
        let side = CGFloat(config.logoSize * config.logoScale * config.finalLogoScale)
        return Image(ImageNames.brightMarkWhiteV5)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.textColor)
            .frame(width: side, height: side)
    }

    private static func rgb(_ color: Color, in environment: EnvironmentValues) -> SIMD3<Float> {
        let c = color.resolve(in: environment)
        return SIMD3(c.red, c.green, c.blue)
    }
}

private struct BrightLiquidGlassLogoMetalViewV5: UIViewRepresentable {
    let config: BrightLiquidGlassLogoConfigV5
    let logo: UIImage?
    let reduceMotion: Bool
    let onFailure: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.framebufferOnly = true
        let page = config.background
        view.clearColor = MTLClearColorMake(Double(page.x), Double(page.y), Double(page.z), 1)
        view.isOpaque = true
        view.backgroundColor = UIColor(red: CGFloat(page.x), green: CGFloat(page.y), blue: CGFloat(page.z), alpha: 1)
        view.contentScaleFactor = min(context.environment.displayScale, config.maxScale)
        view.preferredFramesPerSecond = 60
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.isUserInteractionEnabled = false

        if let logo,
           let renderer = BrightLiquidGlassLogoRendererV5(view: view, logo: logo, config: config,
                                                          reduceMotion: reduceMotion) {
            context.coordinator.renderer = renderer
            view.delegate = renderer
        } else {
            view.isPaused = true
            Task { @MainActor in onFailure() }
        }
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        guard let renderer = context.coordinator.renderer, renderer.reduceMotion != reduceMotion else { return }
        renderer.reduceMotion = reduceMotion
        if reduceMotion { uiView.setNeedsDisplay() }
    }

    @MainActor
    final class Coordinator {
        var renderer: BrightLiquidGlassLogoRendererV5?
    }
}
