//
//  ExerciseProgramPhaseWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 22/7/2026.
//

import SwiftUI

struct ExerciseProgramPhase {
    struct Block: Identifiable {
        let id = UUID()
        let name: String
        let weeks: Int
        var kind: ExerciseBlockKind = .normal

        static func deload(weeks: Int = 1) -> Block {
            Block(name: "", weeks: weeks, kind: .deload)
        }
    }

    let startDate: Date
    let periodName: String
    let blocks: [Block]

    var totalWeeks: Int { blocks.reduce(0) { $0 + $1.weeks } }

    func elapsedDays(on date: Date) -> Int {
        let start = Calendar.current.startOfDay(for: startDate)
        let days = Calendar.current.dateComponents([.day], from: start, to: date).day ?? 0
        return min(max(days, 0), totalWeeks * 7)
    }

    func currentWeek(on date: Date) -> Int {
        min(elapsedDays(on: date) / 7 + 1, totalWeeks)
    }

    func progress(on date: Date) -> Double {
        guard totalWeeks > 0 else { return 0 }
        return Double(elapsedDays(on: date)) / Double(totalWeeks * 7)
    }

    static let demo = ExerciseProgramPhase(
        startDate: Calendar.current.date(byAdding: .day, value: -38, to: .now) ?? .now,
        periodName: "Pre-season",
        blocks: [
            Block(name: "Base", weeks: 6),
            .deload(),
            Block(name: "Build", weeks: 6),
            .deload(),
            Block(name: "Peak", weeks: 4),
            Block(name: "Taper", weeks: 3),
            .deload(),
            Block(name: "Race", weeks: 2),
            Block(name: "Off", weeks: 3),
        ]
    )
}

struct ExerciseProgramPhaseWidget: View {
    var phase: ExerciseProgramPhase?
    var onCreate: () -> Void = {}

    private let calendar = Calendar.current
    private let today = Calendar.current.startOfDay(for: .now)

    @State private var position = ScrollPosition(point: CGPoint(x: Constants.initialOffset, y: 0))
    @State private var scrolledWeeks = 0
    @State private var showingProgram = false

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing5x) {
            header
                .padding(.horizontal, .spacing3x)

            timeline
        }
        .padding(.top, .spacing3x)
        .padding(.bottom, phase == nil ? .spacing3x : .spacing0x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
        .sheet(isPresented: $showingProgram) {
            ExerciseCreateProgramSheet(startsAtBlocks: true)
        }
    }

    // MARK: - Header

    private var progress: CGFloat {
        CGFloat(phase?.progress(on: today) ?? 0)
    }

    private var header: some View {
        HStack(spacing: .spacing105x) {
            ExerciseProgressRing(fraction: progress)

            HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
                BrightText(weeksLabel, size: .standout2)
                    .monospacedDigit()
                BrightText("weeks", size: .body1, color: .lightTextColor)
            }
            .padding(.leading, .spacing1x)

            Spacer(minLength: .spacing0x)
        }
        .overlay(alignment: .topTrailing) {
            if phase != nil {
                BrightRoundButton(
                    systemImage: "arrow.up.left.and.arrow.down.right",
                    size: .medium
                ) {
                    showingProgram = true
                }
            }
        }
    }

    private var weeksLabel: String {
        guard let phase else { return "-" }
        return "\(phase.currentWeek(on: today))/\(phase.totalWeeks)"
    }

    // MARK: - Timeline

    private var timeline: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing0x) {
                monthLabels
                    .frame(height: Constants.monthLabelHeight)

                ticks
                    .frame(height: Constants.majorTickHeight)
                    .padding(.top, .spacing105x)

                if let phase {
                    phaseRows(phase)
                        .padding(.top, .spacing4x)
                } else {
                    createBand
                        .padding(.top, .spacing8x)
                        .padding(.bottom, .spacing4x)
                }
            }
            .frame(width: width(days: Constants.daysBefore + Constants.daysAfter), alignment: .leading)
            .background(alignment: .topLeading) { monthLines }
            .overlay(alignment: .topLeading) { todayMarker }
            .padding(.bottom, phase == nil ? .spacing0x : .spacing4x)
        }
        .scrollPosition($position)
        .scrollDisabled(phase == nil)
        .onScrollGeometryChange(for: Int.self) { geometry in
            Int((geometry.contentOffset.x / width(days: 7)).rounded())
        } action: { _, weeks in
            scrolledWeeks = weeks
        }
        .brightHaptic(.soft, trigger: scrolledWeeks)
        .overlay(alignment: .trailing) { trailingFade }
    }

    private func x(for date: Date) -> CGFloat {
        let days = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: date)).day ?? 0
        return width(days: Constants.daysBefore + days)
    }

    private func width(days: Int) -> CGFloat {
        CGFloat(days) * Constants.dayWidth
    }

    private var monthStarts: [Date] {
        guard let first = calendar.date(byAdding: .day, value: -Constants.daysBefore, to: today),
              let firstMonth = calendar.dateInterval(of: .month, for: first)?.start,
              let last = calendar.date(byAdding: .day, value: Constants.daysAfter, to: today)
        else { return [] }
        var months = [firstMonth]
        while let next = calendar.date(byAdding: .month, value: 1, to: months[months.count - 1]), next <= last {
            months.append(next)
        }
        return months
    }

    private var monthLabels: some View {
        ZStack(alignment: .leading) {
            ForEach(monthStarts, id: \.self) { month in
                BrightText(month.formatted(.brightMonth).uppercased(), size: .body1)
                    .offset(x: x(for: month) + .spacing1x)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var monthLines: some View {
        Canvas { context, size in
            for month in monthStarts {
                let lineX = x(for: month)
                var path = Path()
                path.move(to: CGPoint(x: lineX, y: 0))
                path.addLine(to: CGPoint(x: lineX, y: size.height))
                context.stroke(path, with: .color(.textColor.opacity(.veryMinimalOpacity)), lineWidth: Constants.strokeWidth)
            }
        }
        .frame(height: monthLineHeight)
    }

    private var monthLineHeight: CGFloat {
        phase == nil ? Constants.emptyMonthLineHeight : Constants.monthLineHeight
    }

    private var ticks: some View {
        Canvas { context, size in
            for day in -Constants.daysBefore...Constants.daysAfter {
                guard let date = calendar.date(byAdding: .day, value: day, to: today) else { continue }
                let tickX = x(for: date)
                let isMajor = calendar.component(.weekday, from: date) == calendar.firstWeekday
                let height = isMajor ? Constants.majorTickHeight : Constants.minorTickHeight
                var path = Path()
                path.move(to: CGPoint(x: tickX, y: (size.height - height) / 2))
                path.addLine(to: CGPoint(x: tickX, y: (size.height + height) / 2))
                let color: Color = if day == 0 {
                    .textColor
                } else if day < 0 {
                    .textColor.opacity(.ultraLowOpacity)
                } else {
                    .textColor.opacity(.minimalOpacity)
                }
                context.stroke(path, with: .color(color), lineWidth: Constants.strokeWidth)
            }
        }
    }

    private func phaseRows(_ phase: ExerciseProgramPhase) -> some View {
        let start = x(for: phase.startDate)
        let blockWidths = phase.blocks.map { blockWidth($0) }
        let blocksWidth = blockWidths.reduce(0, +) + .spacing105x * CGFloat(max(0, blockWidths.count - 1))

        return VStack(alignment: .leading, spacing: .spacing3x) {
            bar(
                name: phase.periodName,
                detail: durationLabel(weeks: phase.totalWeeks),
                color: .defaultGreen,
                width: max(width(days: phase.totalWeeks * 7), blocksWidth)
            )
            .padding(.leading, start)

            HStack(spacing: .spacing105x) {
                ForEach(Array(zip(phase.blocks, blockWidths)), id: \.0.id) { block, barWidth in
                    if block.kind == .normal {
                        bar(
                            name: block.name,
                            detail: durationLabel(weeks: block.weeks),
                            color: .defaultSkyBlue,
                            width: barWidth
                        )
                    } else {
                        deloadBar(width: barWidth)
                    }
                }
            }
            .padding(.leading, start)

            datePill
                .padding(.top, .spacing3x)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // A block's label sets a floor its own weeks may not reach, so the period
    // spans at least the row it holds.
    private func durationLabel(weeks: Int) -> String {
        weeks == 1 ? "1 week" : "\(weeks) weeks"
    }

    private func blockWidth(_ block: ExerciseProgramPhase.Block) -> CGFloat {
        let span = width(days: block.weeks * 7) - .spacing105x
        return max(block.kind == .normal ? Constants.minBlockWidth : Constants.minDeloadWidth, span)
    }

    private func bar(name: String, detail: String, color: Color, width: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous)
        // The span sets the width, so a short period drops its duration and
        // then its name rather than crushing them.
        return ViewThatFits(in: .horizontal) {
            barLabel(name: "\(name.uppercased()):", detail: detail, color: color)
            barLabel(name: name.uppercased(), detail: nil, color: color)
            Color.clear.frame(width: .spacing0x)
        }
        .padding(.horizontal, .spacing105x)
        .frame(width: width, height: Constants.barHeight, alignment: .leading)
        .background(color.opacity(.veryMinimalOpacity), in: shape)
        .overlay(shape.strokeBorder(color.opacity(.semiLowOpacity), lineWidth: Constants.strokeWidth))
    }

    private func barLabel(name: String, detail: String?, color: Color) -> some View {
        HStack(spacing: .spacing1x) {
            BrightText(name, size: .body1, color: color, weight: .regular)

            if let detail {
                BrightText(detail, size: .body1, color: color.opacity(.lowOpacity))
            }
        }
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }

    private func deloadBar(width: CGFloat) -> some View {
        ExerciseDiagonalStripes(spacing: Constants.hatchSpacing)
            .stroke(Color.textColor.opacity(.minimalOpacity), lineWidth: Constants.strokeWidth)
            .frame(width: width, height: Constants.barHeight)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous))
    }

    private var datePill: some View {
        BrightText("\(today.formatted(.brightWeekday)), \(today.formatted(.brightDay))", size: .body1, weight: .regular)
            .padding(.horizontal, .spacing105x)
            .frame(height: Constants.pillHeight)
            .modifier(GlassEffect(shape: .capsule))
            .frame(width: x(for: today) * 2)
    }

    private var createBand: some View {
        HStack(spacing: .spacing2x) {
            BrightText("Create a program", size: .body1, weight: .regular)
            BrightRoundButton(systemImage: "play.fill", size: .medium, onTapCallback: onCreate)
        }
        .padding(.leading, x(for: today) + Constants.createLabelInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, .spacing205x)
        .background(Color.defaultGreen.opacity(.finalBossLowOpacity))
        .overlay(alignment: .top) { bandEdge }
        .overlay(alignment: .bottom) { bandEdge }
    }

    private var bandEdge: some View {
        Color.defaultGreen.opacity(.lowOpacity)
            .frame(height: Constants.hairline)
    }

    // The marker runs from just above the first bar to just below the last,
    // so its span depends on which rows the state shows.
    private var todayMarker: some View {
        let rowsTop = Constants.monthLabelHeight + .spacing105x + Constants.majorTickHeight
        let top: CGFloat
        let height: CGFloat
        if phase == nil {
            top = rowsTop + .spacing8x - .spacing4x
            height = Constants.bandHeight + .spacing8x
        } else {
            top = rowsTop + .spacing4x - .spacing3x
            height = Constants.barHeight * 2 + .spacing3x + .spacing3x + .spacing4x
        }

        return VStack(spacing: .spacing05x) {
            markerCap(pointsUp: false)
            Rectangle()
                .fill(Color.textColor.opacity(.lowOpacity))
                .frame(width: Constants.strokeWidth)
            markerCap(pointsUp: true)
        }
        .frame(width: Constants.triangleSize, height: height)
        .offset(x: x(for: today) - Constants.triangleSize / 2, y: top)
    }

    private func markerCap(pointsUp: Bool) -> some View {
        RoundedTriangle()
            .fill(Color.textColor.opacity(.ultraLowOpacity))
            .overlay {
                RoundedTriangle()
                    .strokeBorder(Color.textColor.opacity(.lowOpacity), lineWidth: Constants.strokeWidth)
            }
            .frame(width: Constants.triangleWidth, height: Constants.triangleSize)
            .rotationEffect(.degrees(pointsUp ? 0 : 180))
    }

    private var trailingFade: some View {
        LinearGradient(
            colors: [.defaultCards.opacity(0), .defaultCards],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: .spacing6x)
        .allowsHitTesting(false)
    }

    private enum Constants {
        static let todayX: CGFloat = 84
        // Holds the create label just clear of today's marker, so it stays put
        // whatever the day scale is.
        static let createLabelInset: CGFloat = .spacing4x
        static let dayWidth: CGFloat = 8
        static let emptyMonthDays = 365
        static let daysBefore = 60 + emptyMonthDays
        static let daysAfter = 120 + emptyMonthDays
        // Lands today at todayX on first show.
        static let initialOffset = CGFloat(daysBefore) * dayWidth - todayX
        static let monthLabelHeight: CGFloat = 18
        static let monthLineHeight: CGFloat = 223
        static let emptyMonthLineHeight: CGFloat = 184
        static let majorTickHeight: CGFloat = 16
        static let minorTickHeight: CGFloat = 9
        static let barHeight: CGFloat = .spacing6x
        // A short block's own span is narrower than its name and duration read,
        // so the blue bars grow past their weeks rather than truncate.
        static let minBlockWidth: CGFloat = 138
        static let minDeloadWidth: CGFloat = .spacing6x
        static let bandHeight: CGFloat = .spacing6x + .spacing205x * 2
        static let pillHeight: CGFloat = .spacing5x
        static let triangleSize: CGFloat = .spacing2x
        // The design's polygon is wider than it is tall.
        static let triangleWidth: CGFloat = 13
        static let strokeWidth: CGFloat = 1
        static let hairline: CGFloat = 0.5
        static let hatchSpacing: CGFloat = 4
    }
}

private struct RoundedTriangle: InsettableShape {
    var insetAmount: CGFloat = 0

    // The corner-rounded polygon from the design, normalised to its own box: an
    // equilateral triangle whose corners round at radius 3 of its 12pt height.
    func path(in rect: CGRect) -> Path {
        let box = rect.insetBy(dx: insetAmount, dy: insetAmount)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: box.minX + x * box.width, y: box.minY + y * box.height)
        }

        var path = Path()
        path.move(to: point(0.2992, 0.125))
        path.addCurve(
            to: point(0.7008, 0.125),
            control1: point(0.3884, -0.0417),
            control2: point(0.6116, -0.0417)
        )
        path.addLine(to: point(0.9686, 0.625))
        path.addCurve(
            to: point(0.7678, 1),
            control1: point(1.0578, 0.7917),
            control2: point(0.9463, 1)
        )
        path.addLine(to: point(0.2322, 1))
        path.addCurve(
            to: point(0.0314, 0.625),
            control1: point(0.0537, 1),
            control2: point(-0.0578, 0.7917)
        )
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> RoundedTriangle {
        RoundedTriangle(insetAmount: insetAmount + amount)
    }
}

#Preview {
    VStack(spacing: .spacing3x) {
        ExerciseProgramPhaseWidget()
        ExerciseProgramPhaseWidget(phase: .demo)
    }
    .padding(.spacing3x)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.defaultBackground.ignoresSafeArea())
}
