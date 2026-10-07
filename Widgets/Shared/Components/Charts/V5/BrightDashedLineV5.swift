//
//  BrightDashedLineV5.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import Charts
import SwiftUI

// The dashed guide line drawn across graphs: 0.5pt, round caps, 3pt dashes.
struct BrightDashedLineV5: View {
    var color: Color = .lightTextColor
    var axis: Axis = .horizontal

    var body: some View {
        DashedLineShape(axis: axis)
            .stroke(color, style: .brightDashedLineV5)
            .frame(
                width: axis == .vertical ? StrokeStyle.brightDashedLineV5.lineWidth : nil,
                height: axis == .horizontal ? StrokeStyle.brightDashedLineV5.lineWidth : nil
            )
    }
}

extension StrokeStyle {
    static let brightDashedLineV5 = StrokeStyle(lineWidth: 0.5, lineCap: .round, dash: [3, 3])
}

extension ChartContent {
    // The same line for a chart mark, e.g. `RuleMark(y: .value("Average", average)).brightDashedLineV5()`.
    func brightDashedLineV5(_ color: Color = .lightTextColor) -> some ChartContent {
        foregroundStyle(color)
            .lineStyle(.brightDashedLineV5)
    }
}

private struct DashedLineShape: Shape {
    let axis: Axis

    func path(in rect: CGRect) -> Path {
        Path { path in
            switch axis {
            case .horizontal:
                path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            case .vertical:
                path.move(to: CGPoint(x: rect.midX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            }
        }
    }
}

#Preview {
    VStack(spacing: .spacing3x) {
        BrightDashedLineV5()

        BrightDashedLineV5(color: .defaultRed.opacity(.lowOpacity))

        BrightDashedLineV5(color: .defaultCyan.opacity(.lowOpacity))

        BrightDashedLineV5(axis: .vertical)
            .frame(height: .spacing12x)
    }
    .padding(.spacing3x)
    .background(Color.defaultBackground)
}
