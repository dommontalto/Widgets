//
//  WarningModal.swift
//  Widgets
//
//  Created by Zoe Friedman on 17/10/2023.
//

import SwiftUI

struct WarningModal: View {
    private class Constants {
        static let iconSize: CGFloat = 65
        static let modalWidth: CGFloat = 327
    }

    let message: String
    let buttonTitle: String
    let onTapCallback: () -> Void

    init(
        message: String,
        buttonTitle: String,
        onTapCallback: @escaping (() -> Void)
    ) {
        self.message = message
        self.buttonTitle = buttonTitle
        self.onTapCallback = onTapCallback
    }

    var body: some View {
        VStack(spacing: .spacing12x) {
            VStack(spacing: .spacing9x) {
                icon
                text
            }
            button
        }
        .padding(.spacing8x)
        .frame(width: Constants.modalWidth)
        .modifier(BrightCardModifierV5())
    }

    var icon: some View {
        Image(ImageNames.warningIconV4)
            .frame(width: Constants.iconSize, height: Constants.iconSize)
    }

    var text: some View {
        BrightText(message, size: .subheading)
            .multilineTextAlignment(.center)
    }

    var button: some View {
        BrightPillButton(buttonTitle, color: .defaultRed, buttonSize: .large, onTapCallback: onTapCallback)
    }
}

#Preview {
    WarningModal(
        message: "Are you sure?",
        buttonTitle: "Yes",
        onTapCallback: {}
    )
}
