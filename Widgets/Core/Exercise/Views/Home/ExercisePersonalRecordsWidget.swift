//
//  ExercisePersonalRecordsWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import SwiftUI

struct ExercisePersonalRecordsWidget: View {
    let records: [ExerciseCompleteRecord]

    // The sheet's cards sit on the sheet background; on Home they take the
    // screen's own card colour.
    var cardColor: Color = .defaultSheetModalCards

    // Set to let a record open the exercise it was set on.
    var onSelectExercise: ((String) -> Void)?

    var body: some View {
        VStack(spacing: .spacing0x) {
            ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                if index != 0 {
                    BrightDivider()
                }

                row(record)
            }
        }
        .padding(.horizontal, .spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: cardColor, cornerRadius: .cornerRadius24))
    }

    @ViewBuilder
    private func row(_ record: ExerciseCompleteRecord) -> some View {
        if let onSelectExercise, let exercise = record.exercise {
            Button { onSelectExercise(exercise) } label: { rowContent(record) }
                .buttonStyle(.plain)
        } else {
            rowContent(record)
        }
    }

    private func rowContent(_ record: ExerciseCompleteRecord) -> some View {
        HStack(spacing: .spacing2x) {
            badge(record)

            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(record.title, size: .body1, color: .semiLightTextColor)

                if !record.detail.isEmpty {
                    BrightText(record.detail, size: .body1, color: .lightTextColor)
                }
            }

            Spacer(minLength: .spacing2x)

            BrightText(record.value, size: .standout4, weight: .regular)
                .monospacedDigit()
        }
        .padding(.vertical, .spacing2x)
        .contentShape(Rectangle())
    }

    // The glyph rides the badge in overlay so it picks up the hexagon's own
    // shading rather than sitting flat on top of it.
    private func badge(_ record: ExerciseCompleteRecord) -> some View {
        ZStack {
            Image(record.badge)
                .resizable()
                .scaledToFit()

            switch record.glyph {
            case let .symbol(name):
                Image(systemName: name)
                    .font(.standard(size: .subheading2, weight: .regular))
                    .foregroundStyle(Color.defaultWhite)
                    .blendMode(.overlay)
            case let .captioned(caption, symbol):
                VStack(spacing: .spacing0x) {
                    BrightText(caption, size: .body1, color: .defaultWhite, weight: .regular)
                    Image(systemName: symbol)
                        .font(.standard(size: .body6, weight: .regular))
                        .foregroundStyle(Color.defaultWhite)
                }
                .blendMode(.overlay)
            }
        }
        .frame(width: Constants.badgeSize, height: Constants.badgeSize)
    }

    private enum Constants {
        static let badgeSize: CGFloat = 36
    }
}

#Preview {
    VStack(spacing: .spacing4x) {
        ExerciseWidgetSection(icon: .symbol("trophy.fill"), title: "Personal Records") {
            ExercisePersonalRecordsWidget(records: ExerciseDemoComplete.strength.records)
        }
        ExerciseWidgetSection(icon: .symbol("trophy.fill"), title: "Personal Records") {
            ExercisePersonalRecordsWidget(records: ExerciseDemoComplete.cardio.records)
        }
    }
    .padding(.spacing3x)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.defaultSheetBackground.ignoresSafeArea())
}
