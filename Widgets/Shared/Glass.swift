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
    // When true, uses the more transparent `.clear` glass (no frosted fill).
    var isClear: Bool = false
    // When true, the glass reacts to touch (liquid-glass interactivity).
    var interactive: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    @available(iOS 26.0, *)
    private var glassStyle: Glass {
        let base = (isClear ? Glass.clear : Glass.regular).tint(tint)
        return interactive ? base.interactive() : base
    }

    enum GlassShape {
        case capsule
        case circle
        case roundedRect
        case unevenRoundedRect(top: CGFloat, bottom: CGFloat)
        case cornerRadii(RectangleCornerRadii)
    }

    private var unevenRect: UnevenRoundedRectangle {
        switch shape {
        case let .unevenRoundedRect(top, bottom):
            UnevenRoundedRectangle(cornerRadii: .init(
                topLeading: top, bottomLeading: bottom,
                bottomTrailing: bottom, topTrailing: top
            ))
        case let .cornerRadii(radii):
            UnevenRoundedRectangle(cornerRadii: radii)
        default:
            UnevenRoundedRectangle(cornerRadii: .init(
                topLeading: cornerRadius, bottomLeading: cornerRadius,
                bottomTrailing: cornerRadius, topTrailing: cornerRadius
            ))
        }
    }

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // The glass sits on its own layer, re-identified when the scheme
            // flips so it repaints, while the content keeps its identity — a
            // text field inside would otherwise lose focus on the switch.
            content.background {
                glassLayer
                    .id(colorScheme)
            }
        } else if isClear {
            content
        } else {
            switch shape {
            case .capsule:
                content.background(.ultraThinMaterial, in: .capsule)
            case .circle:
                content.background(.ultraThinMaterial, in: .circle)
            case .roundedRect:
                content.background(.ultraThinMaterial, in: .rect(cornerRadius: cornerRadius))
            case .unevenRoundedRect, .cornerRadii:
                content.background(.ultraThinMaterial, in: unevenRect)
            }
        }
    }

    @available(iOS 26.0, *)
    @ViewBuilder private var glassLayer: some View {
        switch shape {
        case .capsule:
            Color.clear.glassEffect(glassStyle, in: .capsule)
        case .circle:
            Color.clear.glassEffect(glassStyle, in: .circle)
        case .roundedRect:
            Color.clear.glassEffect(glassStyle, in: .rect(cornerRadius: cornerRadius))
        case .unevenRoundedRect, .cornerRadii:
            Color.clear.glassEffect(glassStyle, in: unevenRect)
        }
    }
}
