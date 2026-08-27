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
    @State private var page: Int? = Constants.statsPage
    // The pages ignore the safe area so the map can bleed; the text pages get
    // the top inset handed back through this.
    @State private var topInset: CGFloat = 0
    // Shared with the route generator and the completed map, so all three read
    // the same way.
    @AppStorage("exerciseRouteMapIsDark") private var isDarkMap = false

    var body: some View {
        ZStack(alignment: .bottom) {
            pages
                .ignoresSafeArea()

            bottomBar
        }
        .overlay(alignment: .topTrailing) { topBar }
        .background(Color.defaultBackground.ignoresSafeArea())
        .background {
            Color.clear
                .ignoresSafeArea()
                .onGeometryChange(for: CGFloat.self, of: \.safeAreaInsets.top) { topInset = $0 }
        }
        // Full-screen cover, so the beam takes the display's own curve and rings
        // every edge.
        .overlay {
            // Runs for the whole session; pausing puts it out, playing relights it.
            BrightScreenEdgeBeam(isActive: !isPaused, colorVariant: .skyBlueCyan)
        }
        // No nav bar: the pages run under it, and it would push every one of
        // them down by its own height.
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topBar: some View {
        HStack(spacing: .spacing2x) {
            // The map is the only page it changes anything on.
            if page == Constants.mapPage {
                mapStyleButton
                    .transition(.blurReplace)
            }

            minimiseButton
        }
        .padding(.trailing, .spacing3x)
        .animation(.brightSnappy, value: page)
    }

    private var mapStyleButton: some View {
        BrightRoundButton(
            systemImage: isDarkMap ? "moon.fill" : "sun.max.fill",
            size: .large,
            color: Constants.chromeColor,
            imageColor: .defaultWhite
        ) {
            withAnimation(.brightSnappy) { isDarkMap.toggle() }
        }
        .contentTransition(.symbolEffect(.replace))
        .environment(\.colorScheme, .dark)
    }

    private var minimiseButton: some View {
        BrightRoundButton(systemImage: "arrow.down.right.and.arrow.up.left", size: .large) {
            if let onClose { onClose() } else { dismiss() }
        }
    }

    // The pages run the full height of the screen; the indicator and the
    // controls ride above them.
    private var bottomBar: some View {
        VStack(spacing: .spacing0x) {
            BrightPageIndicator(total: Constants.pageCount, activeIndex: $page)

            controls
        }
    }

    // MARK: - Pages

    private var pages: some View {
        TabView(selection: selectedPage) {
            ExerciseLiveCardioSplits(splits: session.splits)
                .padding(.top, topInset + .spacing2x)
                .tag(0)

            statsPage
                .padding(.top, topInset + .spacing2x)
                .tag(1)

            ExerciseLiveCardioMap()
                // The pager lays its pages out inside the safe area whatever
                // the TabView ignores, so the map takes the top inset back.
                .padding(.top, -topInset)
                .tag(Constants.mapPage)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    // BrightPageIndicator drives an optional index; the TabView needs a plain one.
    private var selectedPage: Binding<Int> {
        Binding(get: { page ?? Constants.statsPage }, set: { page = $0 })
    }

    private var statsPage: some View {
        VStack(spacing: .spacing0x) {
            metric("CURRENT PACE", value: session.currentPace, color: .defaultSkyBlueCyan)

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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Stat blocks

    private func metric(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: .spacing1x) {
            BrightText(label, size: .heading, color: color)

            BrightText(value, size: .enormous, color: color)
                .monospacedDigit()
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacing2x)
    }

    private var heartRateRow: some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: "heart.fill")
                .font(.standard(size: .huge, weight: .light))
                .foregroundStyle(Color.defaultRed)
                .exerciseHeartRatePulse(bpm: Double(session.heartRate))

            BrightText(session.heartRate, size: .enormous, color: .defaultRed)
                .monospacedDigit()
                .lineLimit(1)

            ExerciseHeartRateTrace()

            zoneChip
        }
        .padding(.horizontal, .spacing4x)
        .padding(.vertical, .spacing4x)
    }

    private var zoneChip: some View {
        BrightText(session.heartRateZone, size: .standout28, color: .defaultRed)
            .padding(.horizontal, .spacing105x)
            .padding(.vertical, .spacing2x)
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous)
                    .strokeBorder(
                        Color.defaultRed.opacity(.lowOpacity),
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
                BrightText(elapsedString(at: context.date), size: .huge)
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
        static let pageCount = 3
        static let statsPage = 1
        static let mapPage = 2
        static let chromeColor = Color.defaultBlack.opacity(.lowOpacity)
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
