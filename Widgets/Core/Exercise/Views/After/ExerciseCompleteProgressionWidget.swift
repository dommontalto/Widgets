//
//  ExerciseCompleteProgressionWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import SwiftUI

// One exercise's sets, headed by how its load moved against the last session.
struct ExerciseCompleteProgressionWidget: View {
    let progression: ExerciseCompleteProgression

    // Set to make the whole card open the exercise it belongs to.
    var onSelectExercise: ((String) -> Void)?

    var body: some View {
        if let onSelectExercise {
            Button { onSelectExercise(progression.exercise) } label: { card }
                .buttonStyle(.plain)
        } else {
            card
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(progression.date ?? progression.exercise, size: .body1, weight: .regular)
                .padding(.leading, .spacing2x)

            VStack(alignment: .leading, spacing: .spacing0x) {
                change

                BrightText(progression.direction.note, size: .body1, color: .lightTextColor)
                    .padding(.top, .spacing1x)
                    .padding(.bottom, .spacing3x)

                ForEach(Array(progression.sets.enumerated()), id: \.element.id) { index, set in
                    BrightDivider()

                    setRow(set)
                        .padding(.top, .spacing2x)
                        .padding(
                            .bottom,
                            index == progression.sets.count - 1 ? .spacing0x : .spacing2x
                        )
                }
            }
            .padding(.spacing3x)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
        }
    }

    private var change: some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: "arrow.up")
                .font(.standard(size: .standout4, weight: .light))
                .foregroundStyle(progression.direction.color)
                .rotationEffect(progression.direction.rotation)

            BrightText(progression.change, size: .standout4, color: .semiLightTextColor)
                .monospacedDigit()
        }
    }

    private func setRow(_ set: ExerciseCompleteProgressionSet) -> some View {
        HStack(spacing: .spacing2x) {
            BrightText(set.label, size: .body1, color: .semiLightTextColor)
                .frame(width: Constants.labelWidth, alignment: .leading)

            BrightText(set.detail, size: .body1)
                .monospacedDigit()

            Spacer(minLength: .spacing2x)

            if let failedRep = set.failedRep {
                HStack(spacing: .spacing1x) {
                    BrightText(failedRep, size: .body1, color: .semiLightTextColor, weight: .regular)
                        .monospacedDigit()

                    Image(systemName: "xmark.octagon")
                        .resizable()
                        .scaledToFit()
                        .fontWeight(.light)
                        .foregroundStyle(Color.defaultRed)
                        .frame(width: Constants.stopIconSize, height: Constants.stopIconSize)
                }
            }

            trailing(set)
        }
        .contentShape(Rectangle())
    }

    // A set either carries the effort it was logged at or the mark that it was
    // skipped — never both.
    @ViewBuilder
    private func trailing(_ set: ExerciseCompleteProgressionSet) -> some View {
        if set.isSkipped {
            Image(systemName: "forward.end")
                .resizable()
                .scaledToFit()
                .fontWeight(.light)
                .foregroundStyle(Color.defaultSkyBlue)
                .frame(width: Constants.skipIconSize, height: Constants.skipIconSize)
                .frame(width: Constants.trailingWidth, alignment: .trailing)
        } else if let rpe = set.rpe {
            BrightText("RPE \(rpe)", size: .body1, color: .defaultRed)
                .monospacedDigit()
                .padding(.horizontal, .spacing1x)
                .frame(height: Constants.tagHeight)
                .background(
                    Capsule().strokeBorder(Color.defaultRed.opacity(.veryLowOpacity), lineWidth: 1)
                )
                .frame(width: Constants.trailingWidth, alignment: .trailing)
        }
    }

    private enum Constants {
        static let labelWidth: CGFloat = 72
        static let trailingWidth: CGFloat = 56
        static let tagHeight: CGFloat = 24
        // Optically matched rather than equal: the skip glyph is solid and fills
        // its box, where the stop is a thin outline that reads smaller.
        static let skipIconSize: CGFloat = 18
        static let stopIconSize: CGFloat = 22
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: .spacing4x) {
            ForEach(ExerciseDemoComplete.strength.progressions) { progression in
                ExerciseCompleteProgressionWidget(progression: progression)
            }
        }
        .padding(.spacing3x)
    }
    .background(Color.defaultSheetBackground.ignoresSafeArea())
}
