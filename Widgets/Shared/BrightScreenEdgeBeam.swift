//
//  BrightScreenEdgeBeam.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

struct BrightScreenEdgeBeam: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                beamLayer(in: geo.size, mirrored: false)
                beamLayer(in: geo.size, mirrored: true)
            }
            .clipShape(RoundedRectangle(cornerRadius: Constants.screenCornerRadius))
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    /// Each layer draws on a canvas shrunk by `renderScale` and is scaled back
    /// up: the palette sizes its blobs in card-scale pixels, so a screen-sized
    /// canvas leaves most of the ring unlit. Dividing the radius by the same
    /// factor lands the canvas corners on the display's real corners.
    private func beamLayer(in screen: CGSize, mirrored: Bool) -> some View {
        BorderBeam(
            size: .md,
            colorVariant: .colorful,
            theme: .dark,
            duration: mirrored ? Constants.mirroredDuration : Constants.duration,
            borderRadius: Constants.screenCornerRadius / Constants.renderScale,
            brightness: Constants.brightness,
            saturation: Constants.saturation,
            hueRange: Constants.hueRange
        ) {
            Color.clear
        }
        .mask(bottomFade)
        .frame(
            width: screen.width / Constants.renderScale,
            height: screen.height * Constants.boxHeight / Constants.renderScale
        )
        .scaleEffect(
            x: mirrored ? -Constants.renderScale : Constants.renderScale,
            y: Constants.renderScale,
            anchor: .bottom
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private var bottomFade: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .clear, location: 0.45),
                .init(color: .white, location: 0.62),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private enum Constants {
        /// The iPhone 16/17 Pro display curve — a smaller radius visibly cuts
        /// the hairline stroke at the corners.
        static let screenCornerRadius: Double = 62
        static let renderScale: CGFloat = 2.6
        static let boxHeight: CGFloat = 1.3
        static let duration: Double = 2.8
        static let mirroredDuration: Double = 3.6
        static let brightness: Double = 1.5
        static let saturation: Double = 1.35
        static let hueRange: Double = 120
    }
}

#Preview {
    ZStack {
        Color.bG.ignoresSafeArea()
        BrightScreenEdgeBeam()
    }
}
