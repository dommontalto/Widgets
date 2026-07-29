//
//  ExerciseSetRow.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

struct ExerciseSetRow: View {
    let kind: ExerciseSetKind
    let isTinted: Bool
    @Binding var weight: String
    @Binding var reps: String
    @Binding var rest: String
    var isTyping: FocusState<Bool>.Binding

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: .spacing0x) {
            badge

            Spacer(minLength: .spacing2x)

            field(text: $weight)

            divider

            field(text: $reps)

            divider

            field(text: $rest)
        }
        .padding(.horizontal, .spacing2x)
        .frame(height: Constants.rowHeight)
        .background {
            if isTinted {
                RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous)
                    .fill(tint)
            }
        }
    }

    private var tint: Color {
        colorScheme == .dark
            ? .sheetBackground.opacity(.veryLowOpacity)
            : .defaultMainGrey.opacity(.ultraLowOpacity)
    }

    private var badge: some View {
        ZStack {
            Circle()
                .fill(Color.defaultMainGrey.opacity(.minimalOpacity))

            if let symbol = kind.symbol {
                Image(systemName: symbol)
                    .font(.standardSFPro(size: .body1, weight: .light))
                    .foregroundStyle(kind.color)
            } else if let label = kind.label {
                BrightText(label, size: .body1)
            }
        }
        .frame(width: Constants.badgeSize, height: Constants.badgeSize)
    }

    private var divider: some View {
        BrightVerticalDivider(height: Constants.dividerHeight)
            .frame(width: Constants.fieldGap)
    }

    private func field(text: Binding<String>) -> some View {
        TextField("", text: text)
            .focused(isTyping)
            .font(.standard(size: .body2, weight: .regular))
            .foregroundStyle(Color.textColor)
            .multilineTextAlignment(.center)
            .frame(width: Constants.fieldWidth, height: Constants.badgeSize)
            .modifier(GlassEffect(shape: .capsule))
    }

    enum Constants {
        static let badgeSize: CGFloat = 30
        static let fieldWidth: CGFloat = 60
        static let fieldGap: CGFloat = 24
        static let dividerHeight: CGFloat = 34
        static let rowHeight: CGFloat = 49
    }
}
