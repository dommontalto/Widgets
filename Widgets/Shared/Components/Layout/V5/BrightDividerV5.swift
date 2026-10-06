//
//  BrightDividerV5.swift
//  Widgets
//
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

struct BrightDividerV5: View {
    let axis: Axis
    let color: Color
    let thickness: CGFloat
    let length: CGFloat
    let opacity: Double

    init(
        _ axis: Axis = .horizontal,
        color: Color = .textColor,
        thickness: CGFloat = 0.5,
        length: CGFloat = .infinity,
        opacity: Double = .ultraLowOpacity
    ) {
        self.axis = axis
        self.color = color
        self.thickness = thickness
        self.length = length
        self.opacity = opacity
    }

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(
                width: axis == .vertical ? thickness : fixedLength,
                height: axis == .horizontal ? thickness : fixedLength
            )
            .frame(
                maxWidth: axis == .horizontal && length == .infinity ? .infinity : nil,
                maxHeight: axis == .vertical && length == .infinity ? .infinity : nil
            )
            .opacity(opacity)
    }

    private var fixedLength: CGFloat? {
        length == .infinity ? nil : length
    }
}

#Preview {
    VStack(spacing: .spacing3x) {
        BrightDividerV5()
        HStack {
            Text("Left")
            BrightDividerV5(.vertical, length: 20)
            Text("Right")
        }
    }
    .padding(.spacing3x)
}
