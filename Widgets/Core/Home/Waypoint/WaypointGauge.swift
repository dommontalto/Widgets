//
//  WaypointGauge.swift
//  Widgets
//
//  Created by Dom Montalto on 23/9/2026.
//

import SwiftUI

struct WaypointBounce: Equatable {
    var tick = 0
    var direction: Double = 1
}

struct WaypointGauge: View {
    let bearing: WaypointBearing
    let bounce: WaypointBounce

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: Constants.arcFraction)
                .stroke(bearing.color.opacity(.minimalOpacity), style: stroke)
                .rotationEffect(.degrees(Constants.arcRotation))

            Circle()
                .trim(from: min(Constants.northFraction, bearingFraction), to: max(Constants.northFraction, bearingFraction))
                .stroke(bearing.color.opacity(.lowOpacity), style: stroke)
                .rotationEffect(.degrees(Constants.arcRotation))

            Image(systemName: "arrow.up")
                .font(.standardSFPro(size: .giant, weight: .semibold))
                .foregroundStyle(bearing.color)
                .rotationEffect(.degrees(bearing.degrees))
                .keyframeAnimator(initialValue: 0.0, trigger: bounce.tick) { view, angle in
                    view.rotationEffect(.degrees(angle * bounce.direction))
                } keyframes: { _ in
                    KeyframeTrack {
                        CubicKeyframe(Constants.bounceAngle, duration: Constants.bounceStep)
                        SpringKeyframe(0, duration: Constants.bounceSettle, spring: .bouncy)
                    }
                }

            dot
                .offset(point(radius: Constants.radius))

            BrightText(bearing.label, size: .standout3, color: bearing.color)
                .offset(point(radius: Constants.radius + Constants.labelGap))

            if let badge = bearing.badge {
                Image(systemName: badge)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(bearing.color, bearing.color.opacity(.veryLowOpacity))
                    .font(.standardSFPro(size: .standout3, weight: .regular))
                    .offset(y: Constants.badgeOffset)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: Constants.diameter, height: Constants.diameter)
        .frame(width: Constants.frameSize, height: Constants.diameter + Constants.lineWidth)
    }

    @ViewBuilder private var dot: some View {
        if bearing == .north {
            Circle()
                .strokeBorder(bearing.color, lineWidth: Constants.ringWidth)
                .background(Circle().fill(Color.defaultBackground))
                .frame(width: Constants.dotSize, height: Constants.dotSize)
        } else {
            Circle()
                .fill(bearing.color)
                .frame(width: Constants.dotSize, height: Constants.dotSize)
        }
    }

    private var stroke: StrokeStyle {
        StrokeStyle(lineWidth: Constants.lineWidth, lineCap: .round)
    }

    private var bearingFraction: CGFloat {
        (bearing.degrees + Constants.arcHalfSpan) / 360
    }

    private func point(radius: CGFloat) -> CGSize {
        let radians = bearing.degrees * .pi / 180
        return CGSize(width: radius * sin(radians), height: -radius * cos(radians))
    }

    private enum Constants {
        static let diameter: CGFloat = 145
        static let radius: CGFloat = diameter / 2
        static let frameSize: CGFloat = 225
        static let lineWidth: CGFloat = 16
        static let dotSize: CGFloat = 14
        static let ringWidth: CGFloat = 3
        static let labelGap: CGFloat = 30
        static let badgeOffset: CGFloat = 66
        static let arcHalfSpan: Double = 135
        static let arcFraction: CGFloat = 0.75
        static let northFraction: CGFloat = 0.375
        static let arcRotation: Double = 135
        static let bounceAngle: Double = 14
        static let bounceStep: Double = 0.1
        static let bounceSettle: Double = 0.5
    }
}

enum WaypointBearing: CaseIterable {
    case southWest
    case northWest
    case north
    case northEast
    case southEast

    var degrees: Double {
        switch self {
        case .southWest: -135
        case .northWest: -45
        case .north: 0
        case .northEast: 45
        case .southEast: 135
        }
    }

    var label: String {
        switch self {
        case .southWest: "SW"
        case .northWest: "NW"
        case .north: "N"
        case .northEast: "NE"
        case .southEast: "SE"
        }
    }

    var subtitle: String {
        switch self {
        case .southWest: "Progress is too slow. Goal will be moved back."
        case .northWest: "Progress is slower than usual"
        case .north: "You are on target with your goals"
        case .northEast: "Progress is faster than usual"
        case .southEast: "Progress is too fast. Proceed with caution."
        }
    }

    var color: Color {
        switch self {
        case .southWest, .southEast: .defaultYellow
        case .northWest, .northEast: .defaultCyan
        case .north: .defaultGreen
        }
    }

    var badge: String? {
        switch self {
        case .southWest, .southEast: "exclamationmark.triangle.fill"
        case .north: "checkmark.circle.fill"
        case .northWest, .northEast: nil
        }
    }
}
