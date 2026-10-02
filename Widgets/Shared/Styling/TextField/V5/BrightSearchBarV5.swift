//
//  BrightSearchBarV5.swift
//  Widgets
//
//  Created by Dom Montalto on 16/3/2026.
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

struct BrightSearchBarV5: View {
    let placeholder: String
    let height: CGFloat?
    let autoFocuses: Bool
    let onFocusChange: ((Bool) -> Void)?
    @Binding var text: String

    @FocusState private var isFocused: Bool

    init(
        _ placeholder: String,
        text: Binding<String>,
        height: CGFloat? = nil,
        autoFocuses: Bool = false,
        onFocusChange: ((Bool) -> Void)? = nil
    ) {
        self.placeholder = placeholder
        _text = text
        self.height = height
        self.autoFocuses = autoFocuses
        self.onFocusChange = onFocusChange
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
            // The list filters as you type, so the key's only job is to put
            // the keyboard away.
            .submitLabel(.return)
            .onSubmit { isFocused = false }
            .focused($isFocused)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, showsClear ? BrightButtonSizes.small.rawValue : .spacing0x)
        }
                .padding(.horizontal, .spacing3x)
        .frame(height: height ?? Constants.height)
        .modifier(BrightGlassEffectV5())
        .contentShape(Capsule())
        .onTapGesture { isFocused = true }
        .overlay(alignment: .trailing) {
            if showsClear {
                BrightRoundButton(systemImage: "xmark", size: .small) {
                    text = ""
                    isFocused = false
                }
                .padding(.trailing, .spacing105x)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.brightSnappy, value: showsClear)
        .onChange(of: isFocused) { _, isFocused in
            onFocusChange?(isFocused)
        }
        .onAppear {
            if autoFocuses { isFocused = true }
        }
    }

    private var showsClear: Bool {
        isFocused || !text.isEmpty
    }

    private enum Constants {
        static var height: CGFloat { .rowHeight }
    }
}
