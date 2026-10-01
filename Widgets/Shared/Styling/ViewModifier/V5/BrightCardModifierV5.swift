//
//  BrightCardModifierV5.swift
//  Widgets
//
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

struct BrightCardModifierV5: ViewModifier {
    let color: Color
    let cornerRadius: CGFloat
    let clipContent: Bool
    let isGlass: Bool
    let isCapsule: Bool

    @Environment(\.colorScheme) private var colorScheme

    init(
        color: Color = .defaultCards,
        cornerRadius: CGFloat = .cardCornerRadius,
        clipContent: Bool = true,
        isGlass: Bool = false,
        isCapsule: Bool = false
    ) {
        self.color = color
        self.cornerRadius = cornerRadius
        self.clipContent = clipContent
        self.isGlass = isGlass
        self.isCapsule = isCapsule
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if isCapsule {
            card(content, shape: Capsule(style: .continuous))
        } else {
            card(content, shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    @ViewBuilder
    private func card(_ content: Content, shape: some InsettableShape) -> some View {
        if isGlass {
            content
                .modifier(BrightGlassEffectV5(shape: .roundedRect, cornerRadius: cornerRadius, isClear: true, interactive: false))
                .overlay(shape.strokeBorder(Color.white.opacity(.ultraLowOpacity), lineWidth: 0.5))
        } else if clipContent {
            content
                .background(color)
                .clipShape(shape)
                .overlay(border(shape))
        } else {
            content
                .background(shape.fill(color))
                .overlay(border(shape))
        }
    }

    private func border(_ shape: some InsettableShape) -> some View {
        shape.strokeBorder(
            colorScheme == .dark
                ? Color.white.opacity(.ultraLowOpacity)
                : Color.defaultMainGrey.opacity(.semiLowOpacity),
            lineWidth: 0.5
        )
    }
}

#Preview {
    VStack(spacing: .spacing3x) {
        Text("Card")
            .padding(.spacing3x)
            .modifier(BrightCardModifierV5())
        Text("Glass card")
            .padding(.spacing3x)
            .modifier(BrightCardModifierV5(isGlass: true))
    }
    .padding(.spacing3x)
}
