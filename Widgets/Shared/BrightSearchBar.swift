//
//  BrightSearchBar.swift
//  Widgets
//
//  Created by Dom Montalto on 16/3/2026.
//

import SwiftUI

struct BrightSearchBar: View {
    let placeholder: String
    let color: Color?
    let textColor: Color?
    let height: CGFloat?
    @Binding var text: String

    @FocusState private var isFocused: Bool

    init(
        _ placeholder: String,
        text: Binding<String>,
        color: Color? = nil,
        textColor: Color? = nil,
        height: CGFloat? = nil
    ) {
        self.placeholder = placeholder
        _text = text
        self.color = color
        self.textColor = textColor
        self.height = height
    }

    private var resolvedTextColor: Color {
        textColor ?? .textColor
    }

    private var dimmedTextColor: Color {
        textColor?.opacity(.lowOpacity) ?? .semiLightTextColor
    }

    var body: some View {
        HStack(spacing: .spacing1x) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(dimmedTextColor)

            TextField(
                placeholder,
                text: $text,
                prompt: Text(placeholder).foregroundStyle(dimmedTextColor)
            )
            .font(.system(size: 16))
            .foregroundStyle(resolvedTextColor)
            .submitLabel(.search)
            .focused($isFocused)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, height == nil ? .spacing2x : .spacing0x)
        .padding(.horizontal, .spacing3x)
        .frame(height: height)
        .background(color ?? .clear, in: Capsule())
        .modifier(GlassEffect())
        .contentShape(Capsule())
        .onTapGesture { isFocused = true }
    }
}
