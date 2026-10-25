//
//  ExploreComingSoonView.swift
//  Widgets
//

import SwiftUI

struct ExploreComingSoonView: View {
    @Environment(\.self) private var environment

    // The grains are drawn in Metal, so they take the text colour as a hex.
    private var grainHex: String {
        let c = Color.textColor.resolve(in: environment)
        return String(format: "#%02X%02X%02X", Int(c.red * 255), Int(c.green * 255), Int(c.blue * 255))
    }

    var body: some View {
        VStack(spacing: .spacing0x) {
            Spacer()

            VStack(spacing: .spacing2x) {
                // The sand draws on a canvas wider than its slot, scaled down to match, so
                // grains a finger blows outward aren't cut off at the slot's edge.
                Color.clear
                    .frame(width: Constants.sandSize, height: Constants.sandSize)
                    .overlay {
                        BrightSandV5(
                            logo: BrightSandImagesV5.symbolPrefix + "map.fill",
                            // A finger blows the grains apart like a breath through sand; they drift back after.
                            touchStrength: 0.12 / Constants.canvasScale,
                            touchRadius: 0.45 / Constants.canvasScale,
                            touchLife: 3.2,
                            touchNoise: 3,
                            touchOnIcon: 1,
                            iconScale: 1.03 / Constants.canvasScale,
                            particleCount: Constants.sandGrains,
                            radius: 0.69 / Constants.canvasScale,
                            backColor: grainHex,
                            glowColor: grainHex,
                            frontColor: grainHex,
                            transparent: true
                        )
                        .frame(width: Constants.sandSize * CGFloat(Constants.canvasScale),
                               height: Constants.sandSize * CGFloat(Constants.canvasScale))
                    }
                    .accessibilityHidden(true)

                BrightText("Explore", size: .huge205, weight: .medium)
                    // The map sits inside its slot with room to spare, so the title tucks up into it.
                    .padding(.top, -.spacing2x)

                BrightText("Agents, clinics and offers picked for your health are on their way", size: .body1, color: .lightTextColor)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            HStack(spacing: .spacing1x) {
                Image(systemName: "clock")
                    .font(.system(size: FontSizes.body1.rawValue, weight: .medium))
                BrightText("Coming Soon", size: .body1, color: .defaultCyan, weight: .medium)
            }
            .foregroundStyle(Color.defaultCyan)
            .padding(.bottom, Constants.dockClearance)
        }
        .padding(.horizontal, .spacing6x)
        // The page is a scroll view, so fill its visible height for Coming Soon to reach the bottom.
        .containerRelativeFrame([.horizontal, .vertical])
    }

    private enum Constants {
        static let sandSize: CGFloat = .spacing10x * 3
        static let sandGrains: Float = 40000
        static let canvasScale: Float = 1.8
        static let dockClearance: CGFloat = .spacing1x
    }
}

#Preview {
    ExploreComingSoonView()
        .background(Color.defaultBackground)
}
