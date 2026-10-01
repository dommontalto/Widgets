//
//  TextFieldActionButtonViewModifier.swift
//  Widgets
//
//  Created by Ian Tran on 3/12/2025.
//

import SwiftUI

private struct TextFieldActionButtonViewModifier: ViewModifier {
    let buttonTitle: String
    let onTapAction: () -> Void
    var textColor: Color

    func body(content: Content) -> some View {
        HStack {
            content
            Spacer()
            Button(action: onTapAction) {
                Text(buttonTitle)
                    .font(.standard(size: .body1, weight: .light))
                    .foregroundStyle(textColor)
                    .padding()
            }
        }
    }
}

extension View {
    func textFieldActionButton(
        title: String,
        titleColor: Color = .textColor.opacity(0.25),
        action: @escaping () -> Void
    ) -> some View {
        modifier(
            TextFieldActionButtonViewModifier(
                buttonTitle: title,
                onTapAction: action,
                textColor: titleColor
            )
        )
    }
}
