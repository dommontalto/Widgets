//
//  BrightGraph.swift
//  Widgets
//
//  Created by Zoe Friedman on 4/1/2024.
//

import Charts
import SwiftUI

struct SleepGraphResponseStats: Codable {
    var inBed: SleepGraphResponseValueDuration?
    var asleep: SleepGraphResponseValueDuration?
    var awake: SleepGraphResponseValueDuration?
    var rem: SleepGraphResponseValueDuration?
    var core: SleepGraphResponseValueDuration?
    var deep: SleepGraphResponseValueDuration?
}

struct SleepGraphResponseValueDuration: Codable {
    var hour: Int?
    var minute: Int?
    var percentage: Int?
}

typealias GraphSelectDateCompletion = ((
    _ location: CGPoint,
    _ proxy: ChartProxy,
    _ geometry: GeometryProxy
) -> Void)?

struct GraphDisplayData {
    let id: UUID
    let title: String
    let date: Date
    let values: [GraphValue]?
    let unit: String
    let tag: String
    let total: Double?
    let averages: [GraphAverage]?
    var sleepStats: SleepGraphResponseStats?

    struct GraphValue {
        let name: String
        let value: Double
        let color: Color
        var startDate: Date? // Use for xStart date
        var endDate: Date? // Use for xEnd date
    }

    struct GraphAverage {
        let name: String
        var unit: String?
        var value: Double?
        var percentage: Double?

        var displayString: String {
            if let value {
                "\(Int(value)) \(unit ?? "")"
            } else {
                "-"
            }
        }
        // Use this object to display amount value.
        // For example if value is 1.0 it will display only 1,
        // if it's 1.5 then return value will be 1.5
        var displayValue: String {
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 1
            formatter.minimumIntegerDigits = 1
            return formatter.string(
                from: NSNumber(value: value ?? 0)
            ) ?? ""
        }
    }
}

struct GraphAverageData {
    let date: Date
    let value: Double
    let originalValue: Double
    let color: Color
}

struct BrightGraph: View {
    @SwiftUI.Environment(\.locale) var locale

    let style: Style
    let tab: GraphTab
    let data: [GraphDisplayData]
    let dateSections: [[Date]]
    let unit: String
    var avgStyle: AvgStyle = .ruleMark

    @Binding var currentData: GraphDisplayData?
    @Binding var scrollPosition: Date
    @Binding var upperBound: Double?
    @Binding var selectedAverage: String?
    @Binding var selectedData: GraphDisplayData?
    @Binding var annotationLineHeight: CGFloat

    var onScrollPositionChanged: ((Date) -> Void)?
    var onSelectDate: GraphSelectDateCompletion

    enum Style {
        case bar
        case point
    }

    // Use AvgStyle for Daily graph style only
    // Otherwise modify getAvgPointMarkData logic
    enum AvgStyle {
        case ruleMark
        case pointMark
    }

    class Constants {
        static let dailyXAxisStride = 6
        static let height: CGFloat = 250
        static let secondsInHour = 3600
        static let numWeeksThreeMonthly = 52
        static let hourInDay = 24
        static let numBinsDaily = 1
        static let numBinsWeekly = 7
        static let numBinsMonthly = 30
        static let numBinsThreeMonthly = 13
        static let numBinsYearly = 12
    }

    var body: some View {
        VStack {
            ChartView(
                style: style,
                tab: tab,
                data: data,
                currentData: currentData,
                selectedData: selectedData,
                annotationLineHeight: annotationLineHeight,
                selectedAverage: selectedAverage,
                avgStyle: avgStyle
            )
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(
                length: Constants.secondsInHour * chartLengthMultiplier
            )
            .chartScrollPosition(x: $scrollPosition)
            /*
              // MARK: needs refactoring
             .chartScrollTargetBehavior(
                 .valueAligned(
                     unit: 1,
                     majorAlignment: .page
                 )
             )
              */
            .chartScrollTargetBehavior(
                .dateAligned(
                    tab: tab,
                    dateSections: dateSections,
                    currentData: $currentData
                )
            )
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            onSelectDate?(
                                location,
                                proxy,
                                geometry
                            )
                        }
                }
            }
            .onChange(of: scrollPosition) {
                onScrollPositionChanged?(scrollPosition)
            }
            .chartYScale(
                domain: [
                    .zero,
                    calculatedUpperBound,
                ]
            )
            .chartXAxis {
                switch tab {
                case .daily:
                    dailyXAxisMarks
                case .weekly:
                    weeklyXAxisMarks
                case .monthly:
                    monthlyXAxisMarks
                case .threeMonth:
                    threeMonthXAxisMarks
                case .yearly:
                    yearlyXAxisMarks
                }
            }
            .styleChart(unit: unit)
        }
        .frame(height: Constants.height)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, .spacing2x)
        .transition(.opacity)
        .animation(.bouncy, value: data.count)
        .environment(\.locale, .init(identifier: "en_AU"))
    }

    struct ChartView: View {
        let style: Style
        let tab: GraphTab
        let data: [GraphDisplayData]
        let currentData: GraphDisplayData?
        let selectedData: GraphDisplayData?
        let annotationLineHeight: CGFloat
        let selectedAverage: String?
        let avgStyle: AvgStyle

        private class Constants {
            static let annotationDividerWidth: CGFloat = 1
            static let averageRuleMarkWidth: CGFloat = 1
        }

        var body: some View {
            if style == .bar {
                barChart
            } else {
                pointChart
            }
        }

        var barChart: some View {
            Chart {
                ForEach(data.indices, id: \.self) { index in
                    let item = data[index]
                    let opacity: Double = {
                        var opacity: Double = 1
                        if let selectedData, item.date != selectedData.date {
                            opacity = .veryLowOpacity
                        } else if selectedAverage != nil {
                            opacity = .veryLowOpacity
                        }
                        return opacity
                    }()
                    if let values = item.values {
                        ForEach(values.indices, id: \.self) { index in
                            let value = values[index]
                            if selectedAverage == nil || selectedAverage == value.name {
                                BarMark(
                                    x: .value(value.name, item.date, unit: barMarkUnit),
                                    y: .value("Value", value.value),
                                    width: barWidth
                                )
                                .foregroundStyle(value.color)
                                .cornerRadius(cornerRadius)
                                .opacity(opacity)
                            }
                        }

                    } else {
                        // Empty dummy value.
                        BarMark(
                            x: .value("Dummy", item.date, unit: barMarkUnit),
                            y: .value("Value", 0),
                            width: barWidth
                        )
                    }

                    if let selectedAverage, shouldShowAverageMark(for: item) {
                        if avgStyle == .ruleMark {
                            let averageValue: Double = item.averages?.first(where: {
                                $0.name == selectedAverage
                            })?.value ?? 0

                            RuleMark(
                                y: .value("Average", averageValue)
                            )
                            .lineStyle(StrokeStyle(lineWidth: Constants.averageRuleMarkWidth))
                            .foregroundStyle(Color.textColor)
                            .annotation(position: .top, alignment: .trailing) {
                                BrightText(
                                    Int(averageValue).withCommas + " \(item.unit)",
                                    size: .body5
                                )
                            }
                        } else {
                            let avgData = generateAvgPointMarkData(item)
                            ForEach(avgData.indices, id: \.self) { index in
                                let data = avgData[index]

                                if data.originalValue != 0 {
                                    LineMark(
                                        x: .value(selectedAverage, data.date),
                                        y: .value("Value", data.value)
                                    )
                                    .foregroundStyle(Color.textColor)

                                    PointMark(
                                        x: .value(selectedAverage, data.date),
                                        y: .value("Value", data.value)
                                    )
                                    .symbol {
                                        symbolView(data.color)
                                    }
                                }
                            }
                        }
                    }
                }
                if let selectedData {
                    RuleMark(
                        x: .value("Selection", selectedData.date, unit: barMarkUnit),
                        yEnd: annotationLineHeight
                    )
                    .foregroundStyle(Color.textColor)
                    .zIndex(-2)
                }
            }
        }

        var pointChart: some View {
            Chart {
                ForEach(data.indices, id: \.self) { index in
                    let item = data[index]
                    let opacity: Double = {
                        var opacity: Double = 1
                        if let selectedData, item.date != selectedData.date {
                            opacity = .lowOpacity
                        }
                        return opacity
                    }()
                    if let values = item.values {
                        ForEach(values.indices, id: \.self) { index in
                            let value = values[index]
                            if value.value != 0 {
                                LineMark(
                                    x: .value(value.name, item.date, unit: barMarkUnit),
                                    y: .value("Value", value.value)
                                )
                                .foregroundStyle(Color.textColor)
                            }

                            PointMark(
                                x: .value(value.name, item.date, unit: barMarkUnit),
                                y: .value(item.unit, value.value)
                            )
                            .symbol {
                                if value.value != 0 { symbolView() }
                            }
                            .annotation(position: .automatic, alignment: .top) {
                                VStack {
                                    if index == 0, let selectedData, item.date == selectedData.date {
                                        BrightDividerV5(
                                            .vertical,
                                            thickness: Constants.annotationDividerWidth,
                                            length: annotationLineHeight,
                                            opacity: .opaque
                                        )
                                    }
                                }
                            }
                            .opacity(opacity)
                        }

                    } else {
                        // Empty dummy value.
                        BarMark(
                            x: .value("Dummy", item.date, unit: barMarkUnit),
                            y: .value("Value", 0)
                        )
                    }
                }
            }
        }

        struct RuleMarkAnnotation: View {
            let value: Double
            let unit: String
            let ruleMarkBackground: Color

            private class Constants {
                static let averageRuleMarkHeight: CGFloat = 20
                static let averageRuleMarkCorner: CGFloat = 6
            }

            var body: some View {
                VStack {
                    BrightText(
                        String(Int(value)) + unit + " avg",
                        size: .body5,
                        color: .defaultDarkGreen
                    )
                    .padding(.horizontal, .spacing1x)
                }
                .frame(height: Constants.averageRuleMarkHeight)
                .background(ruleMarkBackground)
                .cornerRadius(Constants.averageRuleMarkCorner)
            }
        }

        private func symbolView(_ color: Color = .defaultBrightGreen) -> some View {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .inset(by: -0.5)
                        .stroke(Color.defaultBackground, lineWidth: 1)
                )
        }

        private func shouldShowAverageMark(for item: GraphDisplayData) -> Bool {
            guard let currentData else { return false }
            switch tab {
            case .daily:
                return currentData.date.hasSameHour(as: item.date)
            case .weekly:
                return currentData.date.isSameDay(as: item.date)
            case .monthly:
                return currentData.date.isSameDay(as: item.date)
            case .threeMonth:
                return currentData.date.isInSameWeek(as: item.date)
            case .yearly:
                return currentData.date.isInSameMonth(as: item.date)
            }
        }

        private var barMarkUnit: Calendar.Component {
            switch tab {
            case .daily:
                .hour
            case .weekly, .monthly:
                .day
            case .threeMonth:
                .weekOfMonth
            case .yearly:
                .month
            }
        }

        private var barWidth: MarkDimension {
            switch tab {
            case .daily, .monthly:
                6
            case .weekly:
                16
            case .threeMonth, .yearly:
                14
            }
        }

        private var cornerRadius: CGFloat {
            switch tab {
            case .daily, .monthly:
                2
            case .weekly:
                5
            case .threeMonth, .yearly:
                4
            }
        }

        func generateAvgPointMarkData(_ item: GraphDisplayData) -> [GraphAverageData] {
            guard let selectedAverage else { return [] }

            var averages = [GraphAverageData]()
            let sortedData = data
                .filter { $0.date.isSameDay(as: item.date) }
                .sorted(by: { $0.date < $1.date })
            var total: Double = 0

            for data in sortedData {
                let valueToAdd = data.values?.first(where: {
                    $0.name == selectedAverage
                })

                total += valueToAdd?.value ?? 0

                averages.append(
                    GraphAverageData(
                        date: data.date.byAdding(component: .minute, value: 30) ?? data.date,
                        value: total,
                        originalValue: valueToAdd?.value ?? 0,
                        color: valueToAdd?.color ?? .clear
                    )
                )
            }
            return averages
        }
    }

    // Chart length is measured in seconds. This multiplier
    // is used against number of seconds.
    private var chartLengthMultiplier: Int {
        switch tab {
        case .daily:
            Constants.hourInDay * Constants.numBinsDaily
        case .weekly:
            Constants.hourInDay * Constants.numBinsWeekly
        case .monthly:
            Constants.hourInDay * Constants.numBinsMonthly
        case .threeMonth:
            Constants.hourInDay * Constants.numBinsWeekly * Constants.numBinsThreeMonthly
        case .yearly:
            Constants.hourInDay * (Constants.numBinsMonthly * Constants.numBinsYearly)
        }
    }

    private var dailyXAxisMarks: AxisMarks<some AxisMark> {
        AxisMarks(values: .stride(by: .hour, count: Constants.dailyXAxisStride)) { value in
            AxisTick()
            AxisValueLabel(format: .dateTime.hour())
                .foregroundStyle(Color.lightTextColor)
                .font(.standard(size: .body3, weight: .regular))
            if value.index != 0,
               value.index != value.count - 1 {
                AxisGridLine()
            }
        }
    }

    private var weeklyXAxisMarks: AxisMarks<some AxisMark> {
        AxisMarks(values: .stride(by: .day)) { value in
            AxisTick()
            AxisValueLabel(
                format: .dateTime.weekday(.abbreviated)
            )
            .foregroundStyle(Color.lightTextColor)
            .font(.standard(size: .body3, weight: .regular))

            if value.index != 0, value.index != value.count - 1 {
                AxisGridLine()
            }
        }
    }

    private var monthlyXAxisMarks: AxisMarks<some AxisMark> {
        AxisMarks { _ in
            AxisTick()
            AxisGridLine()
            AxisValueLabel(
                format: .dateTime.day(.defaultDigits)
            )
            .foregroundStyle(Color.lightTextColor)
            .font(.standard(size: .body3, weight: .regular))
        }
    }

    private var threeMonthXAxisMarks: AxisMarks<some AxisMark> {
        AxisMarks { _ in
            AxisTick()
            AxisGridLine()
            AxisValueLabel(
                format: .dateTime.month(.abbreviated)
            )
            .foregroundStyle(Color.lightTextColor)
            .font(.standard(size: .body3, weight: .regular))
        }
    }

    private var yearlyXAxisMarks: AxisMarks<some AxisMark> {
        AxisMarks(values: .stride(by: .month)) { _ in
            AxisTick()
            AxisGridLine()
            AxisValueLabel(
                format: .dateTime.month(.narrow)
            )
            .foregroundStyle(Color.lightTextColor)
            .font(.standard(size: .body3, weight: .regular))
        }
    }

    var calculatedUpperBound: Double {
        guard let selectedAverage else { return upperBound ?? 0 }

        switch avgStyle {
        case .ruleMark:
            return upperBound ?? 0
        case .pointMark:
            if let averages = data.filter({ $0.date.isSameDay(as: scrollPosition) }).map(\.averages).first {
                if let average = averages?.filter({ $0.name == selectedAverage }).first {
                    let total = average.value ?? 0
                    return total + (total * 0.1) // Add extra room at top
                }
            }
            return 0
        }
    }
}
extension Sequence {
    func sum<T: AdditiveArithmetic>(_ predicate: (Element) -> T) -> T {
        reduce(.zero) { $0 + predicate($1) }
    }
}
