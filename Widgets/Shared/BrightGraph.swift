//
//  BrightGraph.swift
//  Widgets
//
//  Created by Dom Montalto on 13/7/2026.
//

import SwiftUI
import Charts

struct BrightGraphPoint: Identifiable {
    var id: Double { x }
    let x: Double
    let value: Double
}

struct BrightGraph: View {
    var points: [BrightGraphPoint] = []
    var lineColor: Color = .defaultSkyBlue
    var xDomain: ClosedRange<Double> = 0...6
    var xAxisLabels: [Double: String] = [0: "Mon", 1: "Tue", 2: "Wed", 3: "Thu", 4: "Fri", 5: "Sat", 6: "Sun"]
    var showsPointMarkers = false

    var body: some View {
        Chart {
            ForEach(points) { point in
                LineMark(x: .value("X", point.x), y: .value("Value", point.value))
                    .foregroundStyle(lineColor.opacity(.mediumOpacity))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .interpolationMethod(.catmullRom)
            }

            if points.isEmpty {
                // Invisible mark so Charts still lays out the axes.
                PointMark(x: .value("X", xDomain.lowerBound), y: .value("Value", 0))
                    .opacity(0)
            }
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: xAxisLabels.keys.sorted()) { value in
                AxisValueLabel(anchor: .topLeading) {
                    if let x = value.as(Double.self), let label = xAxisLabels[x] {
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
        .chartOverlay { proxy in
            GeometryReader { geo in
                if showsPointMarkers, let plot = proxy.plotFrame {
                    let frame = geo[plot]
                    ForEach(points) { point in
                        if let x = proxy.position(forX: point.x),
                           let y = proxy.position(forY: point.value) {
                            ZStack {
                                Circle().fill(Color.bG)
                                Circle().stroke(lineColor, lineWidth: 2.5)
                            }
                            .frame(width: 7, height: 7)
                            .position(x: frame.minX + x, y: frame.minY + y)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let series = VaultDemoData.graphSeries(for: "W")
    BrightGraph(
        points: series.points,
        xDomain: series.xDomain,
        xAxisLabels: series.xLabels,
        showsPointMarkers: true
    )
    .frame(height: 250)
    .padding(.spacing3x)
}
