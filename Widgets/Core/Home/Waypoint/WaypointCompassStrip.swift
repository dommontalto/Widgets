//
//  WaypointCompassStrip.swift
//  Widgets
//
//  Created by Dom Montalto on 24/11/2026.
//

import SwiftUI

// A compass tape that slides as the map turns. The lit stretch runs from where the
// last block drifted to back to north, and the hatching marks the bearings where
// strain ran high.
struct WaypointCompassStrip: View, Animatable {
    var heading: Double
    var drift: Double = -18
    var strain: ClosedRange<Double> = -81 ... -54

    static let degreesPerTick: Double = 9
    static let pointsPerDegree: Double = Constants.tickSpacing / degreesPerTick

    var animatableData: Double {
        get { heading }
        set { heading = newValue }
    }

    var body: some View {
        VStack(spacing: .spacing0x) {
            Canvas { context, size in
                drawBand(&context, size: size)
            }
            .frame(height: Constants.bandHeight)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: Constants.edgeFade),
                        .init(color: .black, location: 1 - Constants.edgeFade),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }

            Canvas { context, size in
                drawTicks(&context, size: size)
            }
            .frame(height: Constants.tickRowHeight)
        }
    }

    // How far along the tape a bearing sits from the centre, taking the short way round.
    private func offset(_ bearing: Double) -> Double {
        (bearing - heading).remainder(dividingBy: 360) * Self.pointsPerDegree
    }

    private func drawBand(_ context: inout GraphicsContext, size: CGSize) {
        let centre = Double(size.width) / 2
        let height = Double(size.height)

        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .color(Color.defaultCyan.opacity(Constants.bandOpacity))
        )

        let strainStart = centre + offset(strain.lowerBound)
        let strainEnd = strainStart + (strain.upperBound - strain.lowerBound) * Self.pointsPerDegree
        var hatching = Path()
        var x = strainStart - Constants.hatchLean
        while x < strainEnd {
            hatching.move(to: CGPoint(x: x, y: height))
            hatching.addLine(to: CGPoint(x: x + Constants.hatchLean, y: 0))
            x += Constants.hatchSpacing
        }
        context.drawLayer { layer in
            layer.clip(to: Path(CGRect(x: strainStart, y: 0, width: strainEnd - strainStart, height: height)))
            layer.stroke(
                hatching,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Color.defaultYellow.opacity(.zero), location: 0),
                        .init(color: Color.defaultYellow.opacity(Constants.hatchOpacity), location: Constants.hatchFade),
                        .init(color: Color.defaultYellow.opacity(Constants.hatchOpacity), location: 1 - Constants.hatchFade),
                        .init(color: Color.defaultYellow.opacity(.zero), location: 1),
                    ]),
                    startPoint: CGPoint(x: strainStart, y: 0),
                    endPoint: CGPoint(x: strainEnd, y: 0)
                ),
                lineWidth: Constants.hatchWidth
            )
        }

        let driftX = centre + offset(drift)
        let northX = driftX - drift * Self.pointsPerDegree
        context.fill(
            Path(CGRect(x: min(driftX, northX), y: 0, width: abs(northX - driftX), height: height)),
            with: .linearGradient(
                Gradient(colors: [.defaultCyan, Color.defaultCyan.opacity(.zero)]),
                startPoint: CGPoint(x: driftX, y: 0),
                endPoint: CGPoint(x: northX, y: 0)
            )
        )
    }

    private func drawTicks(_ context: inout GraphicsContext, size: CGSize) {
        let centre = Double(size.width) / 2
        let middle = Double(size.height) / 2
        let tickCount = Int(360 / Self.degreesPerTick)
        let ticksPerQuarter = tickCount / Constants.cardinals.count
        let driftTick = ((Int((drift / Self.degreesPerTick).rounded()) % tickCount) + tickCount) % tickCount

        for tick in 0 ..< tickCount {
            let x = centre + offset(Double(tick) * Self.degreesPerTick)
            guard abs(x - centre) < centre + Constants.tickSpacing else { continue }

            if tick % ticksPerQuarter == 0 {
                let isNorth = tick == 0
                context.draw(
                    Text(Constants.cardinals[tick / ticksPerQuarter])
                        .font(.standard(size: .subheading2, weight: .regular))
                        .foregroundStyle(isNorth ? Color.defaultGreen : Color.lightTextColor),
                    at: CGPoint(x: x, y: middle)
                )
            } else {
                let dot = CGRect(
                    x: x - Constants.dotRadius,
                    y: middle - Constants.dotRadius,
                    width: Constants.dotRadius * 2,
                    height: Constants.dotRadius * 2
                )
                let opacity = tick == driftTick ? Constants.litDotOpacity : Constants.dotOpacity
                context.fill(Path(ellipseIn: dot), with: .color(Color.textColor.opacity(opacity)))
            }
        }
    }

    private enum Constants {
        static let bandHeight: CGFloat = 22
        static let tickRowHeight: CGFloat = 22
        static let tickSpacing: Double = 22
        static let edgeFade: Double = 0.25
        static let bandOpacity: Double = .veryMinimalOpacity
        static let hatchSpacing: Double = 2.75
        static let hatchLean: Double = 9
        static let hatchWidth: CGFloat = 1
        static let hatchFade: Double = 0.3
        static let hatchOpacity: Double = .mediumOpacity
        static let dotRadius: Double = 1.5
        static let dotOpacity: Double = .semiLowOpacity
        static let litDotOpacity: Double = .opaque
        static let cardinals = ["N", "E", "S", "W"]
    }
}

#Preview {
    WaypointCompassStrip(heading: 0)
        .background(Color.defaultBackground)
}
