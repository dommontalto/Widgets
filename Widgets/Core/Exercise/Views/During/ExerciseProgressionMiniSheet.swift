//
//  ExerciseProgressionMiniSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 8/8/2026.
//

import SwiftUI

struct ExerciseProgressionSet: Identifiable, Sendable {
    let id = UUID()
    let label: String
    let weight: String
    let reps: String
    let rpe: Int
}

struct ExerciseProgressionMiniSheet: View {
    let lastSessionDate: String
    let sets: [ExerciseProgressionSet]
    // How much the working weight moved off thel last session, in kg.
    let weightChange: Double
    var onRevert: () -> Void = {}
    var onClose: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            header

            VStack(alignment: .leading, spacing: .spacing2x) {
                BrightText("Last Session:  \(lastSessionDate)", size: .body1, color: .lightTextColor)

                lastSession
            }

            insight

            BrightPillButton("Revert", buttonSize: .large, onTapCallback: onRevert)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, -.spacing2x)
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: .spacing2x) {
            HStack(spacing: .spacing105x) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.standardSFPro(size: .standout3, weight: .medium))
                    .foregroundStyle(Color.textColor)

                BrightText("Progression", size: .standout3)
            }

            Spacer(minLength: .spacing2x)

            BrightRoundButton(systemImage: "xmark", size: .large, onTapCallback: onClose)
        }
    }

    // MARK: - Last session

    private var lastSession: some View {
        VStack(spacing: .spacing0x) {
            ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                if index > 0 {
                    BrightDivider()
                }

                row(set)
            }
        }
        .padding(.horizontal, .spacing2x)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    private func row(_ set: ExerciseProgressionSet) -> some View {
        HStack(spacing: .spacing0x) {
            BrightText(set.label, size: .body2)
                .frame(width: Constants.labelWidth, alignment: .leading)

            Spacer(minLength: .spacing2x)

            BrightText("\(set.weight) kg", size: .body2, weight: .regular)
                .monospacedDigit()

            divider

            BrightText(set.reps, size: .body2, weight: .regular)
                .monospacedDigit()

            divider

            BrightStatus(status: "RPE \(set.rpe)")
                .frame(width: Constants.rpeWidth)
        }
        .frame(height: Constants.rowHeight)
        .padding(.vertical, .spacing1x)
    }

    private var divider: some View {
        BrightVerticalDivider(height: Constants.dividerHeight)
            .padding(.horizontal, .spacing2x)
    }

    // MARK: - Insight

    private var insight: some View {
        BrightText(insightText, size: .subheading, color: .semiLightTextColor, weight: .regular)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var insightText: String {
        let arrow = weightChange > 0 ? "\u{2191}" : "\u{2193}"
        return "Based of your session, we've increased your working weight by \(arrow) \(abs(weightChange).formatted()) kg from your previous RPE this session"
    }

    private enum Constants {
        static let rowHeight: CGFloat = 45
        static let labelWidth: CGFloat = 50
        static let rpeWidth: CGFloat = 55
        static let dividerHeight: CGFloat = 30
    }
}

#Preview {
    Color.defaultBackground
        .ignoresSafeArea()
        .brightMiniSheet(isPresented: .constant(true)) {
            ExerciseProgressionMiniSheet(
                lastSessionDate: "Fri, 7 Aug",
                sets: [
                    ExerciseProgressionSet(label: "Set 1", weight: "80", reps: "5", rpe: 8),
                    ExerciseProgressionSet(label: "Set 2", weight: "80", reps: "5", rpe: 8),
                    ExerciseProgressionSet(label: "Set 3", weight: "90", reps: "5", rpe: 9),
                ],
                weightChange: 2.5
            )
        }
}
