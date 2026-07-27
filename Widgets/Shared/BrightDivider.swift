//
//  BrightDivider.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import SwiftUI

struct BrightDivider: View {
    let color: Color
    let opacity: Double
    let dividerHeight: CGFloat

    init(
        color: Color = .textColor,
        dividerHeight: CGFloat = Constants.dividerHeight,
        opacity: Double = .ultraLowOpacity
    ) {
        self.color = color
        self.dividerHeight = dividerHeight
        self.opacity = opacity
    }

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(maxWidth: .infinity)
            .frame(height: dividerHeight)
            .opacity(opacity)
    }

    enum Constants {
        static let dividerHeight: CGFloat = 0.5
    }
}

struct BrightVerticalDivider: View {
    let color: Color
    let opacity: Double
    let width: CGFloat
    let height: CGFloat

    init(
        color: Color = .textColor,
        width: CGFloat = Constants.dividerWidth,
        height: CGFloat = .infinity,
        opacity: Double = .ultraLowOpacity
    ) {
        self.color = color
        self.width = width
        self.height = height
        self.opacity = opacity
    }

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: width)
            .frame(maxHeight: height == .infinity ? .infinity : nil, alignment: .center)
            .frame(height: height == .infinity ? nil : height)
            .opacity(opacity)
    }

    enum Constants {
        static let dividerWidth: CGFloat = 0.5
    }
}

struct VerticalDashedLineWidget: View {
    var color: Color = .textColor.opacity(.veryLowOpacity)
    var lineWidth: CGFloat = 0.5
    var dashPattern: [CGFloat] = [3]

    var body: some View {
        VerticalDashedLine()
            .stroke(style: StrokeStyle(lineWidth: lineWidth, dash: dashPattern))
            .foregroundColor(color)
            .frame(width: lineWidth)
    }
}

struct VerticalDashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width / 2, y: 0))
        path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
        return path
    }
}

#Preview {
    VStack(spacing: .spacing3x) {
        BrightDivider()
        BrightVerticalDivider(height: 40)
        VerticalDashedLineWidget()
            .frame(height: 40)
    }
    .padding(.spacing3x)
}
