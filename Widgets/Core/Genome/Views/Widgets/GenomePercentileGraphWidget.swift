//
//  GenomePercentileGraphWidget.swift
//  Widgets
//

import SwiftUI
import Charts

struct GenomePercentileGraphWidget: View {
    let data: GenomeRiskPercentile

    private struct PlotPoint: Identifiable {
        let age: Double
        let reference: Double
        let higherRisk: Double
        let userRisk: Double
        var id: Double { age }
    }

    private var points: [PlotPoint] {
        data.curve.map {
            PlotPoint(
                age: Double($0.age),
                reference: $0.reference * 100,
                higherRisk: $0.higherRisk * 100,
                userRisk: $0.userRisk * 100
            )
        }
    }

    private var ordinalSuffix: String {
        String(data.value.ordinalSuffix().dropFirst(String(data.value).count))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing4x) {
            headerSection
            chartSection
        }
        .padding(.spacing3x)
        .modifier(BrightCardModifierV5())
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText("Genetic risk percentile", size: .body2, color: Color.lightTextColor, weight: .regular)

            VStack(alignment: .leading, spacing: .spacing1x) {
                HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                    BrightText("\(data.value)", size: .huge2)
                    BrightText("\(ordinalSuffix) percentile", size: .body2, color: Color.textColor, weight: .regular)
                }

                BrightText("Higher than \(data.value)% of your matched reference cohort.", size: .body4, color: Color.lightTextColor, weight: .regular)

                if let description = data.displayDescription {
                    BrightText(description, size: .body4, color: Color.lightTextColor, weight: .regular)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(.lineSpacingMedium)
                        .padding(.top, .spacing1x)
                }
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
            legendDot(color: Color.defaultRed, label: "Higher-risk")
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
            ForEach(points) { p in
                AreaMark(
                    x: .value("Age", p.age),
                    yStart: .value("% Risk", p.reference),
                    yEnd: .value("% Risk", p.higherRisk)
                )
                .foregroundStyle(LinearGradient(
                    colors: [Color.defaultRed.opacity(.semiLowOpacity), .clear],
                    startPoint: .top, endPoint: .bottom
                ))
                .interpolationMethod(.catmullRom)
            }
            ForEach(points) { p in
                LineMark(x: .value("Age", p.age), y: .value("% Risk", p.higherRisk))
                    .foregroundStyle(by: .value("Series", "high"))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .interpolationMethod(.catmullRom)
            }
            ForEach(points) { p in
                LineMark(x: .value("Age", p.age), y: .value("% Risk", p.userRisk))
                    .foregroundStyle(by: .value("Series", "user"))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    .interpolationMethod(.catmullRom)
            }
            ForEach(points) { p in
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
            "high": Color.defaultRed
        ])
        .chartLegend(.hidden)
        .chartOverlay { proxy in
            GeometryReader { geo in
                if let plotFrame = proxy.plotFrame {
                    let frame = geo[plotFrame]
                    let pts: [CGPoint] = points.compactMap { p in
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
        .chartXScale(domain: xDomain)
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

    private var xDomain: ClosedRange<Double> {
        let ages = points.map(\.age)
        guard let min = ages.min(), let max = ages.max(), min < max else { return 0...80 }
        return min...max
    }
}

#Preview {
    GenomePercentileGraphWidget(data: GenomeRiskPercentile(
        value: 64,
        description: "Your genetics suggest you may lean towards being a morning person.",
        curve: [
            GenomeRiskCurvePoint(age: 20, reference: 0, higherRisk: 0, userRisk: 0),
            GenomeRiskCurvePoint(age: 30, reference: 0, higherRisk: 0, userRisk: 0),
            GenomeRiskCurvePoint(age: 40, reference: 0.0195, higherRisk: 0.0389, userRisk: 0.0319),
            GenomeRiskCurvePoint(age: 50, reference: 0.0521, higherRisk: 0.1041, userRisk: 0.0854),
            GenomeRiskCurvePoint(age: 60, reference: 0.0954, higherRisk: 0.1908, userRisk: 0.1565),
            GenomeRiskCurvePoint(age: 70, reference: 0.15, higherRisk: 0.3, userRisk: 0.246),
        ]
    ))
}
