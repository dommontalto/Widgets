//
//  OutlinedValuePill.swift
//  Widgets
//
//  Created by Amin Zabihi on 1/1/2026.
//

import SwiftUI

struct OutlinedValuePill: View {
    let text: String
    @Binding var editingText: String
    let placeholderText: String
    let isEditable: Bool
    var keyboardType: UIKeyboardType = .decimalPad
    var onFocusChanged: ((Bool) -> Void)?
    var editableWidth: CGFloat = 92
    var editableHeight: CGFloat = 33

    var textColor: Color = .semiLightTextColor
    var strokeColor = Color.textColor.opacity(.veryLowOpacity)
    var lineWidth: CGFloat = 1
    var cornerRadius: CGFloat = .cardCornerRadius
    var horizontalPadding: CGFloat = .spacing3x
    var verticalPadding: CGFloat = .spacing1x

    @FocusState private var isFocused: Bool

    init(
        text: String,
        textColor: Color = .semiLightTextColor,
        strokeColor: Color = Color.textColor.opacity(.veryLowOpacity),
        lineWidth: CGFloat = 1,
        cornerRadius: CGFloat = .cardCornerRadius,
        horizontalPadding: CGFloat = .spacing3x,
        verticalPadding: CGFloat = .spacing1x
    ) {
        self.text = text
        _editingText = .constant(text)
        placeholderText = ""
        isEditable = false
        self.textColor = textColor
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }

    init(
        text: String,
        isEditable: Bool,
        editingText: Binding<String>,
        placeholderText: String,
        keyboardType: UIKeyboardType = .decimalPad,
        onFocusChanged: ((Bool) -> Void)? = nil,
        editableWidth: CGFloat = 92,
        editableHeight: CGFloat = 33,
        textColor: Color = .semiLightTextColor,
        strokeColor: Color = Color.textColor.opacity(.veryLowOpacity),
        lineWidth: CGFloat = 1,
        cornerRadius: CGFloat = .cardCornerRadius,
        horizontalPadding: CGFloat = .spacing3x,
        verticalPadding: CGFloat = .spacing1x
    ) {
        self.text = text
        self.isEditable = isEditable
        _editingText = editingText
        self.placeholderText = placeholderText
        self.keyboardType = keyboardType
        self.onFocusChanged = onFocusChanged
        self.editableWidth = editableWidth
        self.editableHeight = editableHeight
        self.textColor = textColor
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }

    var body: some View {
        Group {
            if isEditable {
                TextField(placeholderText, text: $editingText)
                    .font(.standard(size: .body2, weight: .regular))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .keyboardType(keyboardType)
                    .focused($isFocused)
                    .onChange(of: isFocused) { _, newValue in
                        onFocusChanged?(newValue)
                    }
                    .frame(width: editableWidth, height: editableHeight)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(strokeColor, lineWidth: lineWidth)
                    )
            } else {
                BrightText(
                    text,
                    size: .body1,
                    color: textColor
                )
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(strokeColor, lineWidth: lineWidth)
                )
            }
        }
    }
}
