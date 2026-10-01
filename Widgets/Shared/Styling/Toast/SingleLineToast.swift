//
//  SingleLineToast.swift
//  Widgets
//
//  Created by Zoe Friedman on 22/9/2023.
//

import SwiftUI

struct SingleLineToast: View {
    let text: String

    private class Constants {
        static let minHeight: CGFloat = 50
    }

    var body: some View {
        HStack(spacing: .spacing2x) {
            BrightText(text, size: .body1)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, minHeight: Constants.minHeight)
    }
}

#Preview {
    SingleLineToast(text: "Split percentage has been adjusted")
}
