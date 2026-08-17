//
//  ExerciseHeartrateWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 17/8/2026.
//

import SwiftUI

struct ExerciseHeartrateWidget: View {
    @State private var trace: CGFloat = .zero

    var body: some View {
        HStack(spacing: .spacing3x) {
            heartRate
            traceLine
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
    }

    private var heartRate: some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: "heart.fill")
                .font(.standard(size: .standout2, weight: .medium))
                .foregroundStyle(Color.defaultRed)
                .phaseAnimator([Constants.restingScale, Constants.beatScale]) { icon, scale in
                    icon.scaleEffect(scale)
                } animation: { _ in .brightBouncy }

            HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                BrightText("67", size: .huge)
                BrightText("bpm", size: .body4, color: .lightTextColor)
            }
        }
    }

    private var traceLine: some View {
        HeartrateTraceShape()
            .trim(from: max(0, trace - Constants.traceTail), to: trace)
            .stroke(
                Color.defaultRed,
                style: StrokeStyle(lineWidth: Constants.traceLineWidth, lineCap: .round, lineJoin: .round)
            )
            .background(
                HeartrateTraceShape()
                    .stroke(
                        Color.defaultRed.opacity(.minimalOpacity),
                        style: StrokeStyle(lineWidth: Constants.traceLineWidth, lineCap: .round, lineJoin: .round)
                    )
            )
            .frame(maxWidth: .infinity)
            .frame(height: Constants.traceHeight)
            .onAppear {
                // Sweeping past 1 lets the bright segment run off the right
                // edge before the loop restarts.
                withAnimation(.brightRepeatForever) {
                    trace = 1 + Constants.traceTail
                }
            }
    }

    private enum Constants {
        static let restingScale: CGFloat = 1.0
        static let beatScale: CGFloat = 1.2
        static let traceTail: CGFloat = 0.25
        static let traceLineWidth: CGFloat = 2
        static let traceHeight: CGFloat = 44
    }
}

private struct HeartrateTraceShape: Shape {
    // One ECG beat — baseline, P bump, QRS spike, T bump — as
    // (x within the beat, y offset from the baseline) rect fractions.
    private static let beat: [(x: CGFloat, y: CGFloat)] = [
        (0.00, 0), (0.18, 0),
        (0.24, -0.10), (0.30, 0),
        (0.38, 0.06), (0.44, -0.62), (0.52, 0.22), (0.58, 0),
        (0.70, -0.14), (0.80, 0),
        (1.00, 0)
    ]

    private static let beatCount = 2
    private static let baselineFraction: CGFloat = 0.7

    func path(in rect: CGRect) -> Path {
        let baseline = rect.minY + rect.height * Self.baselineFraction
        let beatWidth = rect.width / CGFloat(Self.beatCount)

        var path = Path()
        for beatIndex in 0..<Self.beatCount {
            for (pointIndex, point) in Self.beat.enumerated() {
                let position = CGPoint(
                    x: rect.minX + beatWidth * (CGFloat(beatIndex) + point.x),
                    y: baseline + rect.height * point.y
                )
                if beatIndex == 0 && pointIndex == 0 {
                    path.move(to: position)
                } else {
                    path.addLine(to: position)
                }
            }
        }
        return path
    }
}

#Preview {
    ExerciseHeartrateWidget()
        .padding(.spacing4x)
}
