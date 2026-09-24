//
//  ExploreAgentAnimation.swift
//  Widgets
//
//  Created by Dom Montalto on 24/9/2026.
//

import SwiftUI

// Each agent's own picture of the work while it is being created: products
// scanned off a shelf, a radar sweeping for nearby clinics, or a lens reading
// down a paper.
struct ExploreAgentAnimation: View {
    enum Style {
        case shelf
        case radar
        case scan
    }

    let style: Style
    let tint: Color

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            switch style {
            case .shelf:
                ExploreShelfAnimation(time: time, tint: tint)
            case .radar:
                ExploreRadarAnimation(time: time, tint: tint)
            case .scan:
                ExploreScanAnimation(time: time, tint: tint)
            }
        }
        .frame(height: Constants.height)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private enum Constants {
        static let height: CGFloat = 108
    }
}

// Seconds into a loop of `period`, as 0...1.
nonisolated private func loopPhase(_ time: TimeInterval, period: Double, offset: Double = 0) -> Double {
    let raw = (time / period + offset).truncatingRemainder(dividingBy: 1)
    return raw < 0 ? raw + 1 : raw
}

private struct ExploreShelfAnimation: View {
    let time: TimeInterval
    let tint: Color

    private let products = ["pills.fill", "applewatch", "takeoutbag.and.cup.and.straw.fill", "leaf.fill", "drop.fill"]

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let scanner = scannerPosition(in: width)

            ZStack(alignment: .leading) {
                HStack(spacing: .spacing2x) {
                    ForEach(products.indices, id: \.self) { index in
                        tile(products[index], glow: glow(for: index, scanner: scanner, width: width))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                scannerLine
                    .offset(x: scanner - Constants.lineWidth / 2)
            }
        }
    }

    private func scannerPosition(in width: CGFloat) -> CGFloat {
        let phase = loopPhase(time, period: Constants.sweepPeriod)
        let eased = (1 - cos(phase * 2 * .pi)) / 2
        return width * CGFloat(eased)
    }

    private func glow(for index: Int, scanner: CGFloat, width: CGFloat) -> Double {
        let slot = width / CGFloat(products.count)
        let center = slot * (CGFloat(index) + 0.5)
        let distance = abs(center - scanner) / slot
        return Double(max(0, 1 - distance))
    }

    private func tile(_ symbol: String, glow: Double) -> some View {
        let scale = 1 + Constants.tileGrow * glow
        return Image(systemName: symbol)
            .font(.standardSFPro(size: .standout3, weight: .regular))
            .foregroundStyle(tint.opacity(Constants.restOpacity + (1 - Constants.restOpacity) * glow))
            .frame(width: Constants.tileSize, height: Constants.tileSize)
            .background(
                tint.opacity(Constants.tileWash * glow),
                in: RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous)
            )
            .scaleEffect(scale)
    }

    private var scannerLine: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [tint.opacity(0), tint, tint.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: Constants.lineWidth)
            .shadow(color: tint, radius: Constants.lineGlow)
    }

    private enum Constants {
        static let sweepPeriod: Double = 4.4
        static let tileSize: CGFloat = 48
        static let tileGrow: Double = 0.14
        static let tileWash: Double = 0.2
        static let restOpacity: Double = 0.3
        static let lineWidth: CGFloat = 2
        static let lineGlow: CGFloat = 6
    }
}

private struct ExploreRadarAnimation: View {
    let time: TimeInterval
    let tint: Color

    private let clinics: [CGPoint] = [
        CGPoint(x: -0.62, y: -0.28),
        CGPoint(x: 0.44, y: -0.52),
        CGPoint(x: 0.78, y: 0.22),
        CGPoint(x: -0.3, y: 0.56),
        CGPoint(x: 0.18, y: 0.34),
    ]

    var body: some View {
        GeometryReader { proxy in
            let radius = proxy.size.width / 2
            let rise = proxy.size.height / 2 * Constants.verticalSquash
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)

            ZStack {
                ForEach(0 ..< Constants.ringCount, id: \.self) { ring in
                    ringView(ring, radius: radius)
                        .position(center)
                }

                ForEach(clinics.indices, id: \.self) { index in
                    clinicDot(reach: reach(of: clinics[index], radius: radius, rise: rise))
                        .position(point(for: clinics[index], center: center, radius: radius, rise: rise))
                }

                Image(systemName: "mappin.circle.fill")
                    .font(.standardSFPro(size: .standout3, weight: .regular))
                    .foregroundStyle(tint)
                    .position(center)
            }
        }
    }

    private func ringPhase(_ ring: Int) -> Double {
        loopPhase(time, period: Constants.pulsePeriod, offset: Double(ring) / Double(Constants.ringCount))
    }

    private func ringView(_ ring: Int, radius: CGFloat) -> some View {
        let phase = ringPhase(ring)
        let size = radius * 2 * CGFloat(phase)
        return Circle()
            .stroke(tint.opacity(1 - phase), lineWidth: Constants.ringWidth)
            .frame(width: size, height: size)
    }

    private func point(for clinic: CGPoint, center: CGPoint, radius: CGFloat, rise: CGFloat) -> CGPoint {
        CGPoint(x: center.x + clinic.x * radius, y: center.y + clinic.y * rise)
    }

    private func reach(of clinic: CGPoint, radius: CGFloat, rise: CGFloat) -> Double {
        let distance = hypot(clinic.x * radius, clinic.y * rise)
        return Double(distance / max(radius, 1))
    }

    // A dot lights as a ring passes over it, then settles back.
    private func clinicDot(reach: Double) -> some View {
        var light: Double = 0
        for ring in 0 ..< Constants.ringCount {
            let gap = abs(ringPhase(ring) - reach)
            light = max(light, 1 - min(gap / Constants.dotLit, 1))
        }
        return Circle()
            .fill(tint.opacity(Constants.dotRest + (1 - Constants.dotRest) * light))
            .frame(width: Constants.dotSize, height: Constants.dotSize)
            .scaleEffect(1 + Constants.dotGrow * light)
    }

    private enum Constants {
        static let ringCount = 3
        static let pulsePeriod: Double = 3.6
        static let ringWidth: CGFloat = 1.5
        static let verticalSquash: CGFloat = 0.9
        static let dotSize: CGFloat = 8
        static let dotRest: Double = 0.25
        static let dotLit: Double = 0.18
        static let dotGrow: Double = 0.6
    }
}

private struct ExploreScanAnimation: View {
    let time: TimeInterval
    let tint: Color

    private let lines: [CGFloat] = [0.92, 0.78, 0.86, 0.6]

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width * Constants.pageWidth
            let lens = lensPosition(width: width, height: proxy.size.height)

            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: Constants.lineGap) {
                    ForEach(lines.indices, id: \.self) { index in
                        lineView(index, width: width, lens: lens, height: proxy.size.height)
                    }
                }
                .frame(width: width, height: proxy.size.height, alignment: .leading)

                Image(systemName: "magnifyingglass")
                    .font(.standardSFPro(size: .standout2, weight: .regular))
                    .foregroundStyle(tint)
                    .position(lens)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    // Reads each line left to right, then drops to the next.
    private func lensPosition(width: CGFloat, height: CGFloat) -> CGPoint {
        let phase = loopPhase(time, period: Constants.readPeriod) * Double(lines.count)
        let line = Int(phase) % lines.count
        let progress = phase - Double(Int(phase))
        let eased = (1 - cos(progress * .pi)) / 2
        let x = width * lines[line] * CGFloat(eased)
        return CGPoint(x: x, y: lineCenter(line, height: height))
    }

    private func lineCenter(_ line: Int, height: CGFloat) -> CGFloat {
        let block = Constants.lineHeight * CGFloat(lines.count) + Constants.lineGap * CGFloat(lines.count - 1)
        let top = (height - block) / 2
        return top + CGFloat(line) * (Constants.lineHeight + Constants.lineGap) + Constants.lineHeight / 2
    }

    private func lineView(_ index: Int, width: CGFloat, lens: CGPoint, height: CGFloat) -> some View {
        let isCurrent = abs(lineCenter(index, height: height) - lens.y) < 1
        let isRead = lineCenter(index, height: height) < lens.y - 1
        let lineWidth = width * lines[index]
        let readWidth: CGFloat = isRead ? lineWidth : (isCurrent ? min(lens.x, lineWidth) : 0)

        return Capsule()
            .fill(Color.textColor.opacity(.ultraLowOpacity))
            .frame(width: lineWidth, height: Constants.lineHeight)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(tint.opacity(Constants.readOpacity))
                    .frame(width: readWidth, height: Constants.lineHeight)
            }
    }

    private enum Constants {
        static let readPeriod: Double = 6.4
        static let pageWidth: CGFloat = 0.86
        static let lineHeight: CGFloat = 10
        static let lineGap: CGFloat = .spacing2x
        static let readOpacity: Double = 0.6
    }
}

#Preview {
    VStack(spacing: .spacing4x) {
        ExploreAgentAnimation(style: .shelf, tint: .defaultGreen)
        ExploreAgentAnimation(style: .radar, tint: .defaultSkyBlue)
        ExploreAgentAnimation(style: .scan, tint: .defaultBrightViolet)
    }
    .padding(.spacing3x)
    .background(Color.defaultBackground)
}
