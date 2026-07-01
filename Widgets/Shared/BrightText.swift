//
//  BrightText.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
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
        self.allowsTightening = scaleTextSize != 1
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
        self.allowsTightening = scaleTextSize != 1
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
    BrightText("The future is bright", size: .body1)
}
