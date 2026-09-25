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
    @State private var reservesClear = false
    @State private var showsClearButton = false

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
        HStack(spacing: .spacing2x) {
            field

            if reservesClear {
                ZStack {
                    if showsClearButton {
                        BrightRoundButton(systemImage: "xmark", size: .large) {
                            text = ""
                            isFocused = false
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: BrightButtonSizes.large.rawValue, height: BrightButtonSizes.large.rawValue)
            }
        }
        .onChange(of: showsClear) { _, showsClear in
            if showsClear {
                withAnimation(.smooth) {
                    reservesClear = true
                } completion: {
                    guard self.showsClear else { return }
                    withAnimation(.smooth) { showsClearButton = true }
                }
            } else {
                withAnimation(.smooth) {
                    showsClearButton = false
                    reservesClear = false
                }
            }
        }
        .onAppear {
            reservesClear = showsClear
            showsClearButton = showsClear
            if autoFocuses { isFocused = true }
        }
    }

    private var showsClear: Bool {
        isFocused || !text.isEmpty
    }

    private var field: some View {
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
            .submitLabel(.done)
            .onSubmit { isFocused = false }
            .focused($isFocused)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, height == nil ? .spacing2x : .spacing0x)
        .padding(.horizontal, .spacing3x)
        .frame(height: height)
        .modifier(GlassEffect())
        .contentShape(Capsule())
        .onTapGesture { isFocused = true }
    }
}
