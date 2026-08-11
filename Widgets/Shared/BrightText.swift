//
//  BrightText.swift
//  Streamplate
//
//  Created by Anthony Uccello on 2023-06-14.
//  Copyright © 2023 Bryan Jordan. All rights reserved.
//

import SwiftUI

struct BrightText: View {
    var text: AttributedString
    var size: FontSizes
    var color: Color
    var weight: Font.Weight
    var kerning: CGFloat
    var isItalic: Bool
    var scaleTextSize: CGFloat
    var allowsTightening: Bool

    var paddingSize: CGFloat {
        // Reduce extra vertical padding around text for .standout.
        if size == .standout1 {
            -(size.rawValue * 0.23)
        } else {
            0
        }
    }

    init(
        _ text: String,
        size: FontSizes,
        color: Color = .textColor,
        weight: Font.Weight = .light,
        kerning: CGFloat = .defaultKerning,
        isItalic: Bool = false,
        scaleTextSize: CGFloat = 1
    ) {
        self.text = AttributedString(text)
        self.size = size
        self.color = color
        self.weight = weight
        self.kerning = kerning
        self.isItalic = isItalic
        self.scaleTextSize = scaleTextSize
        if scaleTextSize != 1 {
            allowsTightening = true
        } else {
            allowsTightening = false
        }
    }

    init(
        _ text: AttributedString,
        size: FontSizes,
        color: Color = .textColor,
        weight: Font.Weight = .regular,
        kerning: CGFloat = .defaultKerning,
        isItalic: Bool = false,
        scaleTextSize: CGFloat = 1
    ) {
        self.text = text
        self.size = size
        self.color = color
        self.weight = weight
        self.kerning = kerning
        self.isItalic = isItalic
        self.scaleTextSize = scaleTextSize
        if scaleTextSize != 1 {
            allowsTightening = true
        } else {
            allowsTightening = false
        }
    }

    init(
        localized key: String,
        size: FontSizes,
        color: Color = .textColor,
        weight: Font.Weight = .light,
        kerning: CGFloat = .defaultKerning,
        isItalic: Bool = false,
        scaleTextSize: CGFloat = 1
    ) {
        text = AttributedString(String(localized: String.LocalizationValue(key)))
        self.size = size
        self.color = color
        self.weight = weight
        self.kerning = kerning
        self.isItalic = isItalic
        self.scaleTextSize = scaleTextSize
        if scaleTextSize != 1 {
            allowsTightening = true
        } else {
            allowsTightening = false
        }
    }

    var body: some View {
        Text(text)
            .font(.standard(size: size, weight: weight))
            .foregroundColor(color)
            .kerning(kerning)
            .italic(isItalic)
            .minimumScaleFactor(scaleTextSize)
            .allowsTightening(allowsTightening)
            .truncationMode(.tail)
            .dynamicTypeSize(.medium)
            .padding(.vertical, paddingSize)
    }
}

#Preview {
    // No string catalog in this project, so the key would render as-is.
    BrightText("The future is bright", size: .body1)
}
