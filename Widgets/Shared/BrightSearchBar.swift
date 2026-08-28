//
//  BrightSearchBar.swift
//  Widgets
//
//  Created by Dom Montalto on 16/3/2026.
//

import SwiftUI

struct BrightSearchBar: View {
    let placeholder: String
    let height: CGFloat?
    let autoFocuses: Bool
    @Binding var text: String

    @FocusState private var isFocused: Bool

    init(
        _ placeholder: String,
        text: Binding<String>,
        height: CGFloat? = nil,
        autoFocuses: Bool = false
    ) {
        self.placeholder = placeholder
        _text = text
        self.height = height
        self.autoFocuses = autoFocuses
    }

    var body: some View {
        HStack(spacing: .spacing1x) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(Color.semiLightTextColor)

            TextField(
                placeholder,
                text: $text,
                prompt: Text(placeholder).foregroundStyle(Color.semiLightTextColor)
            )
            .font(.system(size: 16))
            .foregroundStyle(Color.textColor)
            .submitLabel(.search)
            .focused($isFocused)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, height == nil ? .spacing2x : .spacing0x)
        .padding(.horizontal, .spacing3x)
        .frame(height: height)
        .modifier(GlassEffect())
        .contentShape(Capsule())
        .onTapGesture { isFocused = true }
        .onAppear {
            if autoFocuses { isFocused = true }
        }
    }
}
