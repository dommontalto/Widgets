//
//  ExerciseSetHistoryList.swift
//  Widgets
//
//  Created by Dom Montalto on 4/8/2026.
//

import SwiftUI

nonisolated struct ExerciseSetLine: Identifiable {
    let id = UUID()
    /// Warm-up and drop sets render their own glyph in place of a set number.
    let kind: ExerciseSetKind
    let reps: String
    let weight: String
    var prLabel: String?
}

nonisolated struct ExerciseSetGroup: Identifiable {
    let id = UUID()
    /// A session date in the exercise library, an exercise name after a workout.
    let title: String
    let lines: [ExerciseSetLine]
}

struct ExerciseSetHistoryList: View {
    let groups: [ExerciseSetGroup]
    var onTitleTap: ((ExerciseSetGroup) -> Void)?

    var body: some View {
        VStack(spacing: .spacing3x) {
            ForEach(groups) { group in
                ExerciseSetHistoryCard(
                    group: group,
                    repsTemplate: repsTemplate,
                    weightTemplate: weightTemplate,
                    onTitleTap: onTitleTap.map { tap in { tap(group) } }
                )
            }
        }
    }

    /// Longest values across every group, so the columns line up between cards
    /// rather than per card.
    private var repsTemplate: String {
        groups.flatMap(\.lines).map(\.reps).max(by: { $0.count < $1.count }) ?? ""
    }

    private var weightTemplate: String {
        groups.flatMap(\.lines).map(\.weight).max(by: { $0.count < $1.count }) ?? ""
    }
}

struct ExerciseSetHistoryCard: View {
    let group: ExerciseSetGroup
    let repsTemplate: String
    let weightTemplate: String
    var onTitleTap: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            title
                .padding(.vertical, .spacing2x)

            ForEach(group.lines) { line in
                row(line)

                if line.id != group.lines.last?.id {
                    BrightDivider()
                }
            }
        }
        .padding(.horizontal, .spacing3x)
        .padding(.bottom, .spacing1x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius18))
    }

    @ViewBuilder private var title: some View {
        if let onTitleTap {
            Button(action: onTitleTap) {
                titleText
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            titleText
        }
    }

    private var titleText: some View {
        BrightText(group.title, size: .body2, color: .lightTextColor)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ line: ExerciseSetLine) -> some View {
        HStack(spacing: .spacing2x) {
            if let symbol = line.kind.symbol {
                Image(systemName: symbol)
                    .font(.system(size: Constants.iconSize, weight: .light))
                    .foregroundStyle(line.kind.color)
                    .frame(width: Constants.labelWidth, alignment: .leading)
            } else {
                BrightText(line.kind.label ?? "", size: .subheading)
                    .monospacedDigit()
                    .frame(width: Constants.labelWidth, alignment: .leading)
            }

            Spacer(minLength: .spacing2x)

            if let prLabel = line.prLabel {
                BrightText(prLabel, size: .body2, color: .lightTextColor)
                    .lineLimit(1)

                prBadge
                    // Draws at full size but reports the text's height, so a PR
                    // row stays level with the rows around it.
                    .frame(height: Constants.prBadgeInlineHeight)
            }

            column(line.reps, template: repsTemplate)

            Rectangle()
                .fill(Color.textColor.opacity(.minimalOpacity))
                .frame(width: 1, height: Constants.dividerHeight)

            column(line.weight, template: weightTemplate)
        }
        .padding(.vertical, .spacing2x)
    }

    private func column(_ value: String, template: String) -> some View {
        ZStack(alignment: .trailing) {
            BrightText(template, size: .body2, weight: .regular)
                .monospacedDigit()
                .hidden()

            BrightText(value, size: .body2, color: .semiLightTextColor, weight: .regular)
                .monospacedDigit()
        }
        .lineLimit(1)
    }

    private var prBadge: some View {
        ZStack {
            Image(ImageNames.exerciseRecordHexagonGoldV5)
                .resizable()
                .scaledToFit()

            Image(systemName: "trophy.fill")
                .font(.system(size: Constants.prBadgeIconSize, weight: .regular))
                .foregroundStyle(Color.defaultBlack)
                .blendMode(.overlay)
        }
        .frame(width: Constants.prBadgeWidth, height: Constants.prBadgeHeight)
    }

    private enum Constants {
        static let iconSize: CGFloat = 18
        static let labelWidth: CGFloat = 24
        static let dividerHeight: CGFloat = 16
        static let prBadgeWidth: CGFloat = 30
        static let prBadgeHeight: CGFloat = 33
        static let prBadgeInlineHeight: CGFloat = 20
        static let prBadgeIconSize: CGFloat = 13
    }
}

#Preview {
    ScrollView {
        ExerciseSetHistoryList(groups: ExerciseDemoData.detailHistory)
            .padding(.spacing3x)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.defaultSheetBackground.ignoresSafeArea())
}
