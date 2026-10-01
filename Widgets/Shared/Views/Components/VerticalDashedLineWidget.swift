//
//  VerticalDashedLineWidget.swift
//  Widgets
//
//  Created by Gangajaliya Sandeep on 16/6/2023.
//

import SwiftUI

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

private struct VerticalDashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width / 2, y: 0))
        path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
        return path
    }
}

#Preview {
    VerticalDashedLineWidget()
}
