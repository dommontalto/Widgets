//
//  BrightSearchBar.swift
//  Widgets
//
//  Created by Dom Montalto on 16/3/2026.
//

import SwiftUI

struct BrightSearchBar: View {
    let placeholder: String
    @Binding var text: String

    @FocusState private var isFocused: Bool

    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        _text = text
    }

    var body: some View {
        HStack(spacing: .spacing1x) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(Color.semiLightTextColor)

            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundStyle(Color.textColor)
                .submitLabel(.search)
                .focused($isFocused)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, .spacing2x)
        .padding(.horizontal, .spacing3x)
        .modifier(GlassEffect())
        .contentShape(Capsule())
        .onTapGesture { isFocused = true }
    }
}
