//
//  BrightTextFieldV5.swift
//  Widgets
//
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

enum BrightTextFieldV5Style {
    case regular
    case small
    case inline
}

struct BrightTextFieldV5: View {
    let placeholder: String
    @Binding var editingText: String
    let style: BrightTextFieldV5Style
    let systemImage: String?
    let keyboardType: UIKeyboardType
    let size: FontSizes
    let color: Color
    let backgroundColor: Color
    let textAlignment: TextAlignment
    let textInputAutocapitalization: TextInputAutocapitalization
    let disableAutocorrection: Bool
    let characterLimit: Int?
    let width: CGFloat?
    let isEnabled: Bool
    let isSecure: Bool
    let onTextChanged: (() -> Void)?
    let didFinishEditing: ((String) -> Void)?

    @FocusState private var focus: Field?
    @State private var isRevealed = false

    init(
        _ placeholder: String,
        editingText: Binding<String>,
        style: BrightTextFieldV5Style = .regular,
        systemImage: String? = nil,
        keyboardType: UIKeyboardType = .default,
        size: FontSizes = .body1,
        color: Color = .textColor,
        backgroundColor: Color = .textFields,
        textAlignment: TextAlignment? = nil,
        textInputAutocapitalization: TextInputAutocapitalization = .sentences,
        disableAutocorrection: Bool = false,
        characterLimit: Int? = nil,
        width: CGFloat? = nil,
        isEnabled: Bool = true,
        isSecure: Bool = false,
        onTextChanged: (() -> Void)? = nil,
        didFinishEditing: ((String) -> Void)? = nil
    ) {
        self.placeholder = placeholder
        _editingText = editingText
        self.style = style
        self.systemImage = systemImage
        self.keyboardType = keyboardType
        self.size = size
        self.color = color
        self.backgroundColor = backgroundColor
        self.textAlignment = textAlignment ?? Self.defaultAlignment(for: style)
        self.textInputAutocapitalization = textInputAutocapitalization
        self.disableAutocorrection = disableAutocorrection
        self.characterLimit = characterLimit
        self.width = width
        self.isEnabled = isEnabled
        self.isSecure = isSecure
        self.onTextChanged = onTextChanged
        self.didFinishEditing = didFinishEditing
    }

    var body: some View {
        switch style {
        case .regular:
            field
                .padding(.horizontal, .spacing3x)
                .frame(maxWidth: width ?? .infinity)
                .frame(height: Constants.regularHeight)
                .background(backgroundColor, in: Capsule())
                .contentShape(Capsule())
                .onTapGesture { focus = activeField }
        case .small:
            field
                .padding(.horizontal, .spacing2x)
                .frame(width: width ?? Constants.smallWidth, height: Constants.smallHeight)
                .background(backgroundColor, in: Capsule())
                .contentShape(Capsule())
                .onTapGesture { focus = activeField }
        case .inline:
            field
                .frame(maxWidth: width ?? .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { focus = activeField }
        }
    }

    private var field: some View {
        HStack(spacing: .spacing2x) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.standard(size: .heading, weight: .light))
                    .foregroundStyle(Color.semiLightTextColor)
            }

            input
            .font(.standard(size: size, weight: .regular))
            .foregroundStyle(color)
            .multilineTextAlignment(textAlignment)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(textInputAutocapitalization)
            .autocorrectionDisabled(disableAutocorrection)
            .dynamicTypeSize(.medium)
            .textContentType(isSecure ? .password : nil)
            .disabled(!isEnabled)
            .onSubmit { didFinishEditing?(editingText) }
            .onChange(of: editingText) { _, newValue in
                if let characterLimit, newValue.count > characterLimit {
                    editingText = String(newValue.prefix(characterLimit))
                }
                onTextChanged?()
            }

            if isSecure {
                Button {
                    isRevealed.toggle()
                    if focus != nil { focus = activeField }
                } label: {
                    Image(systemName: isRevealed ? "eye" : "eye.slash")
                        .font(.standard(size: .subheading2, weight: .light))
                        .foregroundStyle(Color.semiLightTextColor)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .brightHapticV5(.light, trigger: isRevealed)
            }
        }
    }

    @ViewBuilder
    private var input: some View {
        let prompt = Text(placeholder).foregroundStyle(Color.lightTextColor)
        if isSecure {
            ZStack {
                SecureField(placeholder, text: $editingText, prompt: prompt)
                    .focused($focus, equals: .secure)
                    .opacity(isRevealed ? 0 : .opaque)
                    .allowsHitTesting(!isRevealed)
                    .accessibilityHidden(isRevealed)
                TextField(placeholder, text: $editingText, prompt: prompt)
                    .focused($focus, equals: .plain)
                    .opacity(isRevealed ? .opaque : 0)
                    .allowsHitTesting(isRevealed)
                    .accessibilityHidden(!isRevealed)
            }
        } else {
            TextField(placeholder, text: $editingText, prompt: prompt)
                .focused($focus, equals: .plain)
        }
    }

    private var activeField: Field {
        isSecure && !isRevealed ? .secure : .plain
    }

    private static func defaultAlignment(for style: BrightTextFieldV5Style) -> TextAlignment {
        switch style {
        case .regular: .leading
        case .small: .center
        case .inline: .trailing
        }
    }

    private enum Field {
        case secure
        case plain
    }

    private enum Constants {
        static var regularHeight: CGFloat { 50 }
        static var smallHeight: CGFloat { 36 }
        static var smallWidth: CGFloat { 90 }
    }
}

#Preview {
    @Previewable @State var name = ""
    @Previewable @State var amount = "250"
    @Previewable @State var email = ""

    VStack(spacing: .spacing3x) {
        BrightTextFieldV5("Name", editingText: $name)
        BrightTextFieldV5("Email", editingText: $email, systemImage: "envelope", keyboardType: .emailAddress)
        BrightTextFieldV5("0", editingText: $amount, style: .small, keyboardType: .decimalPad)
    }
    .padding(.spacing3x)
}
