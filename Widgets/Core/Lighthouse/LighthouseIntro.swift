//
//  LighthouseIntro.swift
//  Widgets
//
//  Created by Dom Montalto on 15/9/2026.
//

import SwiftUI

// The beats of the opening: the screen sits dark, a single spark breathes
// where the beacon will be, then it goes off and the welcome condenses out of
// the blast. Ordered, so a view can ask whether a beat has passed.
enum LighthouseIntroPhase: Int, Comparable {
    case dark
    case spark
    case bang
    case title
    case subtitle
    case done

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// Everything the intro draws over the onboarding: the veil the screen starts
// under, the spark, and the burst that lights the room. It sits above the
// page and eats touches while it runs, so a tap anywhere skips ahead.
struct LighthouseIntro: View {
    let phase: LighthouseIntroPhase
    // Where the beacon lands, in global coordinates, so the burst comes from
    // exactly the point the beacon condenses onto.
    let beaconCentre: CGPoint
    let onSkip: () -> Void

    @State private var isBreathing = false
    @State private var bangDate: Date?

    var body: some View {
        ZStack {
            Color.defaultBlackWhite
                .ignoresSafeArea()
                .opacity(phase < .bang ? 1 : 0)
                .animation(.easeOut(duration: Constants.veilLift), value: phase)

            BrightScreenEdgeBeam(isActive: phase >= .bang && phase < .done)

            GeometryReader { proxy in
                let centre = localCentre(in: proxy)

                if phase == .spark {
                    spark
                        .position(centre)
                        .transition(.scale.combined(with: .opacity))
                }

                if let bangDate {
                    LighthouseIntroBurst(start: bangDate, centre: centre)
                }
            }
            .ignoresSafeArea()
        }
        .animation(.brightSnappy, value: phase)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSkip)
        .onChange(of: phase) { _, phase in
            if phase >= .bang, bangDate == nil {
                bangDate = .now
            }
        }
    }

    // A pinprick of light with a soft halo, swelling and easing back like a
    // filament warming up.
    private var spark: some View {
        ZStack {
            Circle()
                .fill(Color.defaultLighthouseBlue.opacity(.lowOpacity))
                .frame(width: Constants.sparkHalo, height: Constants.sparkHalo)
                .blur(radius: Constants.sparkHaloBlur)

            Circle()
                .fill(Color.white)
                .frame(width: Constants.sparkSize, height: Constants.sparkSize)
                .blur(radius: Constants.sparkBlur)
        }
        .scaleEffect(isBreathing ? Constants.sparkBreath : 1)
        .animation(
            .easeInOut(duration: Constants.sparkBreathDuration).repeatForever(autoreverses: true),
            value: isBreathing
        )
        .onAppear { isBreathing = true }
    }

    private func localCentre(in proxy: GeometryProxy) -> CGPoint {
        let origin = proxy.frame(in: .global).origin
        return CGPoint(x: beaconCentre.x - origin.x, y: beaconCentre.y - origin.y)
    }

    private enum Constants {
        static let veilLift: TimeInterval = 0.8
        static let sparkSize: CGFloat = .spacing105x
        static let sparkBlur: CGFloat = 1.5
        static let sparkHalo: CGFloat = .spacing8x
        static let sparkHaloBlur: CGFloat = .spacing3x
        static let sparkBreath: CGFloat = 1.6
        static let sparkBreathDuration: TimeInterval = 0.45
    }
}

// The bang itself, drawn analytically from the time since it went off: a
// full-screen flash, a flare that swells and thins to nothing, three
// shockwave rings and a scatter of sparks thrown out with short comet tails.
// One canvas per frame keeps it cheap; the intro takes it down once done.
private struct LighthouseIntroBurst: View {
    let start: Date
    let centre: CGPoint

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSince(start)
            Canvas { graphics, size in
                let reach = max(size.width, size.height)
                drawFlash(t, in: &graphics, size: size)
                drawFlare(t, in: &graphics, reach: reach)
                drawRings(t, in: &graphics, reach: reach)
                drawSparks(t, in: &graphics, reach: reach)
            }
        }
        .allowsHitTesting(false)
    }

    private func drawFlash(_ t: TimeInterval, in graphics: inout GraphicsContext, size: CGSize) {
        guard t < Constants.flashDuration else { return }
        let fade = 1 - t / Constants.flashDuration
        let alpha = Constants.flashPeak * fade * fade
        graphics.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(alpha)))
    }

    private func drawFlare(_ t: TimeInterval, in graphics: inout GraphicsContext, reach: CGFloat) {
        guard t < Constants.flareDuration else { return }
        let progress = t / Constants.flareDuration
        let radius = Constants.flareStart + reach * Constants.flareSpread * easeOut(progress)
        let alpha = pow(1 - progress, 1.5)
        let gradient = Gradient(colors: [
            .white.opacity(alpha),
            Color.defaultLighthouseBlue.opacity(alpha * Double.lowOpacity),
            .clear,
        ])
        let rect = CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2)
        graphics.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(gradient, center: centre, startRadius: 0, endRadius: radius)
        )
    }

    private func drawRings(_ t: TimeInterval, in graphics: inout GraphicsContext, reach: CGFloat) {
        for ring in 0..<Constants.ringCount {
            let local = t - Double(ring) * Constants.ringStagger
            guard local > 0, local < Constants.ringDuration else { continue }
            let progress = local / Constants.ringDuration
            let radius = Constants.ringStart + reach * easeOut(progress)
            let rect = CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2)
            graphics.stroke(
                Path(ellipseIn: rect),
                with: .color(Color.textColor.opacity(Double.mediumOpacity * (1 - progress))),
                lineWidth: Constants.ringWidth * (1 - progress) + Constants.ringHairline
            )
        }
    }

    private func drawSparks(_ t: TimeInterval, in graphics: inout GraphicsContext, reach: CGFloat) {
        for index in 0..<Constants.sparkCount {
            let angle = hash(index, 1.3) * 2 * .pi
            let speed = (Constants.sparkMinSpeed + hash(index, 4.1) * (1 - Constants.sparkMinSpeed)) * reach
            let life = Constants.sparkMinLife + hash(index, 6.7) * (Constants.sparkMaxLife - Constants.sparkMinLife)
            let width = Constants.sparkMinWidth + hash(index, 9.2) * (Constants.sparkMaxWidth - Constants.sparkMinWidth)
            let progress = t / life
            guard progress > 0, progress < 1 else { continue }

            let direction = CGVector(dx: cos(angle), dy: sin(angle))
            let head = position(direction, distance: speed * easeOut(progress))
            let tail = position(direction, distance: speed * easeOut(max(0, progress - Constants.sparkTail)))

            var path = Path()
            path.move(to: tail)
            path.addLine(to: head)
            graphics.stroke(
                path,
                with: .color(Color.textColor.opacity(1 - progress)),
                style: StrokeStyle(lineWidth: width * (1 - progress) + Constants.ringHairline, lineCap: .round)
            )
        }
    }

    private func position(_ direction: CGVector, distance: CGFloat) -> CGPoint {
        CGPoint(x: centre.x + direction.dx * distance, y: centre.y + direction.dy * distance)
    }

    private func easeOut(_ progress: Double) -> CGFloat {
        1 - pow(1 - min(1, max(0, progress)), 3)
    }

    // A fract(sin) hash, so the scatter is the same every time it plays.
    private func hash(_ index: Int, _ salt: Double) -> Double {
        let value = sin(Double(index) * 12.9898 + salt * 78.233) * 43758.5453
        return value - value.rounded(.down)
    }

    private enum Constants {
        static let flashDuration: TimeInterval = 0.45
        static let flashPeak: Double = .veryHighOpacity
        static let flareDuration: TimeInterval = 1.3
        static let flareStart: CGFloat = .spacing6x
        static let flareSpread: CGFloat = 0.9
        static let ringCount = 3
        static let ringStagger: TimeInterval = 0.1
        static let ringDuration: TimeInterval = 1.4
        static let ringStart: CGFloat = .spacing4x
        static let ringWidth: CGFloat = .spacing1x
        static let ringHairline: CGFloat = 0.5
        static let sparkCount = 56
        static let sparkMinSpeed: Double = 0.35
        static let sparkMinLife: TimeInterval = 0.8
        static let sparkMaxLife: TimeInterval = 1.7
        static let sparkMinWidth: CGFloat = 1
        static let sparkMaxWidth: CGFloat = 3
        static let sparkTail: Double = 0.08
    }
}

#Preview {
    @Previewable @State var phase = LighthouseIntroPhase.dark

    ZStack {
        LighthouseChatBackground()

        LighthouseBeacon(size: 176)
            .opacity(phase >= .bang ? 1 : 0)

        LighthouseIntro(phase: phase, beaconCentre: CGPoint(x: 196, y: 426)) {
            phase = .done
        }
    }
    .task {
        try? await Task.sleep(for: .seconds(0.5))
        phase = .spark
        try? await Task.sleep(for: .seconds(1))
        phase = .bang
    }
}
