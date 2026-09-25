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

    @State private var swing: Double = 1
    @State private var wiggleRun = 0
    @State private var arrowWiggle: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: Constants.arcFraction)
                .stroke(bearing.color.opacity(.minimalOpacity), style: stroke)
                .rotationEffect(.degrees(Constants.arcRotation))

            WaypointCometArc(fraction: bearingFraction, northFraction: Constants.northFraction, rotation: Constants.arcRotation, color: bearing.color, style: stroke)
                .blur(radius: Constants.cometGlowBlur)
                .opacity(.lowOpacity)
                .animation(WaypointPop.travel, value: bearing)

            WaypointCometArc(fraction: bearingFraction, northFraction: Constants.northFraction, rotation: Constants.arcRotation, color: bearing.color, style: stroke)
                .animation(WaypointPop.travel, value: bearing)

            Image(systemName: "arrow.up")
                .font(.standardSFPro(size: .giant, weight: .semibold))
                .foregroundStyle(bearing.color)
                .animation(Constants.colorFade, value: bearing)
                .scaleEffect(Constants.arrowScale)
                .rotationEffect(.degrees(bearing.degrees))
                .rotationEffect(.degrees(arrowWiggle))
                .keyframeAnimator(initialValue: 0.0, trigger: bounce.tick) { view, angle in
                    view.rotationEffect(.degrees(angle * bounce.direction))
                } keyframes: { _ in
                    KeyframeTrack {
                        CubicKeyframe(Constants.bounceAngle, duration: Constants.bounceStep)
                        SpringKeyframe(0, duration: Constants.bounceSettle, spring: .bouncy)
                    }
                }
                .animation(WaypointPop.travel, value: bearing)

            dot
                .modifier(WaypointPop(trigger: bearing))
                .offset(y: -Constants.radius)
                .modifier(WaypointWiggle(trigger: bearing, direction: swing))
                .rotationEffect(.degrees(bearing.degrees))
                .animation(WaypointPop.travel, value: bearing)

            BrightText(bearing.label, size: .standout3, color: bearing.color)
                .brightTextReveal()
                .offset(point(radius: Constants.radius + Constants.labelGap))
                .id(bearing)
                .transition(.asymmetric(insertion: .identity, removal: .opacity))

            ZStack {
                if let badge = bearing.badge {
                    Image(systemName: badge)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(bearing.color, bearing.color.opacity(.veryLowOpacity))
                        .font(.standardSFPro(size: .standout3, weight: .regular))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.brightBouncy, value: bearing.badge)
            .offset(y: Constants.badgeOffset)
        }
        .frame(width: Constants.diameter, height: Constants.diameter)
        .background {
            Circle()
                .fill(bearing.color)
                .frame(width: Constants.headingGlowSize, height: Constants.headingGlowSize)
                .blur(radius: Constants.headingGlowBlur)
                .opacity(.veryLowOpacity)
                .offset(y: -Constants.headingGlowReach)
                .rotationEffect(.degrees(bearing.degrees))
                .allowsHitTesting(false)
        }
        .frame(width: Constants.frameSize, height: Constants.diameter + Constants.lineWidth)
        .onChange(of: bearing) { old, new in
            swing = new.degrees > old.degrees ? 1 : -1
            wiggleRun += 1
        }
        .task(id: wiggleRun) {
            guard wiggleRun > 0 else { return }
            for angle in WaypointWiggle.angles {
                withAnimation(.easeInOut(duration: WaypointWiggle.swing)) {
                    arrowWiggle = angle * swing
                }
                do {
                    try await Task.sleep(for: .seconds(WaypointWiggle.swing))
                } catch {
                    arrowWiggle = 0
                    return
                }
            }
        }
    }

    private var dot: some View {
        Circle()
            .fill(Color.defaultBackground)
            .overlay(Circle().strokeBorder(bearing.color, lineWidth: Constants.ringWidth))
            .frame(width: Constants.dotSize, height: Constants.dotSize)
            .background {
                Circle()
                    .fill(bearing.color)
                    .frame(width: Constants.dotGlowSize, height: Constants.dotGlowSize)
                    .blur(radius: Constants.dotGlowBlur)
                    .opacity(.lowOpacity)
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
        static let dotGlowSize: CGFloat = 26
        static let colorFade: Animation = .easeInOut(duration: 0.6)
        static let arrowScale: CGFloat = 1.15
        static let headingGlowSize: CGFloat = 130
        static let headingGlowBlur: CGFloat = 40
        static let headingGlowReach: CGFloat = 70
        static let cometGlowBlur: CGFloat = 8
        static let dotGlowBlur: CGFloat = 6
    }
}

private struct WaypointPop: ViewModifier {
    static let travel: Animation = .snappy(duration: 0.3)

    let trigger: WaypointBearing

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: 1.0, trigger: trigger) { view, scale in
                view.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(Constants.scale, duration: Constants.rise)
                    SpringKeyframe(1, duration: Constants.settle, spring: .bouncy)
                }
            }
    }

    private enum Constants {
        static let scale: CGFloat = 1.3
        static let rise: Double = 0.15
        static let settle: Double = 0.5
    }
}

private struct WaypointWiggle: ViewModifier {
    static let arrival: Double = 0
    static let swing: Double = 0.065
    static let angles: [Double] = [7, -5, 3, -1.5, 0]

    let trigger: WaypointBearing
    let direction: Double

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: 0.0, trigger: trigger) { view, angle in
                view.rotationEffect(.degrees(angle * direction))
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(0, duration: Self.arrival)
                    CubicKeyframe(Self.angles[0], duration: Self.swing)
                    CubicKeyframe(Self.angles[1], duration: Self.swing)
                    CubicKeyframe(Self.angles[2], duration: Self.swing)
                    CubicKeyframe(Self.angles[3], duration: Self.swing)
                    CubicKeyframe(Self.angles[4], duration: Self.swing)
                }
            }
    }
}

private struct WaypointCometArc: View, Animatable {
    var fraction: CGFloat
    let northFraction: CGFloat
    let rotation: Double
    let color: Color
    let style: StrokeStyle

    var animatableData: CGFloat {
        get { fraction }
        set { fraction = newValue }
    }

    var body: some View {
        let low = min(northFraction, fraction)
        let high = max(northFraction, fraction)
        let tail = color.opacity(.ultraLowOpacity)
        let colors = fraction < northFraction ? [color, tail] : [tail, color]

        Circle()
            .trim(from: low, to: high)
            .stroke(
                AngularGradient(colors: colors, center: .center, startAngle: .degrees(low * 360), endAngle: .degrees(high * 360)),
                style: style
            )
            .rotationEffect(.degrees(rotation))
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
        case .northWest: -55
        case .north: 0
        case .northEast: 55
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
        case .southWest, .southEast: .defaultRed
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
