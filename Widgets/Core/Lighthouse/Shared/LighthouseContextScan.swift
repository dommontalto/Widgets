//
//  LighthouseContextScan.swift
//  Widgets
//

import SwiftUI

// Switching context aware on reads the screen: a band of light sweeps down the page and the page flushes blue for a
// beat. The tray asks for it; the app's root draws it, under the tray and over
// everything else.
@MainActor @Observable
final class LighthouseContextScan {
    static let shared = LighthouseContextScan()

    private(set) var scanCount = 0

    func scan() {
        scanCount += 1
    }
}

struct LighthouseContextScanOverlay: View {
    private let scan = LighthouseContextScan.shared

    var body: some View {
        ZStack {
            Color.defaultSkyBlue
                .keyframeAnimator(initialValue: Double.zero, trigger: scan.scanCount) { content, wash in
                    content.opacity(wash)
                } keyframes: { _ in
                    LinearKeyframe(Constants.washPeak, duration: Constants.washRise)
                    CubicKeyframe(.zero, duration: Constants.sweepDuration)
                }
                .ignoresSafeArea()

            GeometryReader { geo in
                if geo.size.height > 0 {
                    sweep(in: geo.size)
                }
            }
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }

    private func sweep(in size: CGSize) -> some View {
        sweepBand
            .frame(height: Constants.bandHeight)
            .keyframeAnimator(initialValue: SweepPhase(), trigger: scan.scanCount) { content, phase in
                content
                    .offset(y: phase.progress * (size.height + Constants.bandHeight) - Constants.bandHeight)
                    .opacity(phase.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.progress) {
                    CubicKeyframe(1, duration: Constants.sweepDuration)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(1, duration: Constants.washRise)
                    LinearKeyframe(1, duration: Constants.sweepDuration - Constants.washRise * 2)
                    LinearKeyframe(.zero, duration: Constants.washRise)
                }
            }
    }

    // A soft band of blue with a bright core, blurred so it reads as light passing over the page.
    private var sweepBand: some View {
        LinearGradient(
            stops: [
                .init(color: Color.defaultSkyBlue.opacity(.zero), location: 0),
                .init(color: Color.defaultSkyBlue.opacity(.lowOpacity), location: 0.45),
                .init(color: Color.white.opacity(.lowOpacity), location: 0.5),
                .init(color: Color.defaultSkyBlue.opacity(.lowOpacity), location: 0.55),
                .init(color: Color.defaultSkyBlue.opacity(.zero), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .blur(radius: .spacing2x)
        .blendMode(.plusLighter)
    }

    private enum Constants {
        static let sweepDuration: TimeInterval = 1.1
        static let washRise: TimeInterval = 0.12
        static let washPeak: Double = 0.12
        static let bandHeight: CGFloat = .spacing12x * 2
    }
}

private struct SweepPhase {
    var progress: CGFloat = .zero
    var opacity: Double = .zero
}
