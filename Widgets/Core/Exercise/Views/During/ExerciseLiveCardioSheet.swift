//
//  ExerciseLiveCardioSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import SwiftUI

struct ExerciseLiveCardioSheet: View {
    var session: ExerciseLiveSession = ExerciseDemoData.liveSession
    var isInterval = true
    var onStop: () -> Void = {}

    @State private var isPaused = false
    @State private var runningSince = Date()
    @State private var bankedElapsed: TimeInterval = 0

    var body: some View {
        VStack(spacing: .spacing0x) {
            ExerciseInlineTitle(file: #file)
                .padding(.top, .spacing2x)

            metric("CURRENT PACE", value: session.currentPace, color: .defaultCyan)

            BrightDivider()

            metric("DISTANCE", value: session.distance, color: .defaultYellow)

            BrightDivider()

            heartRateRow

            BrightDivider()

            paceRow

            BrightDivider()

            if isInterval {
                intervalRow
            }

            Spacer(minLength: .spacing4x)

            controls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.defaultBackground.ignoresSafeArea())
        .overlay {
            BrightScreenEdgeBeam(isActive: !isPaused)
        }
        .presentationBackground(Color.defaultBackground)
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Stat blocks

    private func metric(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: .spacing1x) {
            BrightText(label, size: .heading, color: color)

            BrightText(value, size: .enormous, color: color, scaleTextSize: 0.8)
                .monospacedDigit()
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacing5x)
    }

    private var heartRateRow: some View {
        HStack(spacing: .spacing4x) {
            HStack(spacing: .spacing2x) {
                Image(systemName: "heart.fill")
                    .font(.standard(size: .huge, weight: .light))
                    .foregroundStyle(Color.defaultRed)

                BrightText(session.heartRate, size: .enormous, color: .defaultRed)
                    .monospacedDigit()
            }

            zoneChip
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, .spacing4x)
        .padding(.vertical, .spacing5x)
    }

    private var zoneChip: some View {
        BrightText(session.heartRateZone, size: .standout28, color: .defaultYellow)
            .padding(.horizontal, .spacing105x)
            .padding(.vertical, .spacing2x)
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous)
                    .strokeBorder(
                        Color.defaultYellow.opacity(.lowOpacity),
                        lineWidth: Constants.hairline
                    )
            }
    }

    private var paceRow: some View {
        HStack(spacing: .spacing0x) {
            paceColumn("AVG PACE", value: session.averagePace, color: .textColor)

            BrightVerticalDivider()

            paceColumn(
                "SPLIT",
                value: session.splitPace,
                color: .defaultGreen,
                delta: session.splitDelta
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func paceColumn(
        _ label: String,
        value: String,
        color: Color,
        delta: String? = nil
    ) -> some View {
        VStack(spacing: .spacing2x) {
            BrightText(label, size: .body1, color: .lightTextColor)

            HStack(alignment: .lastTextBaseline, spacing: .spacing1x) {
                BrightText(value, size: .giant, color: color)
                    .monospacedDigit()

                if let delta {
                    BrightText(delta, size: .standout1, color: color.opacity(.lowOpacity))
                        .monospacedDigit()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, .spacing4x)
        .padding(.bottom, .spacing3x)
    }

    // MARK: - Interval

    private var intervalRow: some View {
        HStack(spacing: .spacing1x) {
            intervalPill

            segmentBars
        }
        .padding(.horizontal, .spacing4x)
        .padding(.top, .spacing6x)
    }

    private var intervalPill: some View {
        HStack(spacing: .spacing2x) {
            BrightText(session.intervalName, size: .heading, color: session.intervalColor)

            Spacer(minLength: .spacing2x)

            BrightText(session.intervalRemaining, size: .heading, color: session.intervalColor)
                .monospacedDigit()
        }
        .padding(.horizontal, .spacing2x)
        .frame(height: .spacing9x)
        .background(
            session.intervalColor.opacity(.ultraLowOpacity),
            in: RoundedRectangle(cornerRadius: .cornerRadius20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: .cornerRadius20, style: .continuous)
                .strokeBorder(
                    session.intervalColor.opacity(.lowOpacity),
                    lineWidth: Constants.hairline
                )
        }
    }

    private var segmentBars: some View {
        HStack(spacing: .spacing1x) {
            ForEach(session.segments) { segment in
                Capsule()
                    .fill(segment.kind.color.opacity(.veryLowOpacity))
                    .frame(width: Constants.segmentWidth, height: Constants.segmentHeight)
            }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: .spacing1x) {
            BrightRoundButton(
                systemImage: "stop.fill",
                size: .extraLarge,
                imageColor: .defaultRed,
                haptic: .medium,
                onTapCallback: onStop
            )

            Spacer(minLength: .spacing1x)

            TimelineView(.animation(minimumInterval: Constants.tick, paused: isPaused)) { context in
                BrightText(elapsedString(at: context.date), size: .huge, scaleTextSize: 0.7)
                    .monospacedDigit()
                    .lineLimit(1)
            }

            Spacer(minLength: .spacing1x)

            BrightRoundButton(systemImage: isPaused ? "play" : "pause", size: .extraLarge) {
                withAnimation(.brightEaseInOut) { togglePause() }
            }
            .contentTransition(.symbolEffect(.replace))
        }
        .padding(.horizontal, .spacing3x)
        .padding(.bottom, .spacing3x)
    }

    private func togglePause() {
        if isPaused {
            runningSince = Date()
        } else {
            bankedElapsed += Date().timeIntervalSince(runningSince)
        }
        isPaused.toggle()
    }

    private func elapsedString(at date: Date) -> String {
        let elapsed = isPaused ? bankedElapsed : bankedElapsed + date.timeIntervalSince(runningSince)
        let centiseconds = Int(max(0, elapsed) * 100)
        return String(
            format: "%02d:%02d:%02d",
            centiseconds / 6000,
            centiseconds / 100 % 60,
            centiseconds % 100
        )
    }

    private enum Constants {
        static let hairline: CGFloat = 0.5
        static let tick: TimeInterval = 0.03
        static let segmentWidth: CGFloat = 9
        static let segmentHeight: CGFloat = 43
    }
}

#Preview("Interval") {
    Color.defaultBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ExerciseLiveCardioSheet()
        }
}

#Preview("Non interval") {
    Color.defaultBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ExerciseLiveCardioSheet(isInterval: false)
        }
}
