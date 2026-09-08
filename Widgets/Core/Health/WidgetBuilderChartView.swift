//
//  WidgetBuilderChartView.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import Charts
import SwiftUI

// The heart-rate line chart inside the HR AVG widget.
struct WidgetBuilderChartView: View {
    enum ChartSize {
        case small
        case extended
        case largest
    }

    let size: ChartSize
    var heartData: HealthDashboardHeartData?

    @Environment(\.lighthouseAnimateChartReveal) private var animateReveal
    // Holds the line undrawn until the widget is loaded in.
    @Environment(\.lighthouseLoadIn) private var loadIn
    // 0 -> 1 draw progress for the left-to-right line reveal.
    @State private var drawProgress: CGFloat = 0

    private var heartDataPoints: [HeartChartDataPoint] {
        guard let heartData,
              let hrData = heartData.hrData,
              let hrTime = heartData.hrTime,
              hrData.count == hrTime.count
        else { return [] }

        let allPoints = zip(hrTime, hrData).compactMap { timeString, value -> HeartChartDataPoint? in
            guard value != 0 else { return nil }
            return HeartChartDataPoint(date: timeString.isoStringToDate(), value: Double(value))
        }

        // The smaller sizes only show the last hour of readings.
        if size == .small || size == .extended {
            guard let mostRecentDate = allPoints.map(\.date).max() else { return allPoints }
            let cutoff = mostRecentDate.addingTimeInterval(-Constants.recentWindow)
            return allPoints.filter { $0.date >= cutoff }
        }

        return allPoints
    }

    private var yMin: Double {
        if let low = heartData?.hrLow {
            return max(Double(low) - Constants.yPadding, 0)
        }
        guard let minValue = heartDataPoints.map(\.value).min() else { return 40 }
        return max(minValue - Constants.yPadding, 0)
    }

    private var yMax: Double {
        if let high = heartData?.hrHigh {
            return Double(high) + Constants.yPadding
        }
        guard let maxValue = heartDataPoints.map(\.value).max() else { return 100 }
        return maxValue + Constants.yPadding
    }

    private let gradientColors: [Color] = [
        Color.defaultRed.opacity(.semiLowOpacity),
        Color.defaultRed.opacity(.ultraLowOpacity),
        Color.clear,
    ]

    var body: some View {
        Group {
            if !heartDataPoints.isEmpty {
                switch size {
                case .small: smallChart
                case .extended: extendedChart
                case .largest: largestChart
                }
            }
        }
        .onAppear {
            guard animateReveal else { return }
            // Reflect the current load state instantly so a LazyVStack remount
            // lands fully drawn without replaying.
            drawProgress = loadIn ? 1 : 0
        }
        // The load-in moment: draw the line left-to-right, once.
        .onChange(of: loadIn) { _, now in
            guard animateReveal, now else { return }
            drawProgress = 0
            withAnimation(.easeInOut(duration: 1.1)) { drawProgress = 1 }
        }
    }

    private var lineChart: some View {
        Chart {
            ForEach(heartDataPoints) { point in
                AreaMark(
                    x: .value("Time", point.date),
                    yStart: .value("Value", point.value),
                    yEnd: .value("Min", yMin)
                )
                .foregroundStyle(
                    LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom)
                )

                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Color.defaultRed)
                .lineStyle(StrokeStyle(lineWidth: Constants.lineWidth))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: yMin ... yMax)
    }

    private var averageLine: some View {
        VStack {
            Spacer()
            DashedLineWidget(dashLength: 3, color: .defaultRed.opacity(.mediumOpacity))
            Spacer()
        }
    }

    private var yAxisLabels: some View {
        VStack(alignment: .leading) {
            BrightText("\(Int(yMax))", size: .body5, color: .semiLightTextColor)
            Spacer()
            BrightText("\(Int(yMin))", size: .body5, color: .semiLightTextColor)
        }
    }

    private var smallChart: some View {
        lineChart
            .frame(height: Constants.smallHeight)
    }

    private var extendedChart: some View {
        HStack(spacing: .spacing1x) {
            ZStack {
                averageLine
                lineChart
            }

            yAxisLabels
                .frame(width: Constants.yAxisWidth)
        }
        .frame(height: Constants.extendedHeight)
    }

    private var largestChart: some View {
        HStack(spacing: .spacing1x) {
            ZStack(alignment: .topLeading) {
                // Vertical grid lines extend down past the chart into the time labels.
                HStack(spacing: .spacing0x) {
                    ForEach(0 ..< 4, id: \.self) { _ in
                        VerticalDashedLineWidget(
                            color: .textColor.opacity(.minimalOpacity),
                            lineWidth: Constants.gridLineWidth,
                            dashPattern: [1, 1, 1, 1]
                        )
                        Spacer()
                    }
                }
                .frame(height: Constants.largestHeight + .spacing3x)

                VStack(spacing: .spacing0x) {
                    ZStack {
                        averageLine
                        lineChart
                            // Draw just the line/area left-to-right; grid lines
                            // and labels stay put.
                            .mask(alignment: .leading) {
                                GeometryReader { geo in
                                    Rectangle()
                                        .frame(width: geo.size.width * (animateReveal ? drawProgress : 1))
                                }
                            }
                    }
                    .frame(height: Constants.largestHeight)

                    HStack(spacing: .spacing0x) {
                        ForEach(["12 AM", "6 AM", "12 PM", "6 PM"], id: \.self) { time in
                            BrightText(time, size: .body5, color: .semiLightTextColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, .spacing1x)
                        }
                    }
                    .padding(.top, .spacing1x)
                }
            }

            yAxisLabels
                .frame(height: Constants.largestHeight)
                .padding(.bottom, .spacing205x)
        }
    }

    private enum Constants {
        static let smallHeight: CGFloat = 60
        static let extendedHeight: CGFloat = 80
        static let largestHeight: CGFloat = 190
        static let yAxisWidth: CGFloat = 24
        static let lineWidth: CGFloat = 1
        static let gridLineWidth: CGFloat = 0.5
        static let yPadding: Double = 10
        static let recentWindow: TimeInterval = 60 * 60
    }
}

private struct HeartChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

#Preview {
    WidgetBuilderChartView(size: .largest, heartData: LighthouseDemo.heartDashboardData)
        .padding(.spacing3x)
        .background(Color.defaultHomeCards)
}
