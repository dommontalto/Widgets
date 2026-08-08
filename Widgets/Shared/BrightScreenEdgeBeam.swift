//
//  BrightScreenEdgeBeam.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

struct BrightScreenEdgeBeam: View {
    // Set false to fade the beam out — BorderBeam keeps its layers mounted so it
    // settles rather than cutting.
    var isActive = true
    // Match the curve of whatever the beam runs around. A sheet's own radius is
    // far tighter than the display's, and the mismatch clips the ring's corners.
    var cornerRadius: Double = Constants.screenCornerRadius
    // Sheets start below the display's top edge, so the beam has to stay inside
    // the safe area or its top run is cut off by the presentation.
    var edgesToIgnore: Edge.Set = .all
    var colorVariant: BeamColorVariant = .brand
    var size: BeamSize = .md
    // nil resolves to the beam spec's defaults, matching the untuned web demo.
    var duration: Double?
    var brightness: Double?
    var saturation: Double?
    var strength: Double = 1
    // How far the ring's blobs spread: the canvas is drawn this much smaller
    // then scaled back up, so a bigger number means a fatter, softer ring.
    var renderScale: Double = Constants.renderScale
    var tuning: BeamTuning = .none

    static var defaultCornerRadius: Double { Constants.screenCornerRadius }
    static var defaultRenderScale: Double { Constants.renderScale }

    var body: some View {
        GeometryReader { geo in
            // The canvas is derived by dividing through `renderScale`, so a
            // zero on either side of that hands the layers a non-finite frame.
            if geo.size.width > 0, geo.size.height > 0, renderScale > 0 {
                beamLayer(in: geo.size)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
        }
        .ignoresSafeArea(edges: edgesToIgnore)
        .allowsHitTesting(false)
    }

    // The layer draws on a canvas shrunk by `renderScale` and is scaled back
    // up: the palette sizes its blobs in card-scale pixels, so a screen-sized
    // canvas leaves most of the ring unlit. Dividing the radius by the same
    // factor lands the canvas corners on the container's real corners.
    private func beamLayer(in screen: CGSize) -> some View {
        BorderBeam(
            size: size,
            colorVariant: colorVariant,
            theme: .dark,
            duration: duration,
            active: isActive,
            borderRadius: cornerRadius / renderScale,
            brightness: brightness,
            saturation: saturation,
            strength: strength,
            tuning: tuning
        ) {
            Color.clear
        }
        .frame(
            width: screen.width / renderScale,
            height: screen.height / renderScale
        )
        .scaleEffect(renderScale, anchor: .center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private enum Constants {
        // Runs a little wider than the true display curve (~62pt on a 16/17
        // Pro): the ring draws on a canvas shrunk by `renderScale`, so its
        // corners read tighter than the radius says once scaled back up.
        static let screenCornerRadius: Double = 60
        static let renderScale: CGFloat = 3
    }
}

#Preview {
    ZStack {
        Color.defaultBackground.ignoresSafeArea()
        BrightScreenEdgeBeam()
    }
}
