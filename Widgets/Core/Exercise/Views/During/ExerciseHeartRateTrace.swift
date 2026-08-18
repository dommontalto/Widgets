//
//  ExerciseHeartRateTrace.swift
//  Widgets
//
//  Created by Dom Montalto on 14/8/2026.
//

import SwiftUI

struct ExerciseHeartRateTrace: View {
    // The wave and the heart pump run at a fixed demo rate — the live reading
    // only drives the number beside them, so the animation stays steady
    // between readings.
    var bpm: Double = Constants.demoBpm

    var width: CGFloat?
    var height: CGFloat = Constants.height
    var lineWidth: CGFloat = Constants.lineWidth

    var body: some View {
        TimelineView(.animation) { context in
            ExerciseHeartRateWave(beatWidth: Constants.beatWidth)
                .stroke(
                    Color.defaultRed,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
                .offset(x: -shift(at: context.date))
        }
        .frame(width: width, height: height)
        .clipped()
        .mask {
            LinearGradient(
                colors: [.clear, .white],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .allowsHitTesting(false)
    }

    // Phased off the wall clock rather than a repeating animation, so the heart
    // pump can derive the same phase and land exactly on each loop's start.
    static func beatPhase(at date: Date, bpm: Double) -> Double {
        let interval = bpm > 0 ? 60 / bpm : Constants.restingInterval
        return date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: interval) / interval
    }

    private func shift(at date: Date) -> CGFloat {
        CGFloat(Self.beatPhase(at: date, bpm: bpm)) * Constants.beatWidth
    }

    enum Constants {
        static let height: CGFloat = .spacing5x
        static let lineWidth: CGFloat = .spacing025x
        static let beatWidth: CGFloat = .spacing8x
        static let restingInterval: TimeInterval = 1
        static let pulseScale: CGFloat = 0.18
        static let demoBpm: Double = 121
    }
}

extension View {
    // Nil holds the heart still: the wave can carry a steady demo rate because
    // it reads as a backdrop, but a beating heart claims a reading.
    func exerciseHeartRatePulse(bpm: Double?) -> some View {
        modifier(ExerciseHeartRatePulse(bpm: bpm))
    }
}

private struct ExerciseHeartRatePulse: ViewModifier {
    let bpm: Double?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let bpm {
            TimelineView(.animation) { context in
                content.scaleEffect(scale(at: context.date, bpm: bpm))
            }
        } else {
            content
        }
    }

    // Two rapid pumps squeezed into the top of each beat, then still until the
    // next one comes round.
    private func scale(at date: Date, bpm: Double) -> CGFloat {
        let beatPhase = ExerciseHeartRateTrace.beatPhase(at: date, bpm: bpm)
        guard beatPhase < Constants.pumpWindow else { return 1 }
        let pumpPhase = (beatPhase / Constants.pumpWindow * Constants.pumpsPerBeat)
            .truncatingRemainder(dividingBy: 1)
        return 1 + ExerciseHeartRateTrace.Constants.pulseScale * CGFloat(pow(sin(.pi * pumpPhase), 2))
    }

    private enum Constants {
        // The share of the beat the double pump takes before the heart rests.
        static let pumpWindow: Double = 0.3
        static let pumpsPerBeat: Double = 2
    }
}

private struct ExerciseHeartRateWave: Shape {
    let beatWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let amplitude = rect.height / 2 * Constants.amplitudeInset
        let end = ((rect.width / beatWidth).rounded(.up) + 1) * beatWidth

        var x: CGFloat = 0
        while x <= end {
            let position = x / beatWidth
            let beat = position - position.rounded(.down)
            let point = CGPoint(x: x, y: midY - Self.waveform(at: beat) * amplitude)
            if x == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
            x += Constants.step
        }
        return path
    }

    private static func waveform(at beat: CGFloat) -> CGFloat {
        switch beat {
        case Constants.pStart ..< Constants.pEnd:
            bump(beat, from: Constants.pStart, to: Constants.pEnd) * Constants.pHeight
        case Constants.qStart ..< Constants.rPeak:
            -ramp(beat, from: Constants.qStart, to: Constants.rPeak) * Constants.qDepth
        case Constants.rPeak ..< Constants.rEnd:
            ramp(beat, from: Constants.rPeak, to: Constants.rEnd)
        case Constants.rEnd ..< Constants.sTrough:
            -ramp(beat, from: Constants.rEnd, to: Constants.sTrough) * Constants.sDepth
        case Constants.sTrough ..< Constants.sEnd:
            -(1 - ramp(beat, from: Constants.sTrough, to: Constants.sEnd)) * Constants.sDepth
        case Constants.tStart ..< Constants.tEnd:
            bump(beat, from: Constants.tStart, to: Constants.tEnd) * Constants.tHeight
        default:
            0
        }
    }

    private static func ramp(_ value: CGFloat, from start: CGFloat, to end: CGFloat) -> CGFloat {
        (value - start) / (end - start)
    }

    private static func bump(_ value: CGFloat, from start: CGFloat, to end: CGFloat) -> CGFloat {
        sin(.pi * (value - start) / (end - start))
    }

    private enum Constants {
        static let step: CGFloat = 1.5
        static let amplitudeInset: CGFloat = 0.9

        static let pStart: CGFloat = 0.06
        static let pEnd: CGFloat = 0.16
        static let pHeight: CGFloat = 0.16
        static let qStart: CGFloat = 0.24
        static let rPeak: CGFloat = 0.3
        static let rEnd: CGFloat = 0.36
        static let sTrough: CGFloat = 0.42
        static let sEnd: CGFloat = 0.5
        static let qDepth: CGFloat = 0.2
        static let sDepth: CGFloat = 0.4
        static let tStart: CGFloat = 0.56
        static let tEnd: CGFloat = 0.76
        static let tHeight: CGFloat = 0.3
    }
}

#Preview {
    VStack(spacing: .spacing4x) {
        HStack(spacing: .spacing2x) {
            Image(systemName: "heart.fill")
                .font(.standard(size: .huge, weight: .light))
                .foregroundStyle(Color.defaultRed)
                .exerciseHeartRatePulse(bpm: 62)

            ExerciseHeartRateTrace(bpm: 62)
        }

        HStack(spacing: .spacing1x) {
            Image(systemName: "heart.fill")
                .font(.standard(size: .subheading, weight: .regular))
                .foregroundStyle(Color.defaultRed)
                .exerciseHeartRatePulse(bpm: ExerciseHeartRateTrace.Constants.demoBpm)

            ExerciseHeartRateTrace(width: .spacing7x, height: .spacing3x)
        }
    }
    .padding(.spacing4x)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.defaultBackground)
}
