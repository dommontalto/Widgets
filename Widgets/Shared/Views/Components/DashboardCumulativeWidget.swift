//
//  DashboardCumulativeWidget.swift
//  Widgets
//
//  Created by Amin Zabihi on 8/1/2026.
//

import SwiftUI

// MARK: - Data Models

struct DashboardCumulativeWidgetModel: Equatable {
    let title: String
    let valueText: String
    let unitText: String
    let subtitleText: String?
}

struct DashboardCumulativeChartPoint: Identifiable, Equatable {
    let id: Int
    let segments: [DashboardCumulativeChartSegment] // bottom -> top
}

struct DashboardCumulativeChartSegment: Equatable {
    let value: Double
    let color: Color
}

struct DashboardCumulativeChartModel: Equatable {
    let maxValue: Double // e.g. 60
    let yTickLabels: [String] // e.g. ["0m","30m","60m"]
    let xTickLabels: [String] // e.g. ["6 AM","12 PM"]
    // Optional explicit guide positions (0...1) for vertical dashed grid lines.
    // If nil, derived from xTickLabels count.
    let xGuideFractions: [Double]?
    let points: [DashboardCumulativeChartPoint]
}

// MARK: - ViewStates (3 variants)

@Observable
class DashboardCumulativeWidgetBaseViewState {
    init(model: DashboardCumulativeWidgetModel, chart: DashboardCumulativeChartModel) {
        self.model = model
        self.chart = chart
    }

    var model: DashboardCumulativeWidgetModel
    var chart: DashboardCumulativeChartModel

    var titleText: String {
        model.title
    }
    var valueText: String {
        model.valueText
    }
    var unitText: String {
        model.unitText
    }
    var subtitleText: String? {
        model.subtitleText
    }
}

@Observable
class DashboardCumulativeWidgetCompactViewState: DashboardCumulativeWidgetBaseViewState {
    override init(model: DashboardCumulativeWidgetModel, chart: DashboardCumulativeChartModel) {
        super.init(model: model, chart: chart)
    }
}

@Observable
class DashboardCumulativeWidgetStandardViewState: DashboardCumulativeWidgetBaseViewState {
    override init(model: DashboardCumulativeWidgetModel, chart: DashboardCumulativeChartModel) {
        super.init(model: model, chart: chart)
    }
}

@Observable
class DashboardCumulativeWidgetDetailedViewState: DashboardCumulativeWidgetBaseViewState {
    init(model: DashboardCumulativeWidgetModel, chart: DashboardCumulativeChartModel, readings: [String]) {
        self.readings = readings
        super.init(model: model, chart: chart)
    }

    var readings: [String]
}

// MARK: - Widgets (3 variants)

// Compact: value/remaining on the left, mini chart on the right
struct DashboardCumulativeWidgetCompact: View {
    let viewState: DashboardCumulativeWidgetCompactViewState

    var body: some View {
        DashboardCumulativeBaseCard(width: 354, height: 168) {
            HStack(alignment: .top, spacing: .spacing3x) {
                leftInfo
                DashboardCumulativeChart(
                    model: viewState.chart,
                    style: .compact
                )
                .padding(.top, .spacing1x)
                .padding(.bottom, .spacing1x)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .padding(.horizontal, .spacing3x)
            .padding(.vertical, .spacing2x)
        }
    }

    private var leftInfo: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            BrightText(viewState.titleText, size: .body3, color: .semiLightTextColor)
                .padding(.top, .spacing1x)

            Spacer(minLength: .spacing0x)

            HStack(alignment: .lastTextBaseline, spacing: .spacing05x) {
                BrightText(
                    viewState.valueText,
                    size: .huge3,
                    color: .lightTextColor,
                    weight: .regular
                )
                .monospacedDigit()
                .lineLimit(1)

                BrightText(
                    viewState.unitText,
                    size: .body3,
                    color: .semiLightTextColor
                )
                .lineLimit(1)
            }

            if let subtitle = viewState.subtitleText {
                BrightText(subtitle, size: .body4, color: .semiLightTextColor)
                    .lineLimit(1)
                    .padding(.bottom, .spacing1x)
            }
        }
        .frame(width: 140, alignment: .leading)
    }
}

// Standard: title + value above a full-width chart
struct DashboardCumulativeWidgetStandard: View {
    let viewState: DashboardCumulativeWidgetStandardViewState

    var body: some View {
        DashboardCumulativeBaseCard(width: 354, height: 168) {
            VStack(alignment: .leading, spacing: .spacing0x) {
                BrightText(viewState.titleText, size: .body3, color: .semiLightTextColor)
                    .padding(.top, .spacing3x)
                    .padding(.bottom, .spacing1x)

                BrightText(
                    viewState.valueText,
                    size: .standout3,
                    color: .lightTextColor,
                    weight: .regular
                )
                .monospacedDigit()
                .lineLimit(1)
                .padding(.bottom, .spacing2x)

                DashboardCumulativeChart(
                    model: viewState.chart,
                    style: .standard
                )
                .padding(.bottom, .spacing2x)
            }
            .padding(.horizontal, .spacing3x)
        }
    }
}

// Detailed: chart + divider + readings grid
struct DashboardCumulativeWidgetDetailed: View {
    let viewState: DashboardCumulativeWidgetDetailedViewState

    var body: some View {
        DashboardCumulativeBaseCard(width: 354, height: 303) {
            VStack(alignment: .leading, spacing: .spacing0x) {
                VStack(alignment: .leading, spacing: .spacing0x) {
                    BrightText(viewState.titleText, size: .body3, color: .semiLightTextColor)
                        .padding(.top, .spacing3x)
                        .padding(.bottom, .spacing1x)

                    BrightText(
                        viewState.valueText,
                        size: .standout3,
                        color: .lightTextColor,
                        weight: .regular
                    )
                    .monospacedDigit()
                    .lineLimit(1)
                    .padding(.bottom, .spacing2x)

                    DashboardCumulativeChart(
                        model: viewState.chart,
                        style: .standard
                    )
                    .padding(.bottom, .spacing2x)
                }
                .padding(.horizontal, .spacing3x)

                BrightDividerV5()
                    .padding(.vertical, .spacing1x)

                DashboardCumulativeReadingsGrid(readings: viewState.readings)
                    .padding(.horizontal, .spacing3x)
                    .padding(.top, .spacing2x)
                    .padding(.bottom, .spacing3x)
            }
        }
    }
}

// MARK: - Shared UI

private struct DashboardCumulativeBaseCard<Content: View>: View {
    let content: Content
    let width: CGFloat?
    let height: CGFloat?

    init(
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.width = width
        self.height = height
        self.content = content()
    }

    var body: some View {
        content
            .frame(width: width, height: height, alignment: .topLeading)
            .modifier(BrightCardModifierV5(cornerRadius: .cardCornerRadius))
            .addBorder(Color.textColor.opacity(.veryLowOpacity), cornerRadius: .cardCornerRadius)
    }
}

private enum DashboardCumulativeChartStyle {
    case compact
    case standard
}

private struct DashboardCumulativeChart: View {
    let model: DashboardCumulativeChartModel
    let style: DashboardCumulativeChartStyle

    private enum Constants {
        static let barWidth: CGFloat = 6
        static let barSpacing: CGFloat = 5
        static let rightLabelWidth: CGFloat = 26
        static let bottomLabelHeight: CGFloat = 18
    }

    var body: some View {
        if style == .compact {
            chartCore
        } else {
            chartCore
                .frame(height: 72)
        }
    }

    private var chartCore: some View {
        GeometryReader { geo in
            let chartHeight = geo.size.height - Constants.bottomLabelHeight
            let chartWidth = geo.size.width - Constants.rightLabelWidth

            HStack(spacing: .spacing0x) {
                ZStack {
                    grid(width: chartWidth, height: chartHeight)
                    bars(width: chartWidth, height: chartHeight)
                }
                .frame(width: chartWidth, height: chartHeight, alignment: .bottomLeading)

                yAxis
                    .frame(width: Constants.rightLabelWidth, height: chartHeight, alignment: .trailing)
            }

            xAxis
                .frame(width: chartWidth, height: Constants.bottomLabelHeight, alignment: .leading)
                .offset(x: 0, y: chartHeight)
        }
    }

    private func grid(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            ForEach(horizontalGridFractions, id: \.self) { t in
                Rectangle()
                    .fill(Color.textColor.opacity(.veryLowOpacity))
                    .frame(height: 1)
                    .offset(y: height - (height * t))
            }

            ForEach(verticalGuideFractions, id: \.self) { t in
                Path { path in
                    let x = width * t
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                .stroke(
                    Color.textColor.opacity(.veryLowOpacity),
                    style: StrokeStyle(lineWidth: 1)
                )
            }
        }
    }

    private var horizontalGridFractions: [Double] {
        switch style {
        case .compact:
            [0.5, 1.0]
        case .standard:
            [0.5, 1.0]
        }
    }

    private var verticalGuideFractions: [Double] {
        if let explicit = model.xGuideFractions, !explicit.isEmpty {
            return explicit
        }
        // Default: draw guides for all tick labels except the last
        let count = model.xTickLabels.count
        guard count > 1 else { return [] }
        let denom = Double(count - 1)
        return (0 ..< (count - 1)).map { Double($0) / denom }
    }

    private func bars(width: CGFloat, height: CGFloat) -> some View {
        let count = max(model.points.count, 1)
        let totalBarsWidth = CGFloat(count) * Constants.barWidth + CGFloat(count - 1) * Constants.barSpacing

        return HStack(alignment: .bottom, spacing: Constants.barSpacing) {
            ForEach(model.points) { point in
                DashboardCumulativeStackedBar(
                    maxValue: model.maxValue,
                    segments: point.segments
                )
                .frame(width: Constants.barWidth, height: height)
            }
        }
        .frame(width: totalBarsWidth, height: height, alignment: .bottomLeading)
        .frame(width: width, height: height, alignment: .bottomLeading)
    }

    private var yAxis: some View {
        VStack(alignment: .trailing, spacing: .spacing0x) {
            ForEach(model.yTickLabels.indices, id: \.self) { idx in
                BrightText(
                    model.yTickLabels[model.yTickLabels.count - 1 - idx],
                    size: .body4,
                    color: .semiLightTextColor
                )
                if idx != model.yTickLabels.indices.last {
                    Spacer()
                }
            }
        }
    }

    private var xAxis: some View {
        HStack {
            ForEach(model.xTickLabels, id: \.self) { label in
                BrightText(label, size: .body4, color: .semiLightTextColor)
                if label != model.xTickLabels.last {
                    Spacer()
                }
            }
        }
    }
}

private struct DashboardCumulativeStackedBar: View {
    let maxValue: Double
    let segments: [DashboardCumulativeChartSegment]

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: .spacing0x) {
                Spacer(minLength: 0)
                ForEach(Array(segments.reversed().enumerated()), id: \.offset) { _, seg in
                    Rectangle()
                        .fill(seg.color)
                        .frame(height: geo.size.height * CGFloat(max(0, min(seg.value / max(maxValue, 1), 1))))
                }
            }
            .mask(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
            )
        }
    }
}

private struct DashboardCumulativeReadingsGrid: View {
    let readings: [String]

    private let columns: [GridItem] = [
        .init(.flexible(), spacing: .spacing3x),
        .init(.flexible(), spacing: .spacing3x),
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: .spacing2x) {
            ForEach(readings.indices, id: \.self) { idx in
                HStack(spacing: .spacing2x) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.textColor.opacity(.veryLowOpacity))
                        .frame(width: 20, height: 20)
                    BrightText(
                        readings[idx],
                        size: .body4,
                        color: .semiLightTextColor
                    )
                    .lineLimit(1)
                }
            }
        }
    }
}
