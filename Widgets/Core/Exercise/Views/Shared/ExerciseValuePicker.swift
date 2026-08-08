//
//  ExerciseValuePicker.swift
//  Widgets
//
//  Created by Dom Montalto on 6/8/2026.
//

import SwiftUI

struct ExerciseValuePicker: View {
    nonisolated struct Step: Sendable {
        let value: Int
        // Spelled out under the rail when the number needs explaining.
        var label: String?
    }

    let title: String
    let symbol: String
    let tint: Color
    // Sits above the rail, naming what the number counts.
    var caption: String?
    let steps: [Step]
    // Where the rail opens when nothing has been picked yet. Defaults to the
    // middle of the scale.
    var defaultValue: Int?
    var actionTitle = "Add"
    @Binding var value: Int?
    var onClose: () -> Void = {}

    @State private var selection = 0
    @State private var scrollPosition = ScrollPosition(idType: Int.self)
    @State private var railWidth: CGFloat = 0
    @State private var scrollTick = 0

    var body: some View {
        VStack(spacing: .spacing4x) {
            header

            VStack(spacing: .spacing2x) {
                if let caption {
                    BrightText(caption, size: .body1)
                }

                rail

                if let label = steps.first(where: { $0.value == selection })?.label {
                    BrightText(label, size: .body2, color: .semiLightTextColor)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                        .animation(.brightSnappy, value: label)
                }
            }

            BrightPillButton(actionTitle, color: .defaultGreen, buttonSize: .large) {
                value = selection
                onClose()
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity)
        .onAppear {
            guard !steps.isEmpty else { return }
            selection = value ?? defaultValue ?? steps[steps.count / 2].value
            scrollPosition.scrollTo(id: selection, anchor: .center)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: .spacing2x) {
            HStack(spacing: .spacing105x) {
                Image(systemName: symbol)
                    .font(.standard(size: .standout3, weight: .medium))
                    .foregroundStyle(tint)

                BrightText(title, size: .standout1)
            }

            Spacer(minLength: .spacing2x)

            BrightRoundButton(systemImage: "xmark", size: .large, onTapCallback: onClose)
        }
    }

    // MARK: - Rail

    private var rail: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Constants.itemGap) {
                ForEach(steps, id: \.value) { step in
                    Button {
                        withAnimation(.brightBouncy) {
                            scrollPosition.scrollTo(id: step.value, anchor: .center)
                        }
                    } label: {
                        BrightText("\(step.value)", size: .enormous)
                            .monospacedDigit()
                            .frame(width: Constants.itemWidth)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    // The value either side reads as a preview of where the swipe
                    // is heading, so it fades back rather than competing.
                    .scrollTransition(.animated(.brightBouncy)) { content, phase in
                        content
                            .opacity(phase.isIdentity ? .opaque : .minimalOpacity)
                            .scaleEffect(phase.isIdentity ? 1 : Constants.neighbourScale)
                    }
                    .id(step.value)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition($scrollPosition)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .contentMargins(.horizontal, railInset, for: .scrollContent)
        // The neighbours dissolve toward the rail's edges instead of being cut
        // off by them. The flat middle is exactly the centred item, so only the
        // flanking values pick up the fade.
        .mask {
            HStack(spacing: .spacing0x) {
                LinearGradient(stops: Constants.fadeInStops, startPoint: .leading, endPoint: .trailing)
                    .frame(width: railInset)

                Color.black

                LinearGradient(stops: Constants.fadeOutStops, startPoint: .leading, endPoint: .trailing)
                    .frame(width: railInset)
            }
        }
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { railWidth = $0 }
        // Read off the offset rather than which items are visible: four values
        // fit the rail at once, so visibility can't say which one is centred.
        .onScrollGeometryChange(for: Int.self) { geometry in
            Int(((geometry.contentOffset.x + geometry.contentInsets.leading) / Constants.itemPitch).rounded())
        } action: { _, index in
            guard steps.indices.contains(index), steps[index].value != selection else { return }
            selection = steps[index].value
            scrollTick += 1
        }
        .brightHaptic(.light, trigger: scrollTick)
    }

    private var railInset: CGFloat {
        guard railWidth > 0 else { return .spacing6x }
        return (railWidth - Constants.itemWidth) / 2
    }

    // nonisolated: referenced from Sendable closures (scrollTransition,
    // onScrollGeometryChange), which can't touch the view's MainActor state.
    private nonisolated enum Constants {
        static let itemWidth: CGFloat = 52
        static let itemGap: CGFloat = .spacing2x
        static let itemPitch = itemWidth + itemGap
        static let neighbourScale: CGFloat = 0.75
        // Clear for the first stretch either side, so a neighbour is gone well
        // before the rail's edge rather than dimming the whole way out.
        static let fadeInStops: [Gradient.Stop] = [
            .init(color: .clear, location: 0),
            .init(color: .clear, location: 0.7),
            .init(color: .black, location: 0.92),
        ]
        static let fadeOutStops: [Gradient.Stop] = [
            .init(color: .black, location: 0.08),
            .init(color: .clear, location: 0.3),
            .init(color: .clear, location: 1),
        ]
        // The 1–9 RPE scale: 1 is a set you could keep going all day, 9 leaves
        // nothing behind.
        static let rpeScale = [
            Step(value: 1, label: "Extremely easy"),
            Step(value: 2, label: "Very easy"),
            Step(value: 3, label: "Comfortable"),
            Step(value: 4, label: "Moderate"),
            Step(value: 5, label: "Challenging but controlled"),
            Step(value: 6, label: "Hard"),
            Step(value: 7, label: "Very Hard"),
            Step(value: 8, label: "Near maximum"),
            Step(value: 9, label: "Maximum effort"),
        ]
        // A set with no reps typed yet still needs a rail to swipe.
        static let minimumFailedReps = 12
    }
}

// MARK: - The card's pickers

extension ExerciseValuePicker {
    // Rates how hard the set felt.
    static func rpe(_ rpe: Binding<Int?>, onClose: @escaping () -> Void = {}) -> Self {
        ExerciseValuePicker(
            title: "RPE",
            symbol: "gauge.open.with.lines.needle.33percent",
            tint: .defaultPink,
            steps: Constants.rpeScale,
            value: rpe,
            onClose: onClose
        )
    }

    // Marks a set as failed and records the rep it went down on. The rail can't
    // run past the reps the set was going for.
    static func failedSet(
        targetReps: Int,
        failedRep: Binding<Int?>,
        onClose: @escaping () -> Void = {}
    ) -> Self {
        let reps = max(targetReps, Constants.minimumFailedReps)

        return ExerciseValuePicker(
            title: "Set Failed",
            symbol: "xmark.octagon",
            tint: .defaultRed,
            caption: "Failed at rep",
            steps: (1...reps).map { Step(value: $0) },
            defaultValue: min(max(targetReps, 1), reps),
            actionTitle: "Confirm",
            value: failedRep,
            onClose: onClose
        )
    }
}

#Preview("RPE") {
    @Previewable @State var rpe: Int?

    Color.defaultBackground
        .ignoresSafeArea()
        .brightMiniSheet(isPresented: .constant(true)) {
            ExerciseValuePicker.rpe($rpe)
        }
}

#Preview("Set failed") {
    @Previewable @State var failedRep: Int?

    Color.defaultBackground
        .ignoresSafeArea()
        .brightMiniSheet(isPresented: .constant(true)) {
            ExerciseValuePicker.failedSet(targetReps: 5, failedRep: $failedRep)
        }
}
