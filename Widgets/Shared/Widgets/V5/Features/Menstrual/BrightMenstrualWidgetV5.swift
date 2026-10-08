//
//  BrightMenstrualWidgetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 8/10/2026.
//

import Charts
import SwiftUI

// The cycle as a strip of day pills coloured by phase. Small zooms in on the ovulation
// window; medium follows the cycle from today with the phases marked underneath; large
// adds the window, ovulation, temperature and resting heart rate.
struct BrightMenstrualWidgetV5: View {
    enum Phase {
        case menstrual
        case follicular
        case ovulation
        case luteal

        var title: String {
            switch self {
            case .menstrual: "Period"
            case .follicular: "Follicular"
            case .ovulation: "Ovulation"
            case .luteal: "Luteal"
            }
        }

        var systemImage: String {
            switch self {
            case .menstrual: "moonphase.new.moon"
            case .follicular: "moonphase.waxing.crescent"
            case .ovulation: "moonphase.waxing.gibbous"
            case .luteal: "moonphase.first.quarter"
            }
        }

        var color: Color {
            switch self {
            case .menstrual: .defaultRed
            case .follicular: .defaultGreen
            case .ovulation: .defaultCyan
            case .luteal: .defaultPurple
            }
        }
    }

    // The cycle's shape: its length and where each phase falls, as days counted from 1.
    struct Cycle: Hashable {
        let length: Int
        let periodLength: Int
        let ovulationWindow: ClosedRange<Int>
        let ovulationDay: Int
        // Where the luteal days start showing as luteal, late in the cycle.
        let lutealStart: Int

        func phase(of day: Int) -> Phase {
            let day = ((day - 1) % length + length) % length + 1
            if day <= periodLength { return .menstrual }
            if day < ovulationWindow.lowerBound { return .follicular }
            if ovulationWindow.contains(day) { return .ovulation }
            return .luteal
        }

        // Wrapped into the cycle, so days past its end are the next cycle's.
        func cycleDay(_ day: Int) -> Int {
            ((day - 1) % length + length) % length + 1
        }
    }

    // The large size's four figures.
    struct Details: Hashable {
        let ovulationWindow: String
        let ovulation: String
        let temperatureDeviation: String
        let restingHeartRate: String
    }

    let cycle: Cycle
    let today: Int
    let nextPeriod: Date
    let daysUntilPeriod: Int
    var details: Details?
    let size: BrightWidgetSizeV5
    var allowsSelection = true

    @State private var selectedDay: Int?

    var body: some View {
        Group {
            if size == .small {
                compactLayout
            } else {
                expandedLayout
            }
        }
        .padding(.spacing205x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(BrightCardModifierV5(color: .defaultHomeCards))
        .onChange(of: allowsSelection) { _, allows in
            if !allows {
                selectedDay = nil
            }
        }
        .animation(.brightEaseInOut, value: selectedDay)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(cycle.phase(of: today).title), cycle day \(today) of \(cycle.length), next period in \(daysUntilPeriod) days")
    }

    // MARK: - Layouts

    // The ovulation window, with the best day picked out.
    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            header(phase: .ovulation, subtitle: "Period: in \(daysUntilPeriod) Days")

            Spacer(minLength: .spacing0x)

            strip(firstDay: cycle.ovulationDay - Constants.compactLeadingDays, arrowDay: cycle.ovulationDay, colour: compactFill)

            BrightText(selectedDay.map { dayCaption($0) } ?? "Optimal Day", size: .body4, color: .lightTextColor)
                .monospacedDigit()
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity)

            Spacer(minLength: .spacing0x)
        }
    }

    private var expandedLayout: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            HStack(alignment: .top, spacing: .spacing1x) {
                header(
                    phase: cycle.phase(of: selectedDay ?? today),
                    subtitle: selectedDay.map { dayCaption($0) } ?? "Cycle day: \(today)/\(cycle.length)"
                )

                Spacer(minLength: .spacing0x)

                nextPeriodSummary
            }

            Spacer(minLength: .spacing0x)

            strip(firstDay: today - Constants.expandedLeadingDays, arrowDay: today, colour: cycleFill)

            phaseMarkers

            Spacer(minLength: .spacing0x)

            if size == .large, let details {
                BrightDividerV5()
                    .padding(.horizontal, -.spacing205x)

                detailsGrid(details)
                    .padding(.top, .spacing1x)
            }
        }
    }

    // MARK: - Header

    private func header(phase: Phase, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing05x) {
                Image(systemName: phase.systemImage)
                    .font(.standard(size: .subheading, weight: .light))
                    .foregroundStyle(phase.color)

                BrightText(phase.title, size: .body1, weight: .regular)
                    .contentTransition(.numericText())
            }
            .lineLimit(1)

            BrightText(subtitle, size: .body2, color: .lightTextColor)
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
        }
    }

    // "Period:" over its date and how many days away.
    private var nextPeriodSummary: some View {
        VStack(alignment: .trailing, spacing: .spacing05x) {
            BrightText("Period:", size: .body5, color: .lightTextColor)

            HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                BrightText(nextPeriod.formatted(.brightDate), size: .body1, weight: .regular)

                Circle()
                    .fill(Color.lightTextColor)
                    .frame(width: .spacing05x, height: .spacing05x)
                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] + .spacing05x }

                BrightText("\(daysUntilPeriod)D", size: .body1, color: .lightTextColor, weight: .regular)
                    .monospacedDigit()
            }
        }
        .lineLimit(1)
    }

    // MARK: - Strip

    // A pill a day from `firstDay`, as many as fit, faded out at both ends. The arrow
    // points down at `arrowDay`.
    private func strip(firstDay: Int, arrowDay: Int, colour: @escaping (Int) -> PillStyle) -> some View {
        GeometryReader { geometry in
            let count = max(Int((geometry.size.width + Constants.pillGap) / (Constants.pillWidth + Constants.pillGap)), 1)

            VStack(spacing: .spacing05x) {
                HStack(spacing: Constants.pillGap) {
                    ForEach(0 ..< count, id: \.self) { offset in
                        let day = firstDay + offset

                        Image(systemName: "arrow.down")
                            .font(.standard(size: .body3, weight: .medium))
                            .foregroundStyle(colour(day).arrow)
                            .frame(width: Constants.pillWidth)
                            .opacity(day == (selectedDay ?? arrowDay) ? .opaque : .zero)
                    }
                }

                HStack(spacing: Constants.pillGap) {
                    ForEach(0 ..< count, id: \.self) { offset in
                        pill(colour(firstDay + offset))
                            .opacity(selectedDay == nil || selectedDay == firstDay + offset ? .opaque : .ultraLowOpacity)
                    }
                }
                .overlay { edgeFades }
                .overlay { selectionLayer(firstDay: firstDay, count: count) }
            }
            .frame(width: geometry.size.width, alignment: .leading)
        }
        .frame(height: Constants.pillHeight + Constants.arrowHeight + .spacing05x)
    }

    // An empty chart over the pills, so holding them uses the same gesture as the charts
    // and the page still scrolls. Snaps to the pill under the finger.
    @ViewBuilder
    private func selectionLayer(firstDay: Int, count: Int) -> some View {
        if allowsSelection {
            Chart {
                PointMark(x: .value("Day", 0.5), y: .value("Floor", 0))
                    .opacity(.zero)
            }
            .chartXScale(domain: 0 ... Double(count))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .chartXSelection(value: Binding {
                selectedDay.map { Double($0 - firstDay) + 0.5 }
            } set: { position in
                let day = position.map { firstDay + min(max(Int($0), 0), count - 1) }
                guard day != selectedDay else { return }
                selectedDay = day
                if day != nil {
                    BrightHaptic.light.play()
                }
            })
        }
    }

    // A held day: where it falls in the cycle and its date.
    private func dayCaption(_ day: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: day - today, to: .now) ?? .now
        return "Cycle day \(cycle.cycleDay(day)) · \(date.formatted(.brightDate))"
    }

    private func pill(_ style: PillStyle) -> some View {
        Capsule()
            .fill(style.fill)
            .overlay {
                if let outline = style.outline {
                    Capsule()
                        .strokeBorder(outline, lineWidth: Constants.outlineWidth)
                }
            }
            .shadow(color: style.glow ?? .clear, radius: Constants.glowRadius)
            .frame(width: Constants.pillWidth, height: Constants.pillHeight)
    }

    // The card's colour washing over each end, so the strip runs off rather than stops.
    private var edgeFades: some View {
        HStack(spacing: .spacing0x) {
            LinearGradient(colors: [.defaultHomeCards, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: Constants.fadeWidth)

            Spacer(minLength: .spacing0x)

            LinearGradient(colors: [.clear, .defaultHomeCards], startPoint: .leading, endPoint: .trailing)
                .frame(width: Constants.fadeWidth)
        }
        .padding(.horizontal, -.spacing05x)
        .allowsHitTesting(false)
    }

    // MARK: - Pill colours

    struct PillStyle {
        let fill: Color
        var outline: Color?
        var glow: Color?
        var arrow: Color
    }

    // Small: only the window lights up, brightest on the best day.
    private func compactFill(_ day: Int) -> PillStyle {
        let cycleDay = cycle.cycleDay(day)
        if cycleDay == cycle.ovulationDay {
            return PillStyle(fill: .defaultCyan, glow: .defaultCyan, arrow: .defaultCyan)
        }
        if cycle.ovulationWindow.contains(cycleDay) {
            return PillStyle(fill: .defaultCyan.opacity(.semiLowOpacity), arrow: .defaultCyan)
        }
        return PillStyle(fill: .textColor.opacity(.ultraLowOpacity), arrow: .defaultCyan)
    }

    // Medium and large: each day in its phase's colour, today outlined, the best day lit.
    private func cycleFill(_ day: Int) -> PillStyle {
        let cycleDay = cycle.cycleDay(day)
        let phase = cycle.phase(of: day)
        if day == today {
            return PillStyle(fill: phase.color.opacity(.veryLowOpacity), outline: phase.color, glow: phase.color.opacity(.lowOpacity), arrow: phase.color)
        }
        switch phase {
        case .menstrual:
            return PillStyle(fill: phase.color.opacity(.lowOpacity), arrow: phase.color)
        case .follicular:
            return PillStyle(fill: phase.color.opacity(.ultraLowOpacity), arrow: phase.color)
        case .ovulation:
            if cycleDay == cycle.ovulationDay {
                return PillStyle(fill: phase.color, glow: phase.color, arrow: phase.color)
            }
            let nearPeak = abs(cycleDay - cycle.ovulationDay) == 1
            return PillStyle(fill: phase.color.opacity(nearPeak ? .lowOpacity : .veryLowOpacity), arrow: phase.color)
        case .luteal:
            let fill = cycleDay >= cycle.lutealStart ? phase.color.opacity(.minimalOpacity) : Color.textColor.opacity(.ultraLowOpacity)
            return PillStyle(fill: fill, arrow: phase.color)
        }
    }

    // MARK: - Phase markers

    // Under the strip: the ovulation window as a bracket, then where luteal and the
    // next period begin.
    private var phaseMarkers: some View {
        GeometryReader { geometry in
            let firstDay = today - Constants.expandedLeadingDays
            let stride = Constants.pillWidth + Constants.pillGap
            let x = { (day: Int) in CGFloat(day - firstDay) * stride + Constants.pillWidth / 2 }
            let windowStart = x(nextOccurrence(of: cycle.ovulationWindow.lowerBound))
            let windowEnd = x(nextOccurrence(of: cycle.ovulationWindow.upperBound))
            let lutealStart = x(nextOccurrence(of: cycle.lutealStart))
            let period = x(nextOccurrence(of: cycle.length + 1))

            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color.defaultCyan)
                    .frame(width: max(windowEnd - windowStart, 0), height: Constants.outlineWidth)
                    .offset(x: windowStart, y: Constants.markerIconSize / 2)

                markerIcon(.ovulation, at: windowStart)
                markerIcon(.ovulation, at: windowEnd)
                markerLabel(Phase.ovulation.title, at: (windowStart + windowEnd) / 2)

                markerIcon(.luteal, at: lutealStart)
                markerLabel(Phase.luteal.title, at: lutealStart)

                markerIcon(.menstrual, at: period)
                markerLabel(Phase.menstrual.title, at: period)
            }
        }
        .frame(height: Constants.markerIconSize + .spacing05x + Constants.markerLabelHeight)
    }

    private func markerIcon(_ phase: Phase, at x: CGFloat) -> some View {
        Image(systemName: phase.systemImage)
            .font(.standard(size: .body5, weight: .light))
            .foregroundStyle(phase.color)
            .background(Circle().fill(Color.defaultHomeCards))
            .position(x: x, y: Constants.markerIconSize / 2)
    }

    private func markerLabel(_ text: String, at x: CGFloat) -> some View {
        BrightText(text, size: .body6, color: .lightTextColor)
            .fixedSize()
            .position(x: x, y: Constants.markerIconSize + .spacing05x + Constants.markerLabelHeight / 2)
    }

    // The first time this cycle day comes round from today on.
    private func nextOccurrence(of cycleDay: Int) -> Int {
        let wrapped = cycle.cycleDay(cycleDay)
        let current = cycle.cycleDay(today)
        let ahead = (wrapped - current + cycle.length) % cycle.length
        return today + (cycleDay > cycle.length && ahead == 0 ? cycle.length : ahead)
    }

    // MARK: - Details

    private func detailsGrid(_ details: Details) -> some View {
        HStack(alignment: .top, spacing: .spacing0x) {
            VStack(alignment: .leading, spacing: .spacing3x) {
                detail(systemImage: "clock", tint: .defaultCyan, title: "Ovulation Window", value: details.ovulationWindow)

                detail(systemImage: "thermometer.variable", tint: .defaultOrange, title: "Temp Deviation", value: details.temperatureDeviation)
            }
            // As wide as its longest value needs; the divider follows it.
            .fixedSize(horizontal: true, vertical: false)

            BrightDividerV5(.vertical)
                .padding(.horizontal, .spacing2x)

            VStack(alignment: .leading, spacing: .spacing3x) {
                detail(systemImage: Phase.ovulation.systemImage, tint: .defaultCyan, title: "Ovulation", value: details.ovulation)

                detail(systemImage: "heart.fill", tint: .defaultRed, title: "RHR", value: details.restingHeartRate, unit: "BPM")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func detail(systemImage: String, tint: Color, title: String, value: String, unit: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing05x) {
                Image(systemName: systemImage)
                    .font(.standard(size: .body4, weight: .regular))
                    .foregroundStyle(tint)

                BrightText(title, size: .body5, color: .lightTextColor)
            }

            HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                BrightText(value, size: .standout2, weight: .regular)
                    .monospacedDigit()

                if let unit {
                    BrightText(unit, size: .body5, color: .lightTextColor)
                }
            }
        }
        .lineLimit(1)
    }

    private enum Constants {
        static let pillWidth: CGFloat = 8
        static let pillHeight: CGFloat = 32
        static let pillGap: CGFloat = 2.5
        static let outlineWidth: CGFloat = 0.5
        static let glowRadius: CGFloat = 2
        static let arrowHeight: CGFloat = 16
        static let fadeWidth: CGFloat = .spacing5x
        static let markerIconSize: CGFloat = 14
        static let markerLabelHeight: CGFloat = 12
        // How many days of the strip sit before the day it's centred on.
        static let compactLeadingDays = 8
        static let expandedLeadingDays = 4
    }
}

#Preview {
    let cycle = BrightMenstrualWidgetV5.Cycle(length: 34, periodLength: 5, ovulationWindow: 14 ... 19, ovulationDay: 18, lutealStart: 27)
    let nextPeriod = Date.now.addingTimeInterval(24 * 24 * 60 * 60)

    ScrollView {
        VStack(spacing: .spacing205x) {
            BrightMenstrualWidgetV5(cycle: cycle, today: 10, nextPeriod: nextPeriod, daysUntilPeriod: 24, size: .small)
                .frame(width: 174, height: 174)

            BrightMenstrualWidgetV5(cycle: cycle, today: 10, nextPeriod: nextPeriod, daysUntilPeriod: 24, size: .medium)
                .frame(width: 363, height: 174)

            BrightMenstrualWidgetV5(
                cycle: cycle,
                today: 10,
                nextPeriod: nextPeriod,
                daysUntilPeriod: 24,
                details: .init(ovulationWindow: "14 Oct – 19 Oct", ovulation: "18 Oct", temperatureDeviation: "+0.1", restingHeartRate: "56"),
                size: .large
            )
            .frame(width: 363, height: 363)
        }
        .padding(.spacing205x)
    }
    .background(Color.defaultBackground)
}
