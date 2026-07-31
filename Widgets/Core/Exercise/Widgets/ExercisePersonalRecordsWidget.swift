//
//  ExercisePersonalRecordsWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import SwiftUI

struct ExercisePersonalRecordsWidget: View {
    private struct BadgeStyle {
        let imageName: String
        let icon: String
        let iconColor: Color
        let iconSize: FontSizes
    }

    private struct CardioRecord: Identifiable {
        let id = UUID()
        let badge: BadgeStyle
        let label: String
        let date: String
        let value: String
    }

    private let records = [
        CardioRecord(
            badge: BadgeStyle(
                imageName: ImageNames.exerciseRecordHexagonV5,
                icon: "hare.fill",
                iconColor: .defaultWhite,
                iconSize: .subheading
            ),
            label: "Fastest 1K",
            date: "2 Jun, 2026",
            value: "4\u{2019}22"
        ),
        CardioRecord(
            badge: BadgeStyle(
                imageName: ImageNames.exerciseRecordHexagonGoldV5,
                icon: "flag.and.flag.filled.crossed",
                iconColor: .defaultBlack,
                iconSize: .heading
            ),
            label: "Finisher",
            date: "2 Jun, 2026",
            value: "40.2 KM"
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText("Cardio records", size: .body1)
                BrightText("This week", size: .body2, color: .lightTextColor)
            }

            VStack(spacing: .spacing2x) {
                ForEach(records) { record in
                    recordRow(record)
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
    }

    private func recordRow(_ record: CardioRecord) -> some View {
        HStack(spacing: .spacing2x) {
            badge(record.badge)

            VStack(alignment: .leading, spacing: .spacing1x) {
                BrightText(record.label, size: .body1, weight: .regular)
                BrightText(record.date, size: .body2, color: .lightTextColor)
                    .monospacedDigit()
            }

            Spacer(minLength: .spacing2x)

            BrightText(record.value, size: .standout3, weight: .regular)
                .monospacedDigit()
        }
        .padding(.horizontal, .spacing2x)
        .frame(height: Constants.rowHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(cornerRadius: .cornerRadius20))
    }

    private func badge(_ style: BadgeStyle) -> some View {
        ZStack {
            Image(style.imageName)
                .resizable()
                .scaledToFit()

            Image(systemName: style.icon)
                .font(.standard(size: style.iconSize, weight: .regular))
                .foregroundStyle(style.iconColor)
                .blendMode(.overlay)
        }
        .frame(width: Constants.badgeSize, height: Constants.badgeHeight)
    }

    private class Constants {
        static let rowHeight: CGFloat = 74
        static let badgeSize: CGFloat = 50
        static let badgeHeight: CGFloat = 55
    }
}

#Preview {
    ExercisePersonalRecordsWidget()
        .padding(.spacing4x)
}
