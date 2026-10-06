//
//  BrightTextArea.swift
//  Widgets
//
//  Created by Zoe Friedman on 5/8/2023.
//

import SwiftUI

struct BrightTextArea: View {
    let title: String
    let placeholder: String
    var size: FontSizes
    var color: Color
    var background: Color
    var minHeight: CGFloat
    var didChange: ((String) -> Void)?
    var didFinishEditing: ((String) -> Void)?
    var keyboardType: UIKeyboardType

    private var editingText: Binding<String>

    private enum Constants {
        static let cornerRadius: CGFloat = 10
        static let paddingVertical: CGFloat = 12
        static let paddingHorizontal: CGFloat = 16
    }

    init(
        title: String = "",
        placeholder: String = "",
        editingText: Binding<String>,
        keyboardType: UIKeyboardType = .alphabet,
        size: FontSizes,
        color: Color = .textColor,
        background: Color = .textFields,
        minHeight: CGFloat,
        didChange: ((String) -> Void)? = nil,
        didFinishEditing: ((String) -> Void)? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self.size = size
        self.color = color
        self.minHeight = minHeight
        self.background = background
        self.didChange = didChange
        self.didFinishEditing = didFinishEditing
        self.editingText = editingText
        self.keyboardType = keyboardType
    }

    var body: some View {
        VStack(spacing: .spacing3x) {
            if !title.isEmpty {
                BrightText(title, size: .subheading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            ZStack(alignment: .topLeading) {
                if !placeholder.isEmpty,
                   editingText.wrappedValue.isEmpty {
                    BrightText(
                        placeholder,
                        size: size,
                        color: color.opacity(.lowOpacity)
                    )
                    .padding(.top, .spacing1x)
                    .padding(.leading, .spacing1x)
                }
                TextEditor(text: editingText)
                    .font(.standard(size: size, weight: .regular))
                    .scrollContentBackground(.hidden)
                    .foregroundColor(color)
                    .keyboardType(keyboardType)
                    .background(background)
                    .cornerRadius(Constants.cornerRadius)
                    .frame(height: minHeight)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.leading)
                    .onChange(of: editingText.wrappedValue) { _, newValue in
                        didChange?(newValue)
                    }
                    .onSubmit {
                        didFinishEditing?(editingText.wrappedValue)
                    }
            }
        }
    }
}

#Preview {
    VStack {
        BrightTextArea(editingText: Binding.constant(""), size: .body1, minHeight: 100)
    }
}
