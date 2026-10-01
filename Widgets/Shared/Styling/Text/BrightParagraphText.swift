//
//  BrightParagraphText.swift
//  Widgets
//
//  Created by Zoe Friedman on 8/8/2023.
//

import SwiftUI

struct BrightParagraphText: View {
    let text: String
    let color: Color
    let size: FontSizes
    let lineSpacing: LineSpacing
    let fontWeight: Font.Weight

    init(
        _ text: String,
        size: FontSizes = .body2,
        color: Color = .lightTextColor,
        lineSpacing: LineSpacing = .paragraph,
        weight: Font.Weight = .regular
    ) {
        self.text = text
        self.color = color
        self.size = size
        self.lineSpacing = lineSpacing
        fontWeight = weight
    }

    var body: some View {
        Text(text)
            .font(.standard(size: size, weight: fontWeight))
            .kerning(FontKerning.paragraph.rawValue)
            .lineSpacing(lineSpacing.rawValue)
            .foregroundColor(color)
            .dynamicTypeSize(.medium)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    BrightParagraphText("The Future Is Bright")
}
