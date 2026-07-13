//
//  BrightGraph.swift
//  Widgets
//
//  Created by Dom Montalto on 13/7/2026.
//

import SwiftUI
import Charts

struct BrightGraphPoint: Identifiable {
    var id: Double { hour }
    let hour: Double
    let value: Double
}

/// Day-scale metric graph: 0–100% y-axis on the trailing edge, 6-hourly x-axis
/// labels, dashed gridlines. Renders its axes even with no data (empty state).
struct BrightGraph: View {
    var points: [BrightGraphPoint] = []
    var lineColor: Color = .defaultSkyBlue

    private static let hourLabels: [Double: String] = [0: "12AM", 6: "6AM", 12: "12PM", 18: "6PM"]

    var body: some View {
        Chart {
            ForEach(points) { point in
                LineMark(x: .value("Hour", point.hour), y: .value("Value", point.value))
                    .foregroundStyle(lineColor.opacity(.mediumOpacity))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .interpolationMethod(.catmullRom)
            }

            if points.isEmpty {
                // Invisible mark so Charts still lays out the axes.
                PointMark(x: .value("Hour", 0), y: .value("Value", 0))
                    .opacity(0)
            }
        }
        .chartXScale(domain: 0...24)
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: [0, 6, 12, 18]) { value in
                AxisValueLabel(anchor: .topLeading) {
                    if let hour = value.as(Double.self), let label = Self.hourLabels[hour] {
                        Text(label)
                            .font(.standard(size: .body4, weight: .regular))
                            .foregroundStyle(Color.lightTextColor)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: [50]) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    .foregroundStyle(Color.textColor.opacity(.veryLowOpacity))
            }
            AxisMarks(position: .trailing, values: [0, 20, 40, 60, 80, 100]) { value in
                AxisValueLabel {
                    if let pct = value.as(Double.self) {
                        Text(pct == 0 ? "0%" : "\(Int(pct))")
                            .font(.standard(size: .body5, weight: .regular))
                            .foregroundStyle(Color.semiLightTextColor)
                    }
                }
            }
        }
    }
}

#Preview {
    BrightGraph()
        .frame(height: 250)
        .padding(.spacing3x)
}
