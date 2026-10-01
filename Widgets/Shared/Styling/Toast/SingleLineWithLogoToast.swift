//
//  SingleLineWithLogoToast.swift
//  Widgets
//
//  Created by Zoe Friedman on 21/9/2023.
//

import SwiftUI

struct SingleLineWithLogoToast: View {
    let text: String

    private class Constants {
        static let minHeight: CGFloat = 50
        static let cornerRadius: CGFloat = 16
        static let imageSize: CGFloat = 32
    }

    var body: some View {
        HStack(spacing: .spacing3x) {
            Image(ImageNames.brightLogoPastelGreenV4)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.imageSize, height: Constants.imageSize)
            BrightText(text, size: .body1, color: .textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.spacing3x)
        .background(
            RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
                .fill(Color.defaultDarkGreen)
        ).frame(maxWidth: .infinity, minHeight: Constants.minHeight)
    }
}

#Preview {
    SingleLineWithLogoToast(text: "Macros can be adjusted in ‘profile’")
}
