//
//  ExerciseLogRow.swift
//  Widgets
//
//  Created by Dom Montalto on 24/8/2026.
//

import SwiftUI

extension ExerciseLoggedSession {
    // The same three the consistency heatmap uses, and red for anything that
    // came in from Apple Health rather than being run here.
    var logColor: Color {
        guard !isFromAppleHealth else { return .defaultRed }

        return switch type {
        case .cardio: .defaultSkyBlue
        case .both: .defaultGreen
        case .strength, .rest: .defaultPurple
        }
    }
}

struct ExerciseLogRow: View {
    let session: ExerciseLoggedSession
    let isLast: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: .spacing105x) {
                // The same square the consistency heatmap draws, so a log entry
                // and its cell on the grid read as the same thing.
                RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous)
                    .fill(session.logColor)
                    .frame(width: Constants.swatchSize, height: Constants.swatchSize)
                    .frame(width: Constants.iconWidth)

                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(session.name, size: .body2, color: .semiLightTextColor, weight: .regular)
                    BrightText(session.summary, size: .body3, color: .lightTextColor)
                        .monospacedDigit()
                }

                Spacer(minLength: .spacing2x)

                VStack(alignment: .trailing, spacing: .spacing05x) {
                    BrightText(session.timestamp, size: .body3, color: .lightTextColor)
                    Image(systemName: "chevron.right")
                        .font(.standard(size: .body5, weight: .regular))
                        .foregroundStyle(Color.lightTextColor)
                }
            }
            .padding(.top, .spacing105x)
            // The card's own padding closes the widget, so the last row's
            // bottom breath would double it.
            .padding(.bottom, isLast ? .spacing0x : .spacing105x)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private enum Constants {
        static let iconWidth: CGFloat = 28
        static let swatchSize: CGFloat = 16
    }
}

struct ExerciseLogDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.textColor.opacity(.ultraLowOpacity))
            .frame(height: 1)
    }
}
