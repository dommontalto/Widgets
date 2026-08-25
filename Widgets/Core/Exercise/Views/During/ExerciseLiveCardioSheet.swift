//
//  ExerciseLiveCardioSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import SwiftUI

struct ExerciseLiveCardioSheet: View {
    var session: ExerciseLiveCardioStats = ExerciseDemoData.liveCardioStats
    var isInterval = true
    var onStop: () -> Void = {}
    // Ends the whole run. Only the flow can do that from a pushed leg, where
    // `dismiss` would pop back instead.
    var onClose: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var isPaused = false
    @State private var runningSince = Date()
    @State private var bankedElapsed: TimeInterval = 0

    var body: some View {
        VStack(spacing: .spacing0x) {
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
        // Full-screen cover, so the beam takes the display's own curve and rings
        // every edge.
        .overlay {
            // Runs for the whole session; pausing puts it out, playing relights it.
            BrightScreenEdgeBeam(isActive: !isPaused, colorVariant: .defaultGreen)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if let onClose { onClose() } else { dismiss() }
                } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.standard(size: .subheading, weight: .regular))
                        .foregroundStyle(Color.textColor)
                }
            }
        }
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
        .padding(.vertical, .spacing4x)
    }

    private var heartRateRow: some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: "heart.fill")
                .font(.standard(size: .huge, weight: .light))
                .foregroundStyle(Color.defaultRed)
                .exerciseHeartRatePulse(bpm: Double(session.heartRate))

            BrightText(session.heartRate, size: .enormous, color: .defaultRed, scaleTextSize: 0.8)
                .monospacedDigit()
                .lineLimit(1)

            ExerciseHeartRateTrace()

            zoneChip
        }
        .padding(.horizontal, .spacing4x)
        .padding(.vertical, .spacing4x)
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
                color: splitColor,
                delta: session.splitDelta
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // A split slower than the average reads red, a faster one green. Level, or
    // with no split logged yet, it stays plain text.
    private var splitColor: Color {
        let delta = session.splitDelta
        if delta.hasPrefix("+") { return .defaultRed }
        if delta.hasPrefix("\u{2212}") || delta.hasPrefix("-") { return .defaultGreen }
        return .textColor
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
        .padding(.bottom, .spacing4x)
    }

    // MARK: - Interval

    private var intervalRow: some View {
        TimelineView(.animation(minimumInterval: Constants.tick, paused: isPaused)) { context in
            let state = intervalState(at: context.date)

            ExerciseLiveIntervalStrip(
                segments: session.segments.map {
                    ExerciseLiveIntervalStrip.Segment(color: $0.kind.color, weight: $0.weight)
                },
                currentIndex: state.index,
                progress: state.progress,
                label: state.label,
                detail: state.remaining
            )
        }
        .padding(.horizontal, .spacing4x)
        .padding(.top, .spacing4x)
    }

    // Plays the plan off the session clock at the demo pace, looping when the
    // legs run out so the strip never stops moving.
    private func intervalState(at date: Date) -> (index: Int?, progress: Double, label: String, remaining: String) {
        let total = session.segments.reduce(0) { $0 + $1.weight }
        guard total > 0 else { return (nil, 0, "", "") }

        let metres = elapsed(at: date) * Constants.demoMetresPerSecond
        let looped = metres.truncatingRemainder(dividingBy: total)

        var covered: Double = 0
        for (index, segment) in session.segments.enumerated() {
            let end = covered + segment.weight
            if looped < end {
                let progress = (looped - covered) / max(segment.weight, 1)
                let secondsLeft = Int((end - looped) / Constants.demoMetresPerSecond)
                return (index, progress, segment.kind.title, remainingString(secondsLeft))
            }
            covered = end
        }
        return (nil, 1, "", "")
    }

    private func remainingString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: .spacing1x) {
            BrightRoundButton(
                systemImage: "stop.fill",
                size: .finalBossLarge,
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

            BrightRoundButton(systemImage: isPaused ? "play" : "pause", size: .finalBossLarge) {
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

    private func elapsed(at date: Date) -> TimeInterval {
        isPaused ? bankedElapsed : bankedElapsed + date.timeIntervalSince(runningSince)
    }

    private func elapsedString(at date: Date) -> String {
        let centiseconds = Int(max(0, elapsed(at: date)) * 100)
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
        // Fast enough that the demo run crosses a leg while you watch.
        static let demoMetresPerSecond: Double = 50
    }
}

#Preview("Interval") {
    Color.defaultBackground
        .ignoresSafeArea()
        .fullScreenCover(isPresented: .constant(true)) {
            NavigationStack {
                ExerciseLiveCardioSheet()
            }
        }
}

#Preview("Non interval") {
    Color.defaultBackground
        .ignoresSafeArea()
        .fullScreenCover(isPresented: .constant(true)) {
            NavigationStack {
                ExerciseLiveCardioSheet(isInterval: false)
            }
        }
}
