//
//  LighthouseV2ChartView.swift
//  Widgets
//
//

import SwiftUI

// A reply's chart: the Health tab's V5 widget for its style, fed the server's own figures and range.
struct LighthouseV2ChartView: View {
    let chart: LighthouseV2Block.Chart
    var onTap: (HealthWidgetKindV5) -> Void = { _ in }

    var body: some View {
        if let inputs = LighthouseV2ChartInputs(chart) {
            LighthouseV2ChartWidget(chart: chart, inputs: inputs)
                .aspectRatio(inputs.size == .large ? Constants.largeAspect : Constants.mediumAspect, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .simultaneousGesture(openGesture(inputs.kind))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(chart.a11y)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { onTap(inputs.kind) }
                .accessibilityIdentifier("lighthouse.v2.chart.\(chart.style)")
        }
    }

    // A short press opens the feature; a hold is the chart's own selection.
    private func openGesture(_ kind: HealthWidgetKindV5) -> some Gesture {
        LongPressGesture(minimumDuration: Constants.openMaxPressDuration)
            .exclusively(before: TapGesture())
            .onEnded { value in
                guard case .second = value else { return }
                onTap(kind)
            }
    }

    private enum Constants {
        // The V5 chat sizes at a 393 pt screen: medium 357×171, large 357×357.
        static let mediumAspect: CGFloat = 357 / 171
        static let largeAspect: CGFloat = 1
        static let openMaxPressDuration: Double = 0.3
    }
}

// The V5 view for a chart's family, fed the server's figures; a reply and a Health tile both draw with it.
struct LighthouseV2ChartWidget: View {
    let chart: LighthouseV2Block.Chart
    let inputs: LighthouseV2ChartInputs
    var allowsSelection = true

    var body: some View {
        switch inputs.content {
        case let .bars(bars):
            BrightVerticalBarChartWidgetV5(
                appearance: inputs.appearance,
                subtitle: chart.range.label,
                range: bars.range,
                bars: bars.bars,
                fill: bars.fill,
                headline: bars.headline,
                size: inputs.size,
                allowsSelection: allowsSelection,
                slotStarts: bars.slotStarts,
                slotRange: inputs.interval,
                headlineFigure: chart.headline?.value,
                splitFigures: bars.split,
                valueFormat: chart.unit == "min" ? .minutes : .number
            )
        case let .line(line):
            BrightLineChartWidgetV5(
                appearance: inputs.appearance,
                bucketed: line.samples,
                interval: inputs.interval,
                low: line.low,
                high: line.high,
                average: line.average,
                range: inputs.hourRange ?? .today,
                size: inputs.size,
                allowsSelection: allowsSelection
            )
        case let .dotted(dotted):
            BrightDottedLineChartWidgetV5(
                appearance: inputs.appearance,
                subtitle: chart.range.label,
                points: dotted.points,
                trend: dotted.trend,
                showsTrendLine: dotted.showsTrendLine,
                changes: dotted.changes,
                size: inputs.size,
                allowsSelection: allowsSelection,
                showsEveryPoint: true
            )
        case let .sleep(sleep):
            BrightSleepWidgetV5(
                segments: sleep.segments,
                asleepMinutes: sleep.asleepMinutes ?? 0,
                inBedMinutes: sleep.inBedMinutes ?? 0,
                score: sleep.score ?? 0,
                restingHeartRate: sleep.restingHeartRate ?? 0,
                heartRateVariability: sleep.heartRateVariability ?? 0,
                size: inputs.size,
                allowsSelection: allowsSelection
            )
        case let .range(measures):
            BrightDottedRangeChartWidgetV5(appearance: inputs.appearance, measures: measures, size: inputs.size, allowsSelection: allowsSelection)
        case let .rings(rings):
            BrightRingGroupWidgetV5(rings: rings, size: inputs.size, allowsSelection: allowsSelection) {
                ringHeader
            }
        case let .tank(tank):
            BrightWaterWidgetV5(
                appearance: inputs.appearance,
                drinks: tank.drinks,
                goal: tank.goal,
                yesterday: 0,
                size: inputs.size,
                allowsSelection: allowsSelection
            )
        case let .cycle(cycle):
            BrightMenstrualWidgetV5(
                cycle: cycle.cycle,
                today: cycle.today,
                nextPeriod: cycle.nextPeriod,
                daysUntilPeriod: cycle.daysUntil,
                size: inputs.size,
                allowsSelection: allowsSelection
            )
        }
    }

    // The icon-and-name header the Health tab's rings use.
    private var ringHeader: some View {
        HStack(spacing: .spacing05x) {
            Image(systemName: inputs.appearance.systemImage)
                .font(.standard(size: .subheading, weight: .light))
                .foregroundStyle(inputs.appearance.tint)

            BrightText(inputs.appearance.title, size: .body1, weight: .regular)
        }
        .lineLimit(1)
    }
}

// What a chart block becomes for its V5 view. Every printed figure and every range is the server's;
// nil when the block can't be read, so the reply shows a placeholder instead.
struct LighthouseV2ChartInputs {
    // The server names Water "hydration".
    static func kind(tile: String) -> HealthWidgetKindV5? {
        HealthWidgetKindV5(rawValue: tile == "hydration" ? "water" : tile)
    }

    enum Content {
        case bars(Bars)
        case line(Line)
        case dotted(Dotted)
        case sleep(Sleep)
        case range([BrightDottedRangeChartWidgetV5.Measure])
        case rings([BrightRingGroupWidgetV5.Ring])
        case tank(Tank)
        case cycle(Cycle)
    }

    struct Tank {
        let drinks: [BrightWaterWidgetV5.Drink]
        let total: Double
        let goal: Double
    }

    struct Cycle {
        let cycle: BrightMenstrualWidgetV5.Cycle
        let today: Int
        let nextPeriod: Date
        let daysUntil: Int
    }


    struct Bars {
        let range: BrightWidgetRangeV5
        let bars: [BrightVerticalBarChartWidgetV5.Bar]
        let slotStarts: [Date]
        let fill: BrightVerticalBarChartWidgetV5.Fill
        let headline: BrightVerticalBarChartWidgetV5.Headline
        let split: [BrightVerticalBarChartWidgetV5.Segment]?
    }

    struct Line {
        let samples: [BrightLineChartWidgetV5.Sample]
        let low: Double
        let high: Double
        let average: Double
    }

    struct Dotted {
        let points: [BrightDottedLineChartWidgetV5.Point]
        let trend: BrightDottedLineChartWidgetV5.Trend?
        let showsTrendLine: Bool
        let changes: [BrightDottedLineChartWidgetV5.Change]
    }

    struct Sleep {
        let segments: [BrightSleepWidgetV5.Segment]
        let asleepMinutes: Int
        let inBedMinutes: Int
        let score: Int?
        let restingHeartRate: Int?
        let heartRateVariability: Int?
    }

    let kind: HealthWidgetKindV5
    let size: BrightWidgetSizeV5
    let appearance: BrightWidgetAppearanceV5
    let interval: DateInterval
    // A tile's hour window (CH3), for the views' axis labels; the interval is still the server's.
    let hourRange: BrightWidgetRangeV5?
    let content: Content

    init?(_ chart: LighthouseV2Block.Chart) {
        guard chart.chart == 1,
              let kind = chart.tileKind.flatMap(LighthouseV2ChartInputs.kind(tile:)),
              let start = Date(lighthouseISO: chart.range.start),
              let end = Date(lighthouseISO: chart.range.end), start < end
        else { return nil }
        self.kind = kind
        size = BrightWidgetSizeV5(rawValue: chart.size) ?? .medium
        interval = DateInterval(start: start, end: end)
        hourRange = BrightWidgetRangeV5(seriesToken: chart.range.type)
        appearance = Self.appearance(style: chart.style, kind: kind, unit: chart.unit)

        switch chart.data {
        case let .bar(data):
            let starts = data.bars.compactMap { Date(lighthouseISO: $0.start) }
            guard starts.count == data.bars.count, data.bars.count == data.slotCount else { return nil }
            let bars = data.bars.map { bar in
                BrightVerticalBarChartWidgetV5.Bar(index: bar.index, value: bar.value, segments: bar.segments.map(Self.segment))
            }
            let headline: BrightVerticalBarChartWidgetV5.Headline = switch data.headline {
            case "average": .average
            case "split": .split
            default: .total
            }
            let split = data.split.isEmpty ? nil : data.split.map { Self.segment(.init(key: $0.key, value: $0.figure.value)) }
            content = .bars(Bars(
                range: data.slot == "day" ? .week : hourRange ?? .today,
                bars: bars,
                slotStarts: starts,
                fill: Self.fill(style: chart.style),
                headline: headline,
                split: split
            ))
        case let .line(data):
            let samples = data.samples.compactMap { sample in
                Date(lighthouseISO: sample.t).map { BrightLineChartWidgetV5.Sample(date: $0, value: sample.v) }
            }
            guard samples.count == data.samples.count, !samples.isEmpty else { return nil }
            content = .line(Line(samples: samples, low: data.stats.min.value, high: data.stats.max.value, average: data.stats.mean.value))
        case let .dottedLine(data):
            let points = data.points.compactMap { point in
                Date(brightDayKey: point.date).map { BrightDottedLineChartWidgetV5.Point(date: $0, value: point.value) }
            }
            guard points.count == data.points.count, !points.isEmpty else { return nil }
            content = .dotted(Dotted(
                points: points,
                trend: data.perWeek.map { Self.trend($0, unit: chart.unit) },
                showsTrendLine: data.showTrendLine,
                changes: data.change.map { [Self.change($0)] } ?? []
            ))
        case let .sleep(data):
            let segments = data.segments.compactMap { segment -> BrightSleepWidgetV5.Segment? in
                guard let stage = Self.stage(segment.stage),
                      let start = Date(lighthouseISO: segment.start),
                      let end = Date(lighthouseISO: segment.end)
                else { return nil }
                return BrightSleepWidgetV5.Segment(stage: stage, start: start, end: end)
            }
            guard segments.count == data.segments.count, !segments.isEmpty else { return nil }
            content = .sleep(Sleep(
                segments: segments,
                asleepMinutes: Int(data.asleep.value.rounded()),
                inBedMinutes: Int((data.inBed ?? data.asleep).value.rounded()),
                score: data.score.map { Int($0.value.rounded()) },
                restingHeartRate: data.restingHR.map { Int($0.value.rounded()) },
                heartRateVariability: data.hrv.map { Int($0.value.rounded()) }
            ))
        case let .dottedRange(data):
            let measures = data.measures.compactMap(Self.measure)
            guard measures.count == data.measures.count, !measures.isEmpty else { return nil }
            content = .range(measures)
        case let .ring(data):
            let rings = data.rings.compactMap(Self.ring)
            guard rings.count == data.rings.count, !rings.isEmpty else { return nil }
            content = .rings(rings)
        case let .water(data):
            // The Health tab's tank is in litres; the server's figures are millilitres.
            let drinks = data.drinks.compactMap { drink in
                Date(lighthouseISO: drink.t).map { BrightWaterWidgetV5.Drink(date: $0, litres: drink.ml / Constants.mlPerLitre) }
            }
            guard drinks.count == data.drinks.count, let goal = data.goal else { return nil }
            content = .tank(Tank(drinks: drinks, total: data.total.value / Constants.mlPerLitre, goal: goal.value / Constants.mlPerLitre))
        case let .menstrual(data):
            guard data.fertileWindow.count == 2, data.fertileWindow[0] <= data.fertileWindow[1],
                  let nextPeriod = Date(brightDayKey: data.nextPeriod)
            else { return nil }
            content = .cycle(Cycle(
                cycle: BrightMenstrualWidgetV5.Cycle(
                    length: Int(data.length.value.rounded()),
                    periodLength: data.periodLength,
                    ovulationWindow: data.fertileWindow[0] ... data.fertileWindow[1],
                    ovulationDay: data.ovulationDay,
                    lutealStart: data.lutealStart
                ),
                today: Int(data.today.value.rounded()),
                nextPeriod: nextPeriod,
                daysUntil: Int(data.daysUntil.value.rounded())
            ))
        case .comparison:
            // No V5 view draws a population yet (V5/briefs/needs-design.md), so a reply shows the placeholder.
            return nil
        }
    }

    // CH2's vitals keep the Health tab's icons and colours; the bands are the server's.
    private static func measure(_ measure: LighthouseV2Block.ChartData.DottedRange.Measure) -> BrightDottedRangeChartWidgetV5.Measure? {
        guard measure.band.low <= measure.band.high else { return nil }
        let look: (label: String, image: String, color: Color, unit: String)? = switch measure.key {
        case "blood_oxygen": ("SpO2", "drop.fill", .defaultRed, "%")
        case "respiratory_rate": ("Resp.", "lungs.fill", .defaultCyan, "br/min")
        case "wrist_temp": ("Temp.", "thermometer.variable", .defaultOrange, "°C")
        default: nil
        }
        guard let look else { return nil }
        return .init(
            label: look.label,
            systemImage: look.image,
            iconColor: look.color,
            value: measure.value.value,
            normalRange: measure.band.low ... measure.band.high,
            unit: look.unit,
            decimals: 1,
            isSigned: measure.signed
        )
    }

    // Each ring keeps its Health tab colour; sleep stages caption their time.
    private static func ring(_ ring: LighthouseV2Block.ChartData.Rings.Ring) -> BrightRingGroupWidgetV5.Ring? {
        let value = ring.value.value
        let goal = ring.goal.value
        return switch ring.key {
        case "intake": .init(label: "Intake", shortLabel: "I", value: value, goal: goal, color: .defaultGreen)
        case "carbs": .init(label: "Carbs", shortLabel: "C", value: value, goal: goal, color: .defaultGreen)
        case "fat": .init(label: "Fats", shortLabel: "F", value: value, goal: goal, color: .defaultYellow)
        case "protein": .init(label: "Protein", shortLabel: "P", value: value, goal: goal, color: .defaultPink)
        case "water":
            .init(label: "Water", shortLabel: "W", value: value / Constants.mlPerLitre, goal: goal / Constants.mlPerLitre, color: .defaultCyan, decimals: 2, warnsWhenOver: false)
        case "awake": .init(label: "Awake", shortLabel: "A", value: value, goal: goal, color: .defaultOrange, caption: duration(value))
        case "rem": .init(label: "REM", shortLabel: "R", value: value, goal: goal, color: .defaultCyan, caption: duration(value))
        case "core": .init(label: "Core", shortLabel: "C", value: value, goal: goal, color: .defaultSkyBlue, caption: duration(value))
        case "deep": .init(label: "Deep", shortLabel: "D", value: value, goal: goal, color: .defaultBrightViolet, caption: duration(value))
        default: nil
        }
    }

    private enum Constants {
        static let mlPerLitre = 1000.0
    }

    // "1h 54m", as the Health tab's sleep rings write it.
    private static func duration(_ minutes: Double) -> String {
        let total = Int(minutes.rounded())
        return total < 60 ? "\(total)m" : "\(total / 60)h \(total % 60)m"
    }

    // The Health tab's look for each style; the unit is the server's.
    static func appearance(style: String, kind: HealthWidgetKindV5, unit: String?) -> BrightWidgetAppearanceV5 {
        let unit = unit.map(displayUnit)
        return switch style {
        case "totalEnergyBars": BrightWidgetAppearanceV5(title: "Total Energy", systemImage: "flame.fill", tint: .defaultOrange, unit: unit)
        case "activeEnergyBars": BrightWidgetAppearanceV5(title: "Active Energy", systemImage: "flame.fill", tint: .defaultOrange, unit: unit)
        case "stepBars": BrightWidgetAppearanceV5(title: "Steps", systemImage: "shoeprints.fill", tint: .defaultYellow)
        case "intakeBars": BrightWidgetAppearanceV5(title: "Intake", systemImage: "arrow.right", tint: .defaultGreen, unit: unit)
        case "waterBars": BrightWidgetAppearanceV5(title: "Water", systemImage: "drop.fill", tint: .defaultCyan, unit: unit)
        case "macroBars": BrightWidgetAppearanceV5(title: "Macros", systemImage: "chart.pie.fill", tint: .textColor, unit: unit)
        case "weightLine": BrightWidgetAppearanceV5(title: "Weight", systemImage: "scalemass.fill", tint: .defaultPurple, unit: unit, decimals: 1)
        case "restingHRBars": BrightWidgetAppearanceV5(title: "Resting Heart Rate", systemImage: kind.systemImage, tint: kind.tint, unit: unit)
        case "sleepBars": BrightWidgetAppearanceV5(title: "Sleep", systemImage: kind.systemImage, tint: kind.tint, unit: unit)
        case "vo2Line": BrightWidgetAppearanceV5(title: "VO2 Max", systemImage: "lungs.fill", tint: .defaultSkyBlue, unit: unit, decimals: 1)
        case "sleepVitals": BrightWidgetAppearanceV5(title: "Sleep Vitals", systemImage: "moon.fill", tint: .defaultCyan)
        case "macroRings": BrightWidgetAppearanceV5(title: "Macros", systemImage: "arrow.right", tint: .defaultGreen)
        case "sleepRings": BrightWidgetAppearanceV5(title: "Sleep", systemImage: kind.systemImage, tint: kind.tint)
        case "waterRing", "waterTank": BrightWidgetAppearanceV5(title: "Water", systemImage: "drop.fill", tint: .defaultCyan, unit: "L", decimals: 2)
        default: BrightWidgetAppearanceV5(title: kind.title, systemImage: kind.systemImage, tint: kind.tint, unit: unit)
        }
    }

    private static func displayUnit(_ unit: String) -> String {
        switch unit {
        case "kcal": "Cal"
        case "bpm": "BPM"
        case "min": "min"
        default: unit
        }
    }

    static func fill(style: String) -> BrightVerticalBarChartWidgetV5.Fill {
        switch style {
        case "totalEnergyBars", "waterBars": .solid(.defaultCyan)
        case "activeEnergyBars": .solid(.defaultOrange)
        case "stepBars": .solid(.defaultYellow)
        case "restingHRBars": .solid(.defaultRed)
        case "sleepBars": .solid(.defaultBlue)
        default: .solid(.defaultGreen)
        }
    }

    // Macro and sleep-stage segments keep the Health tab's fixed colours.
    static func segment(_ segment: LighthouseV2Block.ChartData.Bars.Segment) -> BrightVerticalBarChartWidgetV5.Segment {
        switch segment.key {
        case "carbs": return .init(label: "C", value: segment.value, color: .defaultGreen)
        case "fat": return .init(label: "F", value: segment.value, color: .defaultYellow)
        case "protein": return .init(label: "P", value: segment.value, color: .defaultPink)
        default:
            let stage = stage(segment.key)
            return .init(label: stage?.title ?? segment.key.capitalized, value: segment.value, color: stage?.color ?? .lightTextColor)
        }
    }

    static func stage(_ key: String) -> BrightSleepWidgetV5.Stage? {
        switch key {
        case "awake": .awake
        case "rem": .rem
        case "core": .core
        case "deep": .deep
        default: nil
        }
    }

    private static func trend(_ change: LighthouseV2Block.ChartData.DottedLine.Change, unit: String?) -> BrightDottedLineChartWidgetV5.Trend {
        let arrow = change.direction == "down" ? "arrow.down" : change.direction == "up" ? "arrow.up" : "arrow.right"
        let value = change.figure.value.formatted(.number.precision(.fractionLength(0 ... 2)))
        return .init(systemImage: arrow, text: "\(value)\(unit ?? "") Weekly AVG")
    }

    private static func change(_ change: LighthouseV2Block.ChartData.DottedLine.Change) -> BrightDottedLineChartWidgetV5.Change {
        let sign = change.direction == "down" ? "-" : change.direction == "up" ? "+" : ""
        let value = change.figure.value.formatted(.number.precision(.fractionLength(0 ... 1)))
        return .init(span: "Total", value: "\(sign)\(value)")
    }
}
