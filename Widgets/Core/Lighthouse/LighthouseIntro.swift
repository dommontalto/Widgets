//
//  LighthouseIntro.swift
//  Widgets
//
//  Created by Dom Montalto on 15/9/2026.
//

import SwiftUI

// The beats of the opening: the screen sits dark, then the beacon goes off
// and the welcome condenses out of the blast. Ordered, so a view can ask
// whether a beat has passed.
enum LighthouseIntroPhase: Int, Comparable {
    case dark
    case bang
    case title
    case subtitle
    // The page is settled and usable; the edge beam is still glowing.
    case done
    // The afterglow has gone too.
    case faded

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// Everything the intro draws over the onboarding: the veil the screen starts
// under, the burst that lights the room and the edge beam it leaves glowing.
// It sits above the page and eats touches while it runs, so a tap anywhere
// skips ahead; the caller lets touches through once settled.
struct LighthouseIntro: View {
    let phase: LighthouseIntroPhase
    // Where the beacon lands, in global coordinates, so the burst comes from
    // exactly the point the beacon condenses onto.
    let beaconCentre: CGPoint
    let onSkip: () -> Void

    @State private var bangDate: Date?
    @State private var beamOpacity: Double = .opaque

    var body: some View {
        ZStack {
            Color.defaultBlackWhite
                .ignoresSafeArea()
                .opacity(phase < .bang ? 1 : 0)
                .animation(.easeOut(duration: Constants.veilLift), value: phase)

            // Lit by the bang, then dwindling steadily the whole way to gone.
            BrightScreenEdgeBeam(isActive: phase >= .bang && phase < .faded, duration: Constants.beamLap)
                .opacity(beamOpacity)

            GeometryReader { proxy in
                if let bangDate {
                    LighthouseIntroBurst(start: bangDate, centre: localCentre(in: proxy))
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
                withAnimation(.linear(duration: Constants.beamDwindle)) {
                    beamOpacity = .zero
                }
            }
        }
    }

    private func localCentre(in proxy: GeometryProxy) -> CGPoint {
        let origin = proxy.frame(in: .global).origin
        return CGPoint(x: beaconCentre.x - origin.x, y: beaconCentre.y - origin.y)
    }

    private enum Constants {
        static let veilLift: TimeInterval = 0.8
        // Matches the beats from the bang to the afterglow's end.
        static let beamDwindle: TimeInterval = 5
        // A single trip round the screen over the whole afterglow, pinned
        // rather than paced so it always lands as the glow goes.
        static let beamLap: TimeInterval = beamDwindle
    }
}

// The bang itself, drawn analytically from the time since it went off: a
// full-screen flash and a flare that swells and thins to nothing.
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

    private func easeOut(_ progress: Double) -> CGFloat {
        1 - pow(1 - min(1, max(0, progress)), 3)
    }

    private enum Constants {
        static let flashDuration: TimeInterval = 0.45
        static let flashPeak: Double = .veryHighOpacity
        static let flareDuration: TimeInterval = 1.3
        static let flareStart: CGFloat = .spacing6x
        static let flareSpread: CGFloat = 0.9
    }
}

#Preview {
    @Previewable @State var phase = LighthouseIntroPhase.dark

    ZStack {
        LighthouseChatBackground()

        LighthouseBeacon(size: 176, isLit: phase >= .bang)
            .opacity(phase >= .bang ? 1 : 0)

        LighthouseIntro(phase: phase, beaconCentre: CGPoint(x: 196, y: 426)) {
            phase = .done
        }
    }
    .task {
        try? await Task.sleep(for: .seconds(1.5))
        phase = .bang
    }
}
