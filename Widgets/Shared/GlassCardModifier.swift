//
//  GlassCardModifier.swift
//  Widgets
//
//  Glass variant of CardModifier — a single rounded glass surface with a hairline border.
//

import SwiftUI

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = .cardCornerRadius

    func body(content: Content) -> some View {
        content
            .modifier(GlassEffect(shape: .roundedRect, cornerRadius: cornerRadius, isClear: true, interactive: false))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(.ultraLowOpacity), lineWidth: 0.5)
            )
    }
}
