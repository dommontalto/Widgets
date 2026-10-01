//
//  TopErrorToast.swift
//  Widgets
//
//  Created by Gangajaliya Sandeep on 24/4/2024.
//

import SwiftUI

struct TopErrorToast: View {
    let text: String

    private class Constants {
        static let minHeight: CGFloat = 50
        static let cornerRadius: CGFloat = 16
    }

    var body: some View {
        HStack(spacing: .spacing2x) {
            BrightText(
                text,
                size: .body1,
                color: .textColor
            )
            .lineSpacing(.spacing1x)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.spacing3x)
        .frame(
            maxWidth: .infinity,
            minHeight: Constants.minHeight
        )
        .background(Color(hex: "240E09"))
        .addBorder(
            Color.defaultRed,
            cornerRadius: Constants.cornerRadius
        )
    }
}

#Preview {
    TopErrorToast(text: "Error toast")
}
