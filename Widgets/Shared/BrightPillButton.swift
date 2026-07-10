//
//  BrightPillButton.swift
//  Widgets
//
//  Ported from Bright.
//

import SwiftUI

struct BrightPillButton: View {
    let title: String
    let image: String?
    let systemImage: String?
    let color: Color?
    let size: FontSizes
    let buttonSize: BrightButtonSizes
    let onTapCallback: () -> Void

    init(
        _ title: String,
        image: String? = nil,
        systemImage: String? = nil,
        color: Color? = nil,
        size: FontSizes = .subheading1,
        buttonSize: BrightButtonSizes = .medium,
        onTapCallback: @escaping (() -> Void)
    ) {
        self.title = title
        self.image = image
        self.systemImage = systemImage
        self.color = color
        self.size = size
        self.buttonSize = buttonSize
        self.onTapCallback = onTapCallback
    }

    var body: some View {
        Button(action: onTapCallback) {
            HStack(spacing: .spacing1x) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: Constants.imageSize, weight: .medium))
                        .foregroundStyle(color == nil ? Color.textColor : Color.black)
                } else if let image {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: Constants.imageSize)
                }
                BrightText(title, size: size, color: color == nil ? .textColor : .black)
            }
            .padding(.horizontal, .spacing2x + .spacing05x)
            .frame(height: buttonSize.rawValue)
        }
        .background((color ?? .clear).opacity(.veryHighOpacity), in: Capsule())
        .modifier(GlassEffect(shape: .capsule))
    }

    private enum Constants {
        static let imageSize: CGFloat = 16
    }
}
