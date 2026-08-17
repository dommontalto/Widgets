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
    let onPickKind: (ExerciseSetKind) -> Void

    @Environment(\.colorScheme) private var colorScheme

    // The row is a fixed-height grid of fields, so every measurement has to grow
    // with the text or the numbers clip at accessibility sizes.
    @ScaledMetric(relativeTo: .body) private var rowHeight = Constants.rowHeight
    @ScaledMetric(relativeTo: .body) private var badgeSize = Constants.badgeSize
    @ScaledMetric(relativeTo: .body) private var fieldWidth = Constants.fieldWidth
    @ScaledMetric(relativeTo: .body) private var fieldGap = Constants.fieldGap

    var body: some View {
        HStack(spacing: .spacing0x) {
            Menu {
                ForEach(ExerciseSetKind.pickable, id: \.self) { kind in
                    Button(kind.pickerLabel, systemImage: kind.pickerSymbol) {
                        onPickKind(kind)
                    }
                }
            } label: {
                // The Menu owns the tap, so the badge is label only.
                badge
                    .allowsHitTesting(false)
            }

            Spacer(minLength: .spacing2x)

            field(text: $weight)

            divider

            field(text: $reps)

            divider

            field(text: $rest)
        }
        .padding(.horizontal, .spacing2x)
        .frame(height: rowHeight)
        .background {
            if isTinted {
                RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous)
                    .fill(tint)
            }
        }
    }

    private var tint: Color {
        colorScheme == .dark
            ? .defaultSheetBackground.opacity(.veryLowOpacity)
            : .defaultMainGrey.opacity(.ultraLowOpacity)
    }

    private var badge: some View {
        Group {
            if let symbol = kind.symbol {
                Image(systemName: symbol)
                    .font(.standard(size: .body1, weight: .light))
                    .foregroundStyle(kind.color)
            } else if let label = kind.label {
                BrightText(label, size: .body1)
            }
        }
        .frame(width: badgeSize, height: badgeSize)
        .modifier(GlassEffect(shape: .circle))
    }

    private var divider: some View {
        BrightVerticalDivider(height: Constants.dividerHeight)
            .frame(width: fieldGap)
    }

    private func field(text: Binding<String>) -> some View {
        TextField("", text: text)
            .focused(isTyping)
            .font(.standard(size: .body2, weight: .regular))
            .foregroundStyle(Color.textColor)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .frame(width: fieldWidth, height: badgeSize)
            .background(Color.defaultCapsule, in: Capsule())
    }

    enum Constants {
        static let badgeSize: CGFloat = 30
        static let fieldWidth: CGFloat = 60
        static let fieldGap: CGFloat = 24
        static let dividerHeight: CGFloat = 34
        static let rowHeight: CGFloat = 49
    }
}
