//
//  BrightFullWidthButton.swift
//  Widgets
//
//  Ported from Bright.
//

import SwiftUI

struct BrightFullWidthButton: View {
    let title: String
    let size: FontSizes
    let color: Color?
    let horizontalPadding: CGFloat
    let onTapCallback: () -> Void

    class Constants {
        static let height: CGFloat = 46
    }

    init(
        _ title: String,
        size: FontSizes = .subheading2,
        color: Color? = .defaultGreen,
        horizontalPadding: CGFloat = .spacing3x, // + the standard 18pt container margin = 36pt (spacing6x) total

        onTapCallback: @escaping (() -> Void)
    ) {
        self.title = title
        self.size = size
        self.color = color
        self.horizontalPadding = horizontalPadding
        self.onTapCallback = onTapCallback
    }

    var body: some View {
        Button(action: onTapCallback) {
            BrightText(
                title,
                size: size,
                color: color == nil ? .textColor : .black,
                weight: .regular
            )
            .frame(maxWidth: .infinity)
            .frame(height: Constants.height)
            .background((color ?? .clear).opacity(.veryHighOpacity), in: Capsule())
            .modifier(GlassEffect(shape: .capsule))
        }
        .padding(.horizontal, horizontalPadding)
    }
}

#Preview {
    BrightFullWidthButton("Button") {}
}
