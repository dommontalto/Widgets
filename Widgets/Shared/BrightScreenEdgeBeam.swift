//
//  BrightScreenEdgeBeam.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

struct BrightScreenEdgeBeam: View {
    /// Set false to fade the beam out — BorderBeam keeps its layers mounted so it
    /// settles rather than cutting.
    var isActive = true
    /// Match the curve of whatever the beam runs around. A sheet's own radius is
    /// far tighter than the display's, and the mismatch clips the ring's corners.
    var cornerRadius: Double = Constants.screenCornerRadius
    /// Sheets start below the display's top edge, so the beam has to stay inside
    /// the safe area or its top run is cut off by the presentation.
    var edgesToIgnore: Edge.Set = .all

    var body: some View {
        GeometryReader { geo in
            beamLayer(in: geo.size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .ignoresSafeArea(edges: edgesToIgnore)
        .allowsHitTesting(false)
    }

    /// The layer draws on a canvas shrunk by `renderScale` and is scaled back
    /// up: the palette sizes its blobs in card-scale pixels, so a screen-sized
    /// canvas leaves most of the ring unlit. Dividing the radius by the same
    /// factor lands the canvas corners on the container's real corners.
    private func beamLayer(in screen: CGSize) -> some View {
        BorderBeam(
            size: .md,
            colorVariant: .brand,
            theme: .dark,
            duration: Constants.duration,
            active: isActive,
            borderRadius: cornerRadius / Constants.renderScale,
            brightness: Constants.brightness,
            saturation: Constants.saturation,
            hueRange: Constants.hueRange
        ) {
            Color.clear
        }
        .frame(
            width: screen.width / Constants.renderScale,
            height: screen.height / Constants.renderScale
        )
        .scaleEffect(Constants.renderScale, anchor: .center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private enum Constants {
        /// The iPhone 16/17 Pro display curve — a smaller radius visibly cuts
        /// the hairline stroke at the corners.
        static let screenCornerRadius: Double = 62
        static let renderScale: CGFloat = 2.6
        static let duration: Double = 4
        static let brightness: Double = 1.7
        static let saturation: Double = 1.5
        /// The rotate family ping-pongs the whole ring's hue by ±this much. Wide
        /// ranges drift the blobs off the brand palette entirely, so keep it to
        /// a shimmer.
        static let hueRange: Double = 15
    }
}

#Preview {
    ZStack {
        Color.defaultBackground.ignoresSafeArea()
        BrightScreenEdgeBeam()
    }
}
