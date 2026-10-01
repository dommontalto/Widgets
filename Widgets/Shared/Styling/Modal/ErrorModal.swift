//
//  ErrorModal.swift
//  Widgets
//
//  Created by Zoe Friedman on 12/9/2023.
//

import SwiftUI

struct ErrorModal: View {
    private class Constants {
        static let iconSize: CGFloat = 65
        static let modalWidth: CGFloat = 327
    }

    let errorMessage: String
    let onTapCallback: () -> Void

    init(errorMessage: String = "Something went wrong", onTapCallback: @escaping (() -> Void)) {
        self.errorMessage = errorMessage
        self.onTapCallback = onTapCallback
    }

    var body: some View {
        VStack(spacing: .spacing9x) {
            VStack(spacing: .spacing6x) {
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
        VStack(spacing: .spacing2x) {
            BrightText("Oops!", size: .subheading)
            BrightText(errorMessage, size: .subheading)
                .multilineTextAlignment(.center)
            BrightText("Please try again.", size: .subheading)
        }
    }

    var button: some View {
        // TODO: Replace with Retry
        BrightPillButton("Dismiss", color: .defaultBrightViolet, buttonSize: .large, onTapCallback: onTapCallback)
    }
}

#Preview {
    ErrorModal(errorMessage: "We could not find this barcode", onTapCallback: {})
}
