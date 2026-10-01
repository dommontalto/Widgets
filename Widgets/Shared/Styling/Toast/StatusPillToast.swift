//
//  StatusPillToast.swift
//  Widgets
//
//  Created by Dom Montalto on 14/5/2026.
//

import SwiftUI

struct StatusPillToast: View {
    let text: String
    let icon: String
    let color: Color

    private enum Constants {
        static let height: CGFloat = 46
    }

    var body: some View {
        HStack(spacing: .spacing105x) {
            Image(icon)
                .foregroundStyle(color)
            BrightText(text, size: .body1, color: color)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: Constants.height)
        .padding(.leading, .spacing2x)
        .padding(.trailing, .spacing3x)
        .modifier(
            BrightCardModifierV5(
                color: color.opacity(.minimalOpacity),
                cornerRadius: .largePillCornerRadius
            )
        )
        .modifier(BrightGlassEffectV5(shape: .capsule))
    }
}
