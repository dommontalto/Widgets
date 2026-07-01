//
//  CardModifier.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct CardModifier: ViewModifier {
    let color: Color
    let cornerRadius: CGFloat
    let clipContent: Bool

    @Environment(\.colorScheme) private var colorScheme

    init(
        color: Color = .cards,
        cornerRadius: CGFloat = .cardCornerRadius,
        clipContent: Bool = true
    ) {
        self.color = color
        self.cornerRadius = cornerRadius
        self.clipContent = clipContent
    }

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let border = shape.strokeBorder(
            colorScheme == .dark
                ? Color.white.opacity(.ultraLowOpacity)
                : Color.defaultMainGrey.opacity(.semiLowOpacity),
            lineWidth: 0.5
        )
        if clipContent {
            content
                .background(color)
                .clipShape(shape)
                .overlay(border)
        } else {
            content
                .background(shape.fill(color))
                .overlay(border)
        }
    }
}

#Preview {
    Text("Hello")
        .modifier(CardModifier())
}
