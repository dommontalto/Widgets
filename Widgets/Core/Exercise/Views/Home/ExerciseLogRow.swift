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
        colors: [.defaultPink, .defaultSkyBlueCyan],
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
        case .strength: AnyShapeStyle(Color.defaultPink)
        case .rest: AnyShapeStyle(Color.defaultGreen)
        }
    }
}

struct ExerciseLogDot: View {
    let fill: AnyShapeStyle

    init(_ fill: some ShapeStyle) {
        self.fill = AnyShapeStyle(fill)
    }

    var body: some View {
        Circle()
            .fill(fill.opacity(.minimalOpacity))
            .overlay {
                Circle()
                    .strokeBorder(fill.opacity(.lowOpacity), lineWidth: Constants.lineWidth)
            }
            .frame(width: Constants.size, height: Constants.size)
    }

    private enum Constants {
        static let size: CGFloat = .spacing2x
        static let lineWidth: CGFloat = 1.5
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
                ExerciseLogDot(session.logStyle)

                BrightText(session.name, size: .body1, color: .semiLightTextColor, weight: .regular)
                    .lineLimit(1)

                Spacer(minLength: .spacing2x)

                BrightText(session.timestamp, size: .body1, color: .lightTextColor)
                    .monospacedDigit()
            }
            .padding(.top, isFirst ? .spacing0x : .spacing2x)
            .padding(.bottom, isLast ? .spacing0x : .spacing2x)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ExerciseLogDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.textColor.opacity(.ultraLowOpacity))
            .frame(height: 1)
    }
}
