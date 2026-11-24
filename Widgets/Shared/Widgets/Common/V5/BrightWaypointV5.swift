//
//  BrightWaypointV5.swift
//  Widgets
//
//  Created by Dom Montalto on 18/11/2026.
//

import SwiftUI

struct BrightWaypointV5: View {
    let goal: String
    let message: String
    let lowLabel: String
    let highLabel: String
    // Where you sit between the two extremes, from -1 (low) to 1 (high).
    let offset: Double
    var color: Color = .defaultCyan

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            header
                .padding(.horizontal, .spacing3x)

            VStack(spacing: .spacing1x) {
                north

                track

                HStack(spacing: .spacing0x) {
                    BrightText(lowLabel, size: .body5, color: .semiLightTextColor)

                    Spacer(minLength: .spacing2x)

                    BrightText(highLabel, size: .body5, color: .semiLightTextColor)
                }
                .padding(.horizontal, .spacing05x)
            }
            .padding(.horizontal, .spacing3x)
            .padding(.top, .spacing4x)

            BrightText(message, size: .body2, color: color.opacity(.mediumOpacity))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, .spacing3x)
                .padding(.top, .spacing5x)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            HStack(spacing: .spacing1x) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.standardSFPro(size: .body1, weight: .regular))
                    .foregroundStyle(Color.defaultGreen)

                BrightText("Your Waypoint", size: .body1, color: .semiLightTextColor)
            }

            BrightText(goal, size: .heading)
        }
        .lineLimit(1)
    }

    private var north: some View {
        HStack(spacing: .spacing05x) {
            Image(systemName: "location.north.fill")
                .font(.standardSFPro(size: .body1, weight: .regular))

            BrightText("N", size: .body1)
        }
        .foregroundStyle(Color.textColor)
    }

    private var track: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let middle = width / 2
            let tickX = Constants.inset + Constants.zoneWidth + Constants.tickGap
            let reach = middle - tickX - Constants.pillWidth / 2 - Constants.tickGap
            let pillX = middle + reach * min(max(offset, -1), 1)

            ZStack(alignment: .topLeading) {
                Capsule()
                    .strokeBorder(Color.textColor.opacity(.minimalOpacity), lineWidth: Constants.hairline)

                zone
                    .position(x: Constants.inset + Constants.zoneWidth / 2, y: Constants.height / 2)

                zone
                    .position(x: width - Constants.inset - Constants.zoneWidth / 2, y: Constants.height / 2)

                tick
                    .position(x: tickX, y: Constants.height / 2)

                tick
                    .position(x: width - tickX, y: Constants.height / 2)

                Capsule()
                    .fill(color)
                    .frame(width: Constants.pillWidth, height: Constants.markHeight)
                    .position(x: pillX, y: Constants.height / 2)
            }
        }
        .frame(height: Constants.height)
        .animation(.brightBouncy, value: offset)
    }

    private var zone: some View {
        Capsule()
            .fill(Color.defaultYellow.opacity(.minimalOpacity))
            .frame(width: Constants.zoneWidth, height: Constants.markHeight)
    }

    private var tick: some View {
        Capsule()
            .fill(Color.textColor)
            .frame(width: Constants.tickWidth, height: Constants.markHeight)
    }

    private enum Constants {
        static let height: CGFloat = 25
        static let markHeight: CGFloat = 17
        static let inset: CGFloat = 4
        static let zoneWidth: CGFloat = 42
        static let tickWidth: CGFloat = 3
        static let tickGap: CGFloat = .spacing1x
        static let pillWidth: CGFloat = 47
        static let hairline: CGFloat = 0.5
    }
}

#Preview {
    BrightWaypointV5(
        goal: "General health",
        message: "Your activity health is generally good",
        lowLabel: "Sedentary",
        highLabel: "Excessive",
        offset: 0.15
    )
    .padding(.vertical, .spacing3x)
    .frame(maxHeight: .infinity)
    .background(Color.defaultBackground)
}
