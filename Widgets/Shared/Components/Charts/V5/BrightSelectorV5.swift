//
//  BrightSelectorV5.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import Charts
import SwiftUI

// The marker a chart puts on its latest or held reading: a hairline down the plot
// through a white dot, ringed in the card's colour so it cuts out of the line behind it.
struct BrightSelectorV5: ChartContent {
    let date: Date
    let value: Double

    var body: some ChartContent {
        RuleMark(x: .value("Selected", date))
            .foregroundStyle(Color.textColor)
            .lineStyle(StrokeStyle(lineWidth: Constants.hairline))

        PointMark(x: .value("Selected", date), y: .value("Value", value))
            .symbol {
                Circle()
                    .fill(Color.textColor)
                    .frame(width: Constants.dotDiameter, height: Constants.dotDiameter)
                    .frame(width: Constants.ringDiameter, height: Constants.ringDiameter)
                    .background(Circle().fill(Color.defaultHomeCards))
            }
    }

    private enum Constants {
        static let hairline: CGFloat = 0.5
        static let dotDiameter: CGFloat = 8
        static let ringDiameter: CGFloat = 14
    }
}

#Preview {
    let now = Date.now
    let values: [Double] = [72, 78, 75, 81, 77, 84]

    Chart {
        ForEach(Array(values.enumerated()), id: \.offset) { index, value in
            LineMark(x: .value("Time", now.addingTimeInterval(Double(index) * 600)), y: .value("Value", value))
                .foregroundStyle(Color.defaultRed)
        }

        BrightSelectorV5(date: now.addingTimeInterval(3_000), value: 84)
    }
    .chartXAxis(.hidden)
    .chartYAxis(.hidden)
    .frame(height: 120)
    .padding(.spacing3x)
    .background(Color.defaultHomeCards)
}
