//
//  GenomePercentileGraphWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI
import Charts

// MARK: - Widget

struct GenomePercentileGraphWidget: View {
    private let percentile = 72

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing4x) {
            headerSection
            chartSection
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText("Genetic risk percentile", size: .body2, color: Color.lightTextColor, weight: .regular)

            VStack(alignment: .leading, spacing: .spacing1x) {
                HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                    BrightText("\(percentile)", size: .huge2, weight: .light)
                    BrightText("nd percentile", size: .body2, color: Color.textColor, weight: .regular)
                }

                BrightText("Higher than \(percentile)% of your matched reference cohort.", size: .body4, color: Color.lightTextColor, weight: .regular)
            }
        }
    }

    // MARK: Chart + Legend

    private var chartSection: some View {
        VStack(alignment: .trailing, spacing: .spacing2x) {
            legendRow
            riskChart
        }
    }

    private var legendRow: some View {
        HStack(spacing: .spacing3x) {
            legendDot(color: Color.defaultCyan, label: "Reference")
            legendDot(color: Color.defaultWarningRed, label: "Higher-risk")
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: .spacing05x) {
            Circle()
                .fill(color.opacity(.minimalOpacity))
                .overlay(Circle().stroke(color, lineWidth: 1))
                .frame(width: 7, height: 7)
            BrightText(label, size: .body5, color: Color.lightTextColor, weight: .regular)
        }
    }

    private var riskChart: some View {
        Chart {
            ForEach(GenomeRiskPoint.data) { p in
                AreaMark(
                    x: .value("Age", p.age),
                    yStart: .value("% Risk", p.reference),
                    yEnd: .value("% Risk", p.higherRisk)
                )
                .foregroundStyle(LinearGradient(
                    colors: [Color.defaultWarningRed.opacity(.semiLowOpacity), .clear],
                    startPoint: .top, endPoint: .bottom
                ))
                .interpolationMethod(.catmullRom)
            }
            ForEach(GenomeRiskPoint.data) { p in
                LineMark(x: .value("Age", p.age), y: .value("% Risk", p.higherRisk))
                    .foregroundStyle(by: .value("Series", "high"))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .interpolationMethod(.catmullRom)
            }
            ForEach(GenomeRiskPoint.data) { p in
                LineMark(x: .value("Age", p.age), y: .value("% Risk", p.userRisk))
                    .foregroundStyle(by: .value("Series", "user"))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    .interpolationMethod(.catmullRom)
            }
            ForEach(GenomeRiskPoint.data) { p in
                LineMark(x: .value("Age", p.age), y: .value("% Risk", p.reference))
                    .foregroundStyle(by: .value("Series", "ref"))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .interpolationMethod(.catmullRom)
            }

            ForEach([20.0, 40.0, 60.0], id: \.self) { age in
                RuleMark(x: .value("Age", age))
                    .foregroundStyle(Color.textColor.opacity(.ultraLowOpacity))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                    .annotation(position: .bottom, alignment: .center, spacing: 4) {
                        Text("\(Int(age))")
                            .font(.standard(size: .body5, weight: .regular))
                            .foregroundStyle(Color.lightTextColor)
                    }
            }
        }
        .chartForegroundStyleScale([
            "ref":  Color.defaultCyan,
            "user": Color.lightTextColor,
            "high": Color.defaultWarningRed
        ])
        .chartLegend(.hidden)
        .chartOverlay { proxy in
            GeometryReader { geo in
                if let plotFrame = proxy.plotFrame {
                    let frame = geo[plotFrame]
                    let pts: [CGPoint] = GenomeRiskPoint.data.compactMap { p in
                        guard let x = proxy.position(forX: p.age),
                              let y = proxy.position(forY: p.reference) else { return nil }
                        return CGPoint(x: frame.minX + x, y: frame.minY + y)
                    }
                    if pts.count > 1 {
                        Path { path in
                            path.move(to: CGPoint(x: pts[0].x, y: frame.maxY))
                            path.addLine(to: pts[0])
                            for pt in pts.dropFirst() { path.addLine(to: pt) }
                            path.addLine(to: CGPoint(x: pts.last!.x, y: frame.maxY))
                            path.closeSubpath()
                        }
                        .fill(LinearGradient(
                            colors: [Color.defaultCyan.opacity(.semiLowOpacity), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                    }
                }
            }
        }
        .chartXScale(domain: 0...80)
        .chartYScale(domain: 0...35)
        .chartPlotStyle { plot in
            plot.background(Color.clear)
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0.0, 10.0, 20.0, 30.0]) { value in
                AxisGridLine()
                    .foregroundStyle(Color.textColor.opacity(.ultraLowOpacity))
                AxisTick().foregroundStyle(Color.clear)
                AxisValueLabel {
                    if let pct = value.as(Double.self) {
                        Text(pct == 0 ? "0% risk" : "\(Int(pct))%")
                            .font(.standard(size: .body5, weight: .regular))
                            .foregroundStyle(Color.lightTextColor)
                    }
                }
            }
        }
        .frame(height: 220)
        .padding(.bottom, .spacing3x)
    }
}

#Preview {
    GenomePercentileGraphWidget()
}
