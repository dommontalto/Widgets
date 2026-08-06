//
//  ExerciseLiveWorkoutStatusWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 4/8/2026.
//

import SwiftUI

struct ExerciseLiveWorkoutStatusWidget: View {
    enum Status {
        /// Mid-set: the tick logs `label`.
        case working(label: String)
        /// Every set here is logged, so the button opens the next exercise.
        case nextExercise(name: String)
        /// Between sets, counting down to `until`.
        case resting(upNext: String, until: Date)
        case allSetsComplete
    }

    let status: Status
    var heartRate: String?
    var onRPE: () -> Void = {}
    var onFailedSet: () -> Void = {}
    var onExtendRest: (TimeInterval) -> Void = { _ in }
    var onSkip: () -> Void = {}
    var onComplete: () -> Void = {}

    @State private var showsSource = false
    @State private var sourceTaps = 0

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            HStack(spacing: .spacing2x) {
                if let heartRate {
                    heartRatePill(heartRate)
                }

                Spacer(minLength: .spacing2x)

                if let upNext {
                    upNextLabel(upNext)
                }
            }

            Spacer(minLength: .spacing0x)

            // Aligned on the value rather than the whole stack, so the caption
            // sits above it without dragging it off the buttons' centre line.
            HStack(alignment: .valueCentre, spacing: .spacing2x) {
                VStack(alignment: .leading, spacing: .spacing1x) {
                    captionLabel

                    valueLabel
                        .alignmentGuide(.valueCentre) { $0[VerticalAlignment.center] }
                }

                Spacer(minLength: .spacing2x)

                controls
                    .alignmentGuide(.valueCentre) { $0[VerticalAlignment.center] }
            }
        }
        .padding(.horizontal, .spacing3x)
        .padding(.vertical, .spacing2x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Constants.cardHeight)
        .modifier(GlassCardModifier(cornerRadius: .cardCornerRadius))
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: .spacing105x) {
            if showsSetControls {
                control(.rpe)
            }

            restSlot(.failedSet, extending: Constants.shortExtension)
            restSlot(.skip, extending: Constants.longExtension)

            control(primary)
        }
        .animation(.brightSnappy, value: showsSetControls)
        .animation(.brightSnappy, value: isResting)
        .animation(.brightSnappy, value: primary)
    }

    /// Rest turns the set controls into rest extensions in place: both stay
    /// mounted and cross-fade, so the button reads as changing its mind the way
    /// the tick morphs into skip rather than one popping out for another.
    @ViewBuilder private func restSlot(_ control: Control, extending seconds: TimeInterval) -> some View {
        if showsSetControls || isResting {
            ZStack {
                self.control(control)
                    .opacity(isResting ? .zero : .opaque)
                    .scaleEffect(isResting ? Constants.swapScale : 1)
                    .allowsHitTesting(!isResting)

                extendRestButton(seconds)
                    .opacity(isResting ? .opaque : .zero)
                    .scaleEffect(isResting ? 1 : Constants.swapScale)
                    .allowsHitTesting(isResting)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    private func extendRestButton(_ seconds: TimeInterval) -> some View {
        BrightRoundButton(
            title: "+\(Int(seconds))",
            size: .extraLarge,
            fontSize: .subheading
        ) {
            onExtendRest(seconds)
        }
    }

    private func control(_ control: Control) -> some View {
        BrightRoundButton(
            systemImage: control.symbol,
            size: .extraLarge,
            color: control.tint,
            haptic: control.haptic,
            onTapCallback: action(for: control)
        )
        .contentTransition(.symbolEffect(.replace))
        .transition(.scale.combined(with: .opacity))
    }

    private enum Control {
        case rpe
        case failedSet
        case skip
        case complete
        case start

        var symbol: String {
            switch self {
            case .rpe: "gauge.with.needle"
            case .failedSet: "xmark.octagon"
            case .skip: "forward.end"
            case .complete: "checkmark"
            case .start: "play.fill"
            }
        }

        var tint: Color {
            switch self {
            case .rpe: .defaultPink
            case .failedSet: .defaultRed
            case .skip: .defaultBlue
            case .complete, .start: .defaultGreen
            }
        }

        var haptic: BrightHaptic {
            switch self {
            case .complete: .success
            default: .light
            }
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
        }
    }

    /// Always drawn, blank states included: one text view that every state writes
    /// into rolls its letters over, where a view that comes and goes can only cut
    /// — and it keeps the value pinned to the same line throughout.
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
            withAnimation(.brightSnappy) { showsSource = true }
        } label: {
            HStack(spacing: .spacing1x) {
                Image(systemName: "heart.fill")
                    .font(.standardSFPro(size: .subheading, weight: .regular))
                    .foregroundStyle(Color.defaultRed)

                BrightText(showsSource ? "Apple Watch" : "\(rate) BPM", size: .body1, weight: .regular)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, .spacing2x)
            .frame(height: Constants.pillHeight)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .modifier(GlassEffect(shape: .capsule, interactive: false))
        .task(id: sourceTaps) {
            guard sourceTaps > 0 else { return }
            // A fresh tap cancels this sleep; that tap's own window puts the
            // source away rather than this one cutting it short on the way out.
            do { try await Task.sleep(for: .seconds(Constants.sourceReveal)) } catch { return }
            withAnimation(.brightSnappy) { showsSource = false }
        }
    }

    private func upNextLabel(_ name: String) -> some View {
        HStack(spacing: .spacing1x) {
            Image(systemName: "arrow.turn.up.right")
                .font(.standardSFPro(size: .body1, weight: .regular))
                .foregroundStyle(Color.lightTextColor)

            BrightText("Up next: \(name)", size: .body1, color: .lightTextColor, weight: .regular)
        }
        .lineLimit(1)
    }

    // MARK: - Value

    /// The clock only drives the ticking; every state renders through this one
    /// text view so a state change rolls into the next value at one size instead
    /// of swapping in a differently-sized view.
    private var valueLabel: some View {
        TimelineView(.animation(minimumInterval: Constants.tick, paused: !isResting)) { context in
            let value = value(at: context.date)

            BrightText(
                value.text,
                size: .standout1,
                color: value.color,
                scaleTextSize: Constants.valueScale
            )
            .monospacedDigit()
            .lineLimit(1)
            .contentTransition(.numericText(countsDown: true))
            .animation(.brightSnappy, value: value.text)
        }
    }

    private func value(at date: Date) -> (text: String, color: Color) {
        switch status {
        case let .working(label):
            return (label, .textColor)

        case let .nextExercise(name):
            return (name, .textColor)

        case let .resting(_, until):
            let remaining = max(0, until.timeIntervalSince(date))
            return (countdown(remaining), remaining <= Constants.urgentRemaining ? .defaultRed : .textColor)

        case .allSetsComplete:
            return ("Finish", .textColor)
        }
    }

    private func countdown(_ remaining: TimeInterval) -> String {
        let seconds = Int(remaining.rounded(.up))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Per-status presentation

    /// The start and finish states lead with the value alone — nothing sits
    /// above it.
    private var caption: String? {
        switch status {
        case .working: "In progress"
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
        static let cardHeight: CGFloat = 150
        static let pillHeight: CGFloat = 30
        static let sourceReveal: TimeInterval = 2
        static let tick: TimeInterval = 1
        static let valueScale: CGFloat = 0.6
        static let urgentRemaining: TimeInterval = 10
        static let shortExtension: TimeInterval = 15
        static let longExtension: TimeInterval = 30
        /// How small the half of a swapping slot that isn't showing sits.
        static let swapScale: CGFloat = 0.6
    }
}

private extension VerticalAlignment {
    /// Lines the buttons up with the value alone — the caption above it would
    /// otherwise pull a plain `.center` off the button row.
    enum ValueCentre: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.center]
        }
    }

    static let valueCentre = VerticalAlignment(ValueCentre.self)
}

#Preview {
    VStack(spacing: .spacing3x) {
        ExerciseLiveWorkoutStatusWidget(status: .nextExercise(name: "Warmup"), heartRate: "121")

        ExerciseLiveWorkoutStatusWidget(status: .working(label: "Set 1"), heartRate: "121")

        ExerciseLiveWorkoutStatusWidget(
            status: .resting(upNext: "Set 2", until: Date().addingTimeInterval(263)),
            heartRate: "121"
        )

        ExerciseLiveWorkoutStatusWidget(
            status: .resting(upNext: "Set 2", until: Date().addingTimeInterval(5)),
            heartRate: "121"
        )

        ExerciseLiveWorkoutStatusWidget(status: .allSetsComplete, heartRate: "121")
    }
    .padding(.spacing3x)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.defaultBackground.ignoresSafeArea())
}

#Preview("Skip slides into the tick's slot") {
    @Previewable @State var isResting = false

    VStack(spacing: .spacing3x) {
        ExerciseLiveWorkoutStatusWidget(
            status: isResting
                ? .resting(upNext: "Set 2", until: Date().addingTimeInterval(263))
                : .working(label: "Set 1"),
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
