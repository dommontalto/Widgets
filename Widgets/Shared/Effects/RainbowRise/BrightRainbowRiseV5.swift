//
//  BrightRainbowRiseV5.swift
//  Widgets
//
//  Created by Dom Montalto on 20/10/2026.
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

struct BrightRainbowRiseV5: View {
    @State private var hasPlayed = false

    var body: some View {
        blobs
            .phaseAnimator(GlowPhase.allCases, trigger: hasPlayed) { content, phase in
                content
                    .scaleEffect(phase.scale, anchor: .bottom)
                    .opacity(phase.opacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .visualEffect { content, proxy in
                        content.offset(y: proxy.size.height * phase.rise)
                    }
            } animation: { phase in
                phase.animation
            }
            .allowsHitTesting(false)
            .onAppear { hasPlayed = true }
    }

    private var blobs: some View {
        HStack(spacing: -Constants.blobOverlap) {
            ForEach(Constants.colours.indices, id: \.self) { index in
                Ellipse()
                    .fill(Constants.colours[index])
                    .frame(width: Constants.blobSize.width, height: Constants.blobSize.height)
                    .offset(y: index.isMultiple(of: 2) ? .spacing0x : Constants.blobStagger)
            }
        }
        .blur(radius: Constants.blur)
    }

    private enum GlowPhase: CaseIterable {
        case hidden
        case swell
        case shoot

        var rise: CGFloat {
            switch self {
            case .hidden: 0.4
            case .swell: 0.1
            case .shoot: -1
            }
        }

        var scale: CGFloat {
            switch self {
            case .hidden: 0.6
            case .swell: 1
            case .shoot: 1.5
            }
        }

        var opacity: Double {
            switch self {
            case .hidden, .shoot: 0
            case .swell: 1
            }
        }

        var animation: Animation? {
            switch self {
            case .hidden: nil
            case .swell: .smooth(duration: 0.6).delay(0.1)
            case .shoot: .easeIn(duration: 0.3)
            }
        }
    }

    private enum Constants {
        static let colours: [Color] = [.defaultBrightViolet, .defaultBrightPink, .defaultSand]
        static let blobSize = CGSize(width: 320, height: 340)
        static let blobOverlap: CGFloat = .spacing12x + .spacing6x
        static let blobStagger: CGFloat = .spacing8x
        static let blur: CGFloat = 90
    }
}
