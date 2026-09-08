//
//  DashedLineWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

struct DashedLineWidget: View {
    var dashLength: CGFloat = 10
    var color: Color = .defaultGrey
    var lineWidth: CGFloat = 0.5
    var dashPattern: [CGFloat]?

    var body: some View {
        LinePath()
            .stroke(style: StrokeStyle(lineWidth: lineWidth, dash: dashPattern ?? [dashLength]))
            .frame(height: lineWidth)
            .foregroundStyle(color)
    }
}

struct LinePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

#Preview {
    DashedLineWidget()
}
