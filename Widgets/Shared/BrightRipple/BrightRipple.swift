//
//  BrightRipple.swift
//  Widgets
//
//  Created by Dom Montalto on 25/9/2026.
//

import SwiftUI

struct BrightRipple<Content: View>: View {
    var speed: Double = 1
    var size: Double = 1
    var caustic: Double = 0.1
    var waves: Double = 0.08
    var layering: Double = 0.15
    var edges: Double = 0.3
    var highlights: Double = 0.35
    var colorBack: Color = .black
    var colorHighlight: Color = .white
    @ViewBuilder var content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let elapsed = context.date.timeIntervalSince(start)

            content.layerEffect(
                ShaderLibrary.brightRipple(
                    .boundingRect,
                    .float(elapsed),
                    .float(speed),
                    .float(size),
                    .float(caustic),
                    .float(waves),
                    .float(layering),
                    .float(edges),
                    .float(highlights),
                    .color(colorBack),
                    .color(colorHighlight)
                ),
                maxSampleOffset: CGSize(width: BrightRippleConstants.maxSampleOffset, height: BrightRippleConstants.maxSampleOffset)
            )
        }
    }
}

private enum BrightRippleConstants {
    static let maxSampleOffset: CGFloat = 200
}

#Preview {
    BrightRipple(size: 2.26, caustic: 0.18, waves: 0.21, edges: 0.36) {
        Image(ImageNames.exploreNutritionBackgroundV5)
            .resizable()
            .scaledToFill()
    }
    .ignoresSafeArea()
}
