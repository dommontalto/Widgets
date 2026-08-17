//
//  BrightPillButton.swift
//  Bright
//
//  Created by Zoe Friedman on 8/8/2023.
//  Copyright © 2023 Bryan Jordan. All rights reserved.
//

import SwiftUI

struct BrightPillButton: View {
    let title: String
    let image: String?
    let systemImage: String?
    let color: Color?
    let textColor: Color?
    let size: FontSizes?
    let buttonSize: BrightButtonSizes
    let isClear: Bool
    // Matches InlineTabPill: unselected dims the whole capsule and drops the
    // label to 60%. Defaults to true, so a plain button is full strength.
    let isSelected: Bool
    let onTapCallback: () -> Void

    init(
        _ title: String,
        image: String? = nil,
        systemImage: String? = nil,
        color: Color? = nil,
        textColor: Color? = nil,
        size: FontSizes? = nil,
        buttonSize: BrightButtonSizes = .medium,
        isClear: Bool = false,
        isSelected: Bool = true,
        onTapCallback: @escaping (() -> Void)
    ) {
        self.title = title
        self.image = image
        self.systemImage = systemImage
        self.color = color
        self.textColor = textColor
        self.size = size
        self.buttonSize = buttonSize
        self.isClear = isClear
        self.isSelected = isSelected
        self.onTapCallback = onTapCallback
    }

    private var resolvedTextColor: Color {
        if let textColor { return textColor }
        if color != nil { return .black }
        return isSelected ? .textColor : .lightTextColor
    }

    private var resolvedSize: FontSizes {
        size ?? buttonSize.defaultFontSize
    }

    var body: some View {
        Button(action: onTapCallback) {
            HStack(spacing: .spacing1x) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: Constants.imageSize, weight: .medium))
                        .foregroundStyle(resolvedTextColor)
                } else if let image {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: Constants.imageSize)
                }
                BrightText(title, size: resolvedSize, color: resolvedTextColor)
            }
            .padding(.horizontal, .spacing105x)
            .frame(height: buttonSize.rawValue)
        }
        .background((color ?? .clear).opacity(.veryHighOpacity), in: Capsule())
        .modifier(GlassEffect(shape: .capsule, isClear: isClear))
        .opacity(isSelected ? .opaque : .semiLowOpacity)
    }

    private enum Constants {
        static let imageSize: CGFloat = 16
    }
}
