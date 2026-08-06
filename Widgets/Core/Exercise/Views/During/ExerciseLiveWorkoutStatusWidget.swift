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
    var onRestTime: () -> Void = {}
    var onStop: () -> Void = {}
    var onSkip: () -> Void = {}
    var onComplete: () -> Void = {}

    @State private var showsSource = false

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

                    value
                        .alignmentGuide(.valueCentre) { $0[VerticalAlignment.center] }
                }
                .animation(.brightSnappy, value: caption)

                Spacer(minLength: .spacing2x)

                controls
                    .alignmentGuide(.valueCentre) { $0[VerticalAlignment.center] }
            }
        }
        .padding(.horizontal, .spacing3x)
        .padding(.vertical, .spacing2x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Constants.cardHeight)
        .modifier(GlassCardModifier(cornerRadius: .cornerRadius24))
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: .spacing105x) {
            if showsSetControls {
                control(.restTime)
                control(.stop)
                control(.skip)
            }

            control(primary)
        }
        .animation(.brightSnappy, value: showsSetControls)
        .animation(.brightSnappy, value: primary)
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
        case restTime
        case stop
        case skip
        case complete
        case start

        var symbol: String {
            switch self {
            case .restTime: "gauge.with.needle"
            case .stop: "xmark.octagon"
            case .skip: "forward.end"
            case .complete: "checkmark"
            case .start: "play.fill"
            }
        }

        var tint: Color {
            switch self {
            case .restTime: .defaultPink
            case .stop: .defaultRed
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

    private func action(for control: Control) -> () -> Void {
        switch control {
        case .restTime: onRestTime
        case .stop: onStop
        case .skip: onSkip
        case .complete, .start: onComplete
        }
    }

    @ViewBuilder private var captionLabel: some View {
        if let caption {
            BrightText(caption, size: .body1, color: .lightTextColor, weight: .regular)
                .lineLimit(1)
                .fixedSize()
                .contentTransition(.numericText())
        }
    }

    // MARK: - Header

    private func heartRatePill(_ rate: String) -> some View {
        Button {
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
        .task(id: showsSource) {
            guard showsSource else { return }
            try? await Task.sleep(for: .seconds(Constants.sourceReveal))
            guard !Task.isCancelled else { return }
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

    @ViewBuilder private var value: some View {
        switch status {
        case let .working(label):
            valueText(label)

        case let .nextExercise(name):
            valueText(name)

        case let .resting(_, until):
            TimelineView(.animation(minimumInterval: Constants.tick, paused: false)) { context in
                let remaining = max(0, until.timeIntervalSince(context.date))

                BrightText(
                    countdown(remaining),
                    size: .standout1,
                    color: remaining <= Constants.urgentRemaining ? .defaultRed : .textColor
                )
                .monospacedDigit()
                .lineLimit(1)
            }

        case .allSetsComplete:
            valueText("Finish")
        }
    }

    private func valueText(_ text: String) -> some View {
        BrightText(text, size: .standout1, scaleTextSize: Constants.valueScale)
            .lineLimit(1)
    }

    private func countdown(_ remaining: TimeInterval) -> String {
        let seconds = Int(remaining.rounded(.up))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Per-status presentation

    /// The start state leads with the value alone — nothing sits above it.
    private var caption: String? {
        switch status {
        case .working: "In progress"
        case .nextExercise: nil
        case .resting: "Rest"
        case .allSetsComplete: "Workout complete"
        }
    }

    private var upNext: String? {
        guard case let .resting(upNext, _) = status else { return nil }
        return upNext
    }

    private enum Constants {
        static let cardHeight: CGFloat = 150
        static let pillHeight: CGFloat = 30
        static let sourceReveal: TimeInterval = 2
        static let tick: TimeInterval = 1
        static let valueScale: CGFloat = 0.6
        static let urgentRemaining: TimeInterval = 10
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
