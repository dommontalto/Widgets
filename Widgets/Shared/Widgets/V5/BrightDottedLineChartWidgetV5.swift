//
//  BrightDottedLineChartWidgetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import Charts
import SwiftUI

// Occasional readings, such as weigh-ins, joined by a line with a dot on each and the
// day under it. Medium is the chart; large adds how much it's changed and a note.
struct BrightDottedLineChartWidgetV5: View {
    struct Point: Identifiable, Hashable {
        let date: Date
        let value: Double

        var id: Date { date }
    }

    // A short headline beside the title, e.g. "↓ 0.36kg Weekly AVG".
    struct Trend: Hashable {
        let systemImage: String
        let text: String
    }

    // How far it's moved over a span, e.g. "7d" and "-0.36".
    struct Change: Identifiable, Hashable {
        let span: String
        let value: String

        var id: String { span }
    }

    let appearance: BrightWidgetAppearanceV5
    let subtitle: String
    let points: [Point]
    var trend: Trend?
    // Draws a straight best-fit line through the readings, in the trend's colour.
    var showsTrendLine = false
    var isGoalMet = false
    var changes: [Change] = []
    var note: String?
    let size: BrightWidgetSizeV5
    var allowsSelection = true

    @State private var selectedDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            HStack(alignment: .top, spacing: .spacing1x) {
                header

                Spacer(minLength: .spacing0x)

                if let trend {
                    HStack(spacing: .spacing025x) {
                        Image(systemName: trend.systemImage)

                        BrightText(trend.text, size: .body5, color: .defaultCyan)
                    }
                    .font(.standard(size: .body5, weight: .light))
                    .foregroundStyle(Color.defaultCyan)
                    .lineLimit(1)
                    .padding(.top, .spacing05x)

                    Spacer(minLength: .spacing0x)
                }

                reading
            }

            plotArea
                .frame(maxHeight: .infinity)

            if size == .large {
                if !changes.isEmpty {
                    BrightDividerV5()
                        .padding(.horizontal, -.spacing205x)

                    VStack(alignment: .leading, spacing: .spacing1x) {
                        sectionLabel(systemImage: "clock")

                        HStack(alignment: .top, spacing: .spacing0x) {
                            ForEach(changes) { change in
                                changeColumn(change)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }

                if let note {
                    BrightDividerV5()

                    VStack(alignment: .leading, spacing: .spacing05x) {
                        sectionLabel(systemImage: "arrow.up.and.down.and.sparkles", title: "Affects")

                        BrightText(note, size: .body5, color: .lightTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(.spacing205x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(BrightCardModifierV5(color: .defaultHomeCards))
        .onChange(of: allowsSelection) { _, allows in
            if !allows {
                selectedDate = nil
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(appearance.title), \(appearance.format(shownPoint?.value ?? 0)) \(appearance.unit ?? "")")
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing05x) {
                Image(systemName: appearance.systemImage)
                    .font(.standard(size: .subheading, weight: .light))
                    .foregroundStyle(appearance.iconStyle)

                BrightText(appearance.title, size: .body1, weight: .regular)
            }
            .lineLimit(1)

            BrightText(subtitle, size: .body2, color: .lightTextColor)
                .lineLimit(1)
        }
    }

    // The held reading, or the latest.
    private var reading: some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
            if isGoalMet {
                Image(ImageNames.circleCheckmarkV5)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.checkmarkSize, height: Constants.checkmarkSize)
                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] - Constants.checkmarkBaselineLift }
            }

            BrightText(appearance.format(shownPoint?.value ?? 0), size: size == .large ? .standout1 : .standout3, weight: .regular)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.brightEaseInOut, value: shownPoint)

            if let unit = appearance.unit {
                BrightText(unit, size: .body1, color: .lightTextColor, weight: .regular)
            }
        }
        .lineLimit(1)
    }

    // MARK: - Plot

    private var plotArea: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing1x) {
                VStack(alignment: .leading, spacing: .spacing0x) {
                    axisLabel(domain.upperBound)

                    Spacer(minLength: .spacing0x)

                    axisLabel(domain.lowerBound)
                }
                .frame(width: Constants.axisLabelWidth, alignment: .leading)

                chart
            }

            dayLabels
                .padding(.leading, Constants.axisLabelWidth + .spacing1x)
        }
    }

    private var chart: some View {
        Chart {
            ForEach(points) { point in
                AreaMark(
                    x: .value("Day", point.date),
                    yStart: .value("Floor", domain.lowerBound),
                    yEnd: .value(appearance.unit ?? "", point.value),
                    series: .value("Series", "Readings")
                )
                .foregroundStyle(
                    LinearGradient(colors: [appearance.tint.opacity(.semiLowOpacity), .clear], startPoint: .top, endPoint: .bottom)
                )

                LineMark(
                    x: .value("Day", point.date),
                    y: .value(appearance.unit ?? "", point.value),
                    series: .value("Series", "Readings")
                )
                .foregroundStyle(appearance.tint)
                .lineStyle(StrokeStyle(lineWidth: Constants.lineWidth))

                PointMark(x: .value("Day", point.date), y: .value(appearance.unit ?? "", point.value))
                    .symbol {
                        Circle()
                            .fill(appearance.tint)
                            .frame(width: Constants.dotDiameter, height: Constants.dotDiameter)
                            .opacity(selectedDate == nil || shownPoint == point ? .opaque : .ultraLowOpacity)
                    }
            }

            if showsTrendLine, let fit = trendLine {
                ForEach([fit.start, fit.end], id: \.date) { point in
                    LineMark(
                        x: .value("Day", point.date),
                        y: .value(appearance.unit ?? "", point.value),
                        series: .value("Series", "Trend")
                    )
                    .foregroundStyle(Color.defaultCyan)
                    .lineStyle(StrokeStyle(lineWidth: Constants.hairline))
                }
            }

            if let marked = shownPoint {
                BrightSelectorV5(date: marked.date, value: marked.value)
            }
        }
        .chartXScale(domain: dateDomain)
        .chartYScale(domain: domain)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .modifier(SelectionModifier(isEnabled: allowsSelection, selection: selection))
    }

    private func axisLabel(_ value: Double) -> some View {
        BrightText(appearance.format(value), size: .body5, color: .lightTextColor)
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
    }

    // Each reading's day of the month, under its dot.
    private var dayLabels: some View {
        GeometryReader { geometry in
            ForEach(points) { point in
                BrightText(point.date.formatted(.brightDay), size: .body6, color: shownPoint == point ? .textColor : .semiLightTextColor)
                    .monospacedDigit()
                    .fixedSize()
                    .position(x: xPosition(of: point.date, width: geometry.size.width), y: geometry.size.height / 2)
            }
        }
        .frame(height: Constants.dayLabelHeight)
    }

    private func sectionLabel(systemImage: String, title: String? = nil) -> some View {
        HStack(spacing: .spacing05x) {
            Image(systemName: systemImage)
                .font(.standard(size: .body4, weight: .regular))
                .foregroundStyle(Color.defaultCyan)

            if let title {
                BrightText(title, size: .body5, color: .lightTextColor, weight: .regular)
            }
        }
        .lineLimit(1)
    }

    private func changeColumn(_ change: Change) -> some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            BrightText(change.span, size: .body5, color: .lightTextColor)
                .padding(.horizontal, .spacing1x)
                .padding(.vertical, .spacing025x)
                .background(Capsule().fill(Color.textColor.opacity(.ultraLowOpacity)))

            BrightText(change.value, size: .standout3, weight: .regular)
                .monospacedDigit()
        }
    }

    // MARK: - Values

    private var shownPoint: Point? {
        guard let selectedDate else { return points.last }
        return points.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }

    private var selection: Binding<Date?> {
        Binding {
            selectedDate
        } set: { newDate in
            let previous = shownPoint
            selectedDate = newDate
            if newDate != nil, shownPoint != previous {
                BrightHaptic.light.play()
            }
        }
    }

    private var dateDomain: ClosedRange<Date> {
        let first = points.first?.date ?? .now
        let last = points.last?.date ?? .now
        return first ... max(last, first.addingTimeInterval(1))
    }

    // Rounded out to tidy numbers either side, so the readings never touch the edge.
    private var domain: ClosedRange<Double> {
        let values = points.map(\.value)
        let low = values.min() ?? 0
        let high = values.max() ?? 1
        let spread = max(high - low, 1)
        let magnitude = pow(10, floor(log10(spread)))
        let step = magnitude * Constants.domainStepRatio
        let lower = (low / step).rounded(.down) * step
        let upper = max((high / step).rounded(.up) * step, lower + step)
        return lower ... upper
    }

    // The least-squares line through the readings, as its two ends.
    private var trendLine: (start: Point, end: Point)? {
        guard points.count > 1, let first = points.first, let last = points.last else { return nil }
        let xs = points.map { $0.date.timeIntervalSince(first.date) }
        let ys = points.map(\.value)
        let count = Double(points.count)
        let meanX = xs.reduce(0, +) / count
        let meanY = ys.reduce(0, +) / count
        let spread = zip(xs, xs).reduce(0) { $0 + ($1.0 - meanX) * ($1.1 - meanX) }
        guard spread > 0 else { return nil }
        let slope = zip(xs, ys).reduce(0) { $0 + ($1.0 - meanX) * ($1.1 - meanY) } / spread
        let end = last.date.timeIntervalSince(first.date)
        return (
            Point(date: first.date, value: meanY - slope * meanX),
            Point(date: last.date, value: meanY + slope * (end - meanX))
        )
    }

    private func xPosition(of date: Date, width: CGFloat) -> CGFloat {
        let span = dateDomain.upperBound.timeIntervalSince(dateDomain.lowerBound)
        guard span > 0 else { return width / 2 }
        return width * date.timeIntervalSince(dateDomain.lowerBound) / span
    }

    private struct SelectionModifier: ViewModifier {
        let isEnabled: Bool
        let selection: Binding<Date?>

        func body(content: Content) -> some View {
            if isEnabled {
                content.chartXSelection(value: selection)
            } else {
                content
            }
        }
    }

    private enum Constants {
        static let axisLabelWidth: CGFloat = 26
        static let lineWidth: CGFloat = 1
        static let hairline: CGFloat = 0.5
        static let dotDiameter: CGFloat = 7
        static let dayLabelHeight: CGFloat = 12
        static let domainStepRatio = 0.5
        static let checkmarkSize: CGFloat = 18
        static let checkmarkBaselineLift: CGFloat = 3
    }
}

#Preview {
    let now = Date.now
    let weights: [Double] = [84.1, 83.7, 83.8, 83.7, 83.9, 83.5, 83.3, 83.1, 83.0, 82.4]
    let points = weights.enumerated().map { index, value in
        BrightDottedLineChartWidgetV5.Point(date: now.addingTimeInterval(-Double(weights.count - 1 - index) * 86_400), value: value)
    }

    ScrollView {
        VStack(spacing: .spacing205x) {
            BrightDottedLineChartWidgetV5(
                appearance: BrightWidgetAppearanceV5(title: "Weight", systemImage: "scalemass.fill", tint: .defaultPurple, unit: "kg", decimals: 1),
                subtitle: "Today, 8:30 AM",
                points: points,
                trend: .init(systemImage: "arrow.down", text: "0.36kg Weekly AVG"),
                showsTrendLine: true,
                size: .medium
            )
            .frame(width: 363, height: 174)

            BrightDottedLineChartWidgetV5(
                appearance: BrightWidgetAppearanceV5(title: "Weight", systemImage: "scalemass.fill", tint: .defaultPurple, unit: "kg", decimals: 1),
                subtitle: "Today, 8:30 AM",
                points: points,
                trend: .init(systemImage: "arrow.down", text: "0.36kg Weekly AVG"),
                showsTrendLine: true,
                changes: [.init(span: "7d", value: "-0.36"), .init(span: "14d", value: "-0.71"), .init(span: "30d", value: "-1.4")],
                note: "5h sleep. Stress and poor sleep can raise water retention.",
                size: .large
            )
            .frame(width: 363, height: 363)
        }
        .padding(.spacing205x)
    }
    .background(Color.defaultBackground)
}
