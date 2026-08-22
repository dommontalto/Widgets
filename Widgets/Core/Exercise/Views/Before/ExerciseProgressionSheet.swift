//
//  ExerciseProgressionSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 21/8/2026.
//

import SwiftUI

// How an exercise's load should climb: what grows (weight or reps), by how
// much, and how often.
struct ExerciseProgression: Equatable {
    enum Metric {
        case weight
        case reps
    }

    enum WeightUnit {
        case kg
        case lbs

        // kg climbs by the half-plate, lbs by the 2.5 lb microplate.
        var step: Double {
            switch self {
            case .kg: 0.5
            case .lbs: 2.5
            }
        }

        var label: String {
            switch self {
            case .kg: "KG"
            case .lbs: "lbs"
            }
        }
    }

    enum Cadence {
        case perSession
        case perWeek

        var label: String {
            switch self {
            case .perSession: "Per Session"
            case .perWeek: "Per week"
            }
        }
    }

    var metric: Metric = .weight
    var unit: WeightUnit = .kg
    var cadence: Cadence = .perWeek
    // Ruler positions, one per metric, so swapping between them loses neither.
    var weightIndex = 5
    var repIndex = 1

    var amount: Double {
        Double(weightIndex) * unit.step
    }

    // Reads back on the card that opened the sheet, e.g. "2.5 kg /week".
    var summary: String {
        let cadence = cadence == .perWeek ? "week" : "session"
        switch metric {
        case .weight:
            return "\(amount.formatted()) \(unit == .kg ? "kg" : "lbs") /\(cadence)"
        case .reps:
            return "\(repIndex) rep\(repIndex == 1 ? "" : "s") /\(cadence)"
        }
    }
}

struct ExerciseProgressionSheet: View {
    let progression: ExerciseProgression
    let onApply: (ExerciseProgression) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var draft: ExerciseProgression

    init(progression: ExerciseProgression, onApply: @escaping (ExerciseProgression) -> Void) {
        self.progression = progression
        self.onApply = onApply
        _draft = State(initialValue: progression)
    }

    var body: some View {
        BrightPageSheetView(
            title: "Progression",
            horizontalPadding: .spacing0x,
            showBackButton: true,
            trailing: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        onApply(draft)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.defaultSkyBlue)
                }
            },
            content: {
                VStack(alignment: .leading, spacing: .spacing0x) {
                    Spacer(minLength: .spacing3x)

                    amount
                        .padding(.horizontal, .spacing3x)

                    Spacer(minLength: .spacing3x)

                    ruler

                    bottomBar
                        .padding(.horizontal, .spacing3x)
                        .padding(.top, .spacing8x)
                }
            }
        )
    }

    // MARK: - Amount

    private var amount: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            Image(systemName: "arrow.up")
                .font(.standard(size: .giant, weight: .light))
                .foregroundStyle(Color.textColor)

            BrightText(valueText, size: .enormous)
                .contentTransition(.numericText())
                .animation(.brightSnappy, value: valueText)

            cadenceChip
        }
    }

    private var valueText: String {
        switch draft.metric {
        case .weight:
            switch draft.unit {
            case .kg: String(format: "%.1f", draft.amount) + " KG"
            case .lbs: "\(draft.amount.formatted()) lbs"
            }
        case .reps:
            "\(draft.repIndex) Rep\(draft.repIndex == 1 ? "" : "s")"
        }
    }

    private var cadenceChip: some View {
        Button {
            withAnimation(.brightSnappy) {
                draft.cadence = draft.cadence == .perWeek ? .perSession : .perWeek
            }
        } label: {
            BrightText(draft.cadence.label, size: .subheading)
                .padding(.horizontal, .spacing2x)
                .padding(.vertical, .spacing1x)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .modifier(GlassEffect())
        .brightHaptic(.light, trigger: draft.cadence)
    }

    // MARK: - Ruler

    private var ruler: some View {
        BrightRulerPicker(value: rulerValue, range: rulerRange)
            .frame(height: Constants.rulerHeight)
            // The ruler seeds itself from the binding once, so swapping metric
            // hands it a fresh one at the other metric's position.
            .id(draft.metric)
    }

    private var rulerValue: Binding<Int> {
        switch draft.metric {
        case .weight: $draft.weightIndex
        case .reps: $draft.repIndex
        }
    }

    private var rulerRange: ClosedRange<Int> {
        switch draft.metric {
        case .weight: 0 ... 100
        case .reps: 0 ... 30
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: .spacing2x) {
            BrightRoundButton(title: draft.unit.label, size: .large, fontSize: .subheading) {
                withAnimation(.brightSnappy) {
                    draft.unit = draft.unit == .kg ? .lbs : .kg
                }
            }

            Spacer(minLength: .spacing2x)

            BrightRoundButton(systemImage: "arrow.left.arrow.right", size: .large) {
                withAnimation(.brightSnappy) {
                    draft.metric = draft.metric == .weight ? .reps : .weight
                }
            }
        }
    }

    private enum Constants {
        static let rulerHeight: CGFloat = 60
    }
}

#Preview {
    ExerciseProgressionSheet(progression: ExerciseProgression()) { _ in }
}
