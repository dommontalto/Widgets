//
//  ExerciseLiveStrengthStatusWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 4/8/2026.
//

import SwiftUI

// Prototype. The Bright app builds this card on a shell that's generic over its
// content, so a cardio session can use it too — port the design across, not
// this file's structure.
struct ExerciseLiveStrengthStatusWidget: View {
    enum Status {
        // Mid-set: `set` names the set, `target` is the weight and reps it's for.
        case working(set: String, target: String)
        // Every set here is logged, so the button opens the next exercise.
        case nextExercise(name: String)
        // Between sets, counting down to `until`.
        case resting(upNext: String, until: Date)
        case allSetsComplete
    }

    // What's reporting the rate, named and drawn while the pill shows its source.
    enum Source: String {
        case appleWatch = "Apple Watch"
        case airPods = "AirPods"
        case chestStrap = "Chest strap"

        var symbol: String {
            switch self {
            case .appleWatch: "applewatch"
            case .airPods: "airpods.pro"
            case .chestStrap: "heart.circle"
            }
        }
    }

    let status: Status
    var heartRate: String?
    var heartRateSource: Source = .appleWatch
    var onRPE: () -> Void = {}
    var onFailedSet: () -> Void = {}
    var onExtendRest: (TimeInterval) -> Void = { _ in }
    var onSkip: () -> Void = {}
    var onComplete: () -> Void = {}

    @State private var showsSource = false
    @State private var sourceTaps = 0

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            HStack(spacing: .spacing0x) {
                if let heartRate {
                    heartRatePill(heartRate)
                }

                Spacer(minLength: .spacing0x)

                if let upNext {
                    upNextLabel(upNext)
                }
            }

            Spacer(minLength: .spacing0x)

            // Aligned on the value rather than the whole stack, so the caption
            // sits above it without dragging it off the buttons' centre line.
            HStack(alignment: .valueCentre, spacing: .spacing1x) {
                VStack(alignment: .leading, spacing: .spacing1x) {
                    captionLabel

                    valueLabel
                        .alignmentGuide(.valueCentre) { $0[VerticalAlignment.center] }
                }

                Spacer(minLength: .spacing1x)

                controls
                    .alignmentGuide(.valueCentre) { $0[VerticalAlignment.center] }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Constants.cardHeight)
        .background(Color.exerciseLiveBar, in: Constants.shape)
        // The Lighthouse input card's glass and geometry — softer at the top,
        // tighter where it meets the screen edge.
        .modifier(GlassEffect(
            shape: .unevenRoundedRect(top: Constants.topCorner, bottom: Constants.bottomCorner),
            interactive: false
        ))
        // Lifts the card off whatever scrolls under it.
        .shadow(
            color: .black.opacity(Double.veryMinimalOpacity),
            radius: Constants.shadowRadius,
            y: Constants.shadowDrop
        )
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: .spacing1x) {
            if showsSetControls {
                control(.rpe)
            }

            if showsSetControls || isResting {
                control(isResting ? .extendRest(Constants.shortExtension) : .failedSet)
                control(isResting ? .extendRest(Constants.longExtension) : .skip)
            }

            control(primary)
        }
        .animation(.brightSnappy, value: showsSetControls)
        .animation(.brightSnappy, value: isResting)
        .animation(.brightSnappy, value: primary)
    }

    // Skipping a set sits beside the tick and takes the screen's own blue;
    // skipping the rest is the primary button, so it stays green.
    private func control(_ control: Control) -> some View {
        BrightRoundButton(
            systemImage: control.symbol,
            size: .large,
            color: control.tint,
            imageRotation: .zero,
            imageOffset: control.imageOffset,
            haptic: control.haptic,
            tinted: true,
            onTapCallback: action(for: control)
        )
        .contentTransition(.symbolEffect(.replace))
        .transition(.scale.combined(with: .opacity))
    }

    private enum Control: Hashable {
        case rpe
        case failedSet
        case skip
        case complete
        case start
        // Adds `seconds` to the rest that's running.
        case extendRest(TimeInterval)

        var symbol: String {
            switch self {
            case .rpe: "gauge.open.with.lines.needle.33percent"
            case .failedSet: "xmark.octagon"
            case .skip: "forward.end"
            case .complete: "checkmark"
            case .start: "play.fill"
            // A glyph either side of the swap, so the button morphs into it the
            // way the tick morphs into skip — text can't take part in that.
            case let .extendRest(seconds): "goforward.\(Int(seconds))"
            }
        }

        // Rest extensions stay clear glass — nil leaves the glyph on `textColor`.
        var tint: Color? {
            switch self {
            case .rpe: .defaultPink
            case .failedSet: .defaultRed
            case .skip: .defaultSkyBlueCyan
            case .complete, .start: .defaultGreen
            case .extendRest: nil
            }
        }

        var haptic: BrightHaptic {
            switch self {
            case .complete: .success
            default: .light
            }
        }

        var imageOffset: CGSize {
            self == .rpe ? CGSize(width: 0, height: -2) : .zero
        }
    }

    private var showsSetControls: Bool {
        if case .working = status { true } else { false }
    }

    private var primary: Control {
        switch status {
        case .working, .allSetsComplete: .complete
        case .nextExercise: .start
        case .resting: .skip
        }
    }

    private func action(for control: Control) -> (() -> Void)? {
        switch control {
        case .rpe: onRPE
        case .failedSet: onFailedSet
        case .skip: onSkip
        case .complete, .start: onComplete
        case let .extendRest(seconds): { onExtendRest(seconds) }
        }
    }

    // Always drawn, blank states included: one text view that every state writes
    // into rolls its letters over, where a view that comes and goes can only cut
    // — and it keeps the value pinned to the same line throughout.
    private var captionLabel: some View {
        BrightText(caption ?? " ", size: .body1, color: .lightTextColor, weight: .regular)
                .lineLimit(1)
            .fixedSize()
                .contentTransition(.numericText())
            .animation(.brightSnappy, value: caption)
    }

    // MARK: - Header

    private func heartRatePill(_ rate: String) -> some View {
        Button {
            // Counts the taps rather than keying the window on `showsSource`:
            // tapping while the source shows has to restart the window, and an
            // unchanged flag would leave the first one to run out.
            sourceTaps += 1
            withAnimation(.brightSnappy) { showsSource.toggle() }
        } label: {
            HStack(spacing: .spacing1x) {
                // Beats at the rate it's reporting, so the pill reads as live —
                // and stands still as the watch while it names what's reporting.
                Image(systemName: showsSource ? heartRateSource.symbol : "heart.fill")
                    .font(.standard(size: .subheading, weight: .regular))
                    .foregroundStyle(showsSource ? Color.textColor : Color.defaultRed)
                    .contentTransition(.symbolEffect(.replace))
                    .exerciseHeartRatePulse(bpm: showsSource ? nil : Double(rate))

                BrightText(showsSource ? heartRateSource.rawValue : "\(rate) BPM", size: .body1, weight: .regular)
                    .contentTransition(.numericText())

                if !showsSource {
                    ExerciseHeartRateTrace(
                        width: Constants.traceWidth,
                        height: Constants.traceHeight
                    )
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, .spacing105x)
            .frame(height: Constants.pillHeight)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .modifier(GlassEffect(shape: .capsule, interactive: false))
        .task(id: sourceTaps) {
            guard showsSource else { return }
            // A fresh tap cancels this sleep; that tap's own window puts the
            // source away rather than this one cutting it short on the way out.
            do { try await Task.sleep(for: .seconds(Constants.sourceReveal)) } catch { return }
            withAnimation(.brightSnappy) { showsSource = false }
        }
    }

    private func upNextLabel(_ name: String) -> some View {
        HStack(spacing: .spacing1x) {
            Image(systemName: "arrow.turn.up.right")
                .font(.standard(size: .body1, weight: .regular))
                .foregroundStyle(Color.lightTextColor)

            BrightText("Up next: \(name)", size: .body1, color: .lightTextColor, weight: .regular)
        }
        .lineLimit(1)
    }

    // MARK: - Value

    // The clock only drives the ticking; every state renders through this one
    // text view so a state change rolls into the next value at one size instead
    // of swapping in a differently-sized view.
    private var valueLabel: some View {
        TimelineView(.animation(minimumInterval: Constants.tick, paused: !isResting)) { context in
            let value = value(at: context.date)

            BrightText(value.text, size: Constants.valueSize, color: value.color)
                .monospacedDigit()
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.brightSnappy, value: value.text)
                // Only the colour separates a target from a countdown, so it
                // eases between them rather than snapping.
                .animation(.brightEaseInOut, value: value.color)
        }
    }

    private func value(at date: Date) -> (text: String, color: Color) {
        switch status {
        case let .working(_, target):
            return (target, .textColor)

        case let .nextExercise(name):
            return (name, .textColor)

        case let .resting(_, until):
            let remaining = max(0, until.timeIntervalSince(date))
            return (countdown(remaining), remaining <= Constants.urgentRemaining ? .defaultRed : .defaultSkyBlueCyan)

        case .allSetsComplete:
            return ("Finish", .textColor)
        }
    }

    private func countdown(_ remaining: TimeInterval) -> String {
        let seconds = Int(remaining.rounded(.up))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Per-status presentation

    // The start and finish states lead with the value alone — nothing sits
    // above it.
    private var caption: String? {
        switch status {
        case let .working(set, _): set
        case .resting: "Rest"
        case .nextExercise, .allSetsComplete: nil
        }
    }

    private var upNext: String? {
        guard case let .resting(upNext, _) = status else { return nil }
        return upNext
    }

    private var isResting: Bool {
        if case .resting = status { true } else { false }
    }

    private enum Constants {
        static let cardHeight: CGFloat = 160
        static let pillHeight: CGFloat = 30
        static let sourceReveal: TimeInterval = 2
        static let traceWidth: CGFloat = .spacing7x
        static let traceHeight: CGFloat = .spacing3x
        static let tick: TimeInterval = 1
        static let valueSize: FontSizes = .huge
        static let urgentRemaining: TimeInterval = 10
        static let shortExtension: TimeInterval = 15
        static let longExtension: TimeInterval = 30
        static let topCorner: CGFloat = 36
        static let bottomCorner: CGFloat = 44
        static let shadowRadius: CGFloat = 20
        static let shadowDrop: CGFloat = 6

        static var shape: UnevenRoundedRectangle {
            UnevenRoundedRectangle(cornerRadii: .init(
                topLeading: topCorner,
                bottomLeading: bottomCorner,
                bottomTrailing: bottomCorner,
                topTrailing: topCorner
            ))
        }
        // How small the half of a swapping slot that isn't showing sits.
    }
}

private extension VerticalAlignment {
    // Lines the buttons up with the value alone — the caption above it would
    // otherwise pull a plain `.center` off the button row.
    enum ValueCentre: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.center]
        }
    }

    static let valueCentre = VerticalAlignment(ValueCentre.self)
}

#Preview {
    VStack(spacing: .spacing3x) {
        ExerciseLiveStrengthStatusWidget(status: .nextExercise(name: "Warmup"), heartRate: "121")

        ExerciseLiveStrengthStatusWidget(status: .working(set: "Set 3", target: "80x4"), heartRate: "121")

        ExerciseLiveStrengthStatusWidget(
            status: .resting(upNext: "Set 2", until: Date().addingTimeInterval(263)),
            heartRate: "121"
        )

        ExerciseLiveStrengthStatusWidget(
            status: .resting(upNext: "Set 2", until: Date().addingTimeInterval(5)),
            heartRate: "121"
        )

        ExerciseLiveStrengthStatusWidget(status: .allSetsComplete, heartRate: "121")
    }
    .padding(.spacing3x)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.defaultBackground.ignoresSafeArea())
}

#Preview("Skip slides into the tick's slot") {
    @Previewable @State var isResting = false

    VStack(spacing: .spacing3x) {
        ExerciseLiveStrengthStatusWidget(
            status: isResting
                ? .resting(upNext: "Set 2", until: Date().addingTimeInterval(263))
                : .working(set: "Set 3", target: "80x4"),
            heartRate: "121",
            onSkip: { isResting = false },
            onComplete: { isResting = true }
        )

        Button("Toggle rest") { isResting.toggle() }
    }
    .padding(.spacing3x)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.defaultBackground.ignoresSafeArea())
}
