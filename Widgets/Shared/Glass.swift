//
//  Glass.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct GlassEffect: ViewModifier {
    var shape: GlassShape = .capsule
    var cornerRadius: CGFloat = .cornerRadius22
    var tint: Color = .clear

    @Environment(\.colorScheme) private var colorScheme

    enum GlassShape {
        case capsule
        case circle
        case roundedRect
        case unevenRoundedRect(top: CGFloat, bottom: CGFloat)
    }

    private var unevenRect: UnevenRoundedRectangle {
        guard case let .unevenRoundedRect(top, bottom) = shape else {
            return UnevenRoundedRectangle(cornerRadii: .init(
                topLeading: cornerRadius, bottomLeading: cornerRadius,
                bottomTrailing: cornerRadius, topTrailing: cornerRadius
            ))
        }
        return UnevenRoundedRectangle(cornerRadii: .init(
            topLeading: top, bottomLeading: bottom,
            bottomTrailing: bottom, topTrailing: top
        ))
    }

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            switch shape {
            case .capsule:
                content
                    .glassEffect(Glass.regular.tint(tint).interactive(), in: .capsule)
                    .id(colorScheme)
            case .circle:
                content
                    .glassEffect(Glass.regular.tint(tint).interactive(), in: .circle)
                    .id(colorScheme)
            case .roundedRect:
                content
                    .glassEffect(Glass.regular.tint(tint).interactive(), in: .rect(cornerRadius: cornerRadius))
                    .id(colorScheme)
            case .unevenRoundedRect:
                content
                    .glassEffect(Glass.regular.tint(tint).interactive(), in: unevenRect)
                    .id(colorScheme)
            }
        } else {
            switch shape {
            case .capsule:
                content.background(.ultraThinMaterial, in: .capsule)
            case .circle:
                content.background(.ultraThinMaterial, in: .circle)
            case .roundedRect:
                content.background(.ultraThinMaterial, in: .rect(cornerRadius: cornerRadius))
            case .unevenRoundedRect:
                content.background(.ultraThinMaterial, in: unevenRect)
            }
        }
    }
}
