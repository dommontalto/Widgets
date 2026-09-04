//
//  ExerciseLogRow.swift
//  Widgets
//
//  Created by Dom Montalto on 24/8/2026.
//

import SwiftUI

extension ExerciseDayType {
    // A both day blends its two ingredients — strength's purple falling into
    // cardio's blue, purple leading.
    static let bothGradient = LinearGradient(
        colors: [.defaultPurplePink, .defaultSkyBlueCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension ExerciseLoggedSession {
    // The same palette the consistency heatmap uses, and red for anything that
    // came in from Apple Health rather than being run here.
    var logStyle: AnyShapeStyle {
        guard !isFromAppleHealth else { return AnyShapeStyle(Color.defaultRed) }

        return switch type {
        case .cardio: AnyShapeStyle(Color.defaultSkyBlueCyan)
        case .both: AnyShapeStyle(ExerciseDayType.bothGradient)
        case .strength: AnyShapeStyle(Color.defaultPurplePink)
        case .rest: AnyShapeStyle(Color.defaultGreen)
        }
    }
}

struct ExerciseLogRow: View {
    let session: ExerciseLoggedSession
    var isFirst = false
    let isLast: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: .spacing105x) {
                // The same dot the consistency heatmap draws, so a log entry
                // and its cell on the grid read as the same thing.
                Circle()
                    .fill(session.logStyle)
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
            .padding(.top, isFirst ? .spacing0x : .spacing105x)
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
