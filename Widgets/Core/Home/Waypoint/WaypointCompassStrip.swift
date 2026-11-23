//
//  WaypointCompassStrip.swift
//  Widgets
//
//  Created by Dom Montalto on 24/11/2026.
//

import SwiftUI

// The bar over the map: a track running from too little to too much, with a pill
// showing where the chosen load leaves the user between the two. The north marker
// above it slides and turns as the map is turned, and sits dead centre when north
// is up.
struct WaypointCompassStrip: View, Animatable {
    var heading: Double
    // -1 at the low end of the track, 1 at the high end.
    var load: Double
    var loadColor: Color = .defaultCyan
    var zoneColor: Color = .defaultYellow
    var lowTitle = "Sedentary"
    var highTitle = "Excessive"

    // How far the map turns between each haptic tick.
    static let degreesPerTick: Double = 9

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(heading, load) }
        set {
            heading = newValue.first
            load = newValue.second
        }
    }

    var body: some View {
        VStack(spacing: .spacing1x) {
            northMarker

            track

            HStack(spacing: .spacing2x) {
                BrightText(lowTitle, size: .body4, color: .semiLightTextColor)

                Spacer(minLength: .spacing0x)

                BrightText(highTitle, size: .body4, color: .semiLightTextColor)
            }
            .padding(.horizontal, Constants.inset)
        }
        .padding(.horizontal, .spacing3x)
    }

    private var northMarker: some View {
        HStack(spacing: .spacing05x) {
            Image(systemName: "location.north.fill")
                .font(.standardSFPro(size: .subheading2, weight: .regular))
                .foregroundStyle(Color.textColor)
                .rotationEffect(.degrees(-turn))

            BrightText("N", size: .subheading2)
        }
        .offset(x: -CGFloat(turn * Constants.pointsPerDegree))
        .opacity(min((Constants.halfTurn - abs(turn)) / Constants.fadeDegrees, 1))
    }

    private var track: some View {
        Capsule()
            .strokeBorder(Color.textColor.opacity(Constants.outlineOpacity), lineWidth: Constants.outlineWidth)
            .frame(height: Constants.trackHeight)
            .overlay {
                GeometryReader { proxy in
                    let travel = (proxy.size.width - Constants.pillWidth) / 2 - Constants.inset

                    ZStack {
                        HStack(spacing: Constants.inset) {
                            zone
                            tick

                            Spacer(minLength: .spacing0x)

                            tick
                            zone
                        }

                        Capsule()
                            .fill(loadColor)
                            .frame(width: Constants.pillWidth)
                            .offset(x: travel * CGFloat(min(max(load, -1), 1)))
                    }
                    .padding(Constants.inset)
                }
            }
    }

    private var zone: some View {
        Capsule()
            .fill(zoneColor.opacity(Constants.zoneOpacity))
            .frame(width: Constants.zoneWidth)
    }

    private var tick: some View {
        Capsule()
            .fill(Color.textColor)
            .frame(width: Constants.tickWidth)
    }

    // The heading taken the short way round, so north never travels more than half
    // the track in either direction.
    private var turn: Double {
        heading.remainder(dividingBy: 360)
    }

    private enum Constants {
        static let trackHeight: CGFloat = 25
        static let inset: CGFloat = 4
        static let outlineWidth: CGFloat = 0.5
        static let outlineOpacity: Double = .minimalOpacity
        static let pillWidth: CGFloat = 47
        static let zoneWidth: CGFloat = 42
        static let zoneOpacity: Double = .minimalOpacity
        static let tickWidth: CGFloat = 3
        static let pointsPerDegree: Double = 0.9
        static let halfTurn: Double = 180
        // North fades out over the last of the turn, where it would otherwise jump
        // from one end of the track to the other.
        static let fadeDegrees: Double = 30
    }
}

#Preview {
    WaypointCompassStrip(heading: 0, load: 0.14)
        .background(Color.defaultBackground)
}
