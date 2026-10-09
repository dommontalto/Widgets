//
//  HealthWidgetLayoutV5.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import SwiftUI

// In alphabetical order of their row names, and every switch over them follows it.
enum HealthWidgetKindV5: String, CaseIterable, Codable, Hashable, Identifiable {
    case activity
    case heartRate
    case intake
    case macros
    case menstrual
    case sleep
    case water
    case weight

    var id: Self { self }

    var title: String {
        switch self {
        case .activity: "Total Energy"
        case .heartRate: "Heart Rate"
        case .intake: "Intake"
        case .macros: "Weekly Macros"
        case .menstrual: "Menstrual"
        case .sleep: "Sleep"
        case .water: "Water"
        case .weight: "Weight"
        }
    }

    // The shorter name it's listed under in the add sheet.
    var rowTitle: String {
        switch self {
        case .activity: "Activity"
        case .heartRate: "Heart"
        case .intake: "Intake"
        case .macros: "Macros"
        case .menstrual: "Menstrual"
        case .sleep: "Sleep"
        case .water: "Water"
        case .weight: "Weight"
        }
    }

    var systemImage: String {
        switch self {
        case .activity: "flame.fill"
        case .heartRate: "heart.fill"
        case .intake: "arrow.right"
        case .macros: "chart.pie.fill"
        case .menstrual: "moonphase.waxing.crescent"
        case .sleep: "bed.double.fill"
        case .water: "drop.fill"
        case .weight: "scalemass.fill"
        }
    }

    // The black-and-white icon its row shows in the add sheet.
    var rowIcon: String {
        switch self {
        case .activity: ImageNames.activityAlertsIconV5
        case .heartRate: ImageNames.heartDashIconV4
        case .intake: ImageNames.logFoodIconV1
        case .macros: ImageNames.macronutrientGraphV5
        case .menstrual: ImageNames.cycleTrackingMainV5
        case .sleep: ImageNames.sleepInfoV4
        case .water: ImageNames.waterIconV5
        case .weight: ImageNames.weightIconV4
        }
    }

    var tint: Color {
        switch self {
        case .activity: .defaultOrange
        case .heartRate: .defaultRed
        case .intake: .defaultGreen
        case .macros: .defaultGreen
        case .menstrual: .defaultPink
        case .sleep: .defaultBlue
        case .water: .defaultCyan
        case .weight: .defaultPurple
        }
    }

    var styles: [HealthWidgetStyleV5] {
        switch self {
        case .activity: [.totalEnergyBars, .activeEnergyBars, .stepBars]
        case .heartRate: [.heartLine, .heartNumber, .vo2Line, .vo2Number]
        case .intake: [.intakeBars, .intakeRing]
        case .macros: [.macroBars, .macroRings, .macroRing]
        case .menstrual: [.menstrualCycle]
        case .sleep: [.sleepRings, .sleepVitals, .sleepStages]
        case .water: [.waterBars, .waterNumber, .waterRing, .waterTank]
        case .weight: [.weightLine, .weightNumber]
        }
    }
}

enum HealthMacroV5: String, CaseIterable, Codable, Identifiable {
    case carbs
    case fats
    case protein

    var id: Self { self }

    var title: String {
        switch self {
        case .carbs: "Carbs"
        case .fats: "Fats"
        case .protein: "Protein"
        }
    }
}

// Counts across everything the add sheet can make, for the debug stats.
enum HealthWidgetCatalogV5 {
    // Each kind's designs, paired with it.
    static var designs: [(kind: HealthWidgetKindV5, style: HealthWidgetStyleV5)] {
        HealthWidgetKindV5.allCases.flatMap { kind in kind.styles.map { (kind, $0) } }
    }

    static var designCount: Int {
        designs.count
    }

    static var sizedCount: Int {
        designs.reduce(0) { $0 + $1.style.sizes.count }
    }

    static var optionCount: Int {
        designs.reduce(0) { $0 + options(of: $1.style) }
    }

    static func optionCount(of family: HealthWidgetStyleV5.Family) -> Int {
        designs.filter { $0.style.family == family }.reduce(0) { $0 + options(of: $1.style) }
    }

    // Every size, range and macro a design can be set to.
    private static func options(of style: HealthWidgetStyleV5) -> Int {
        style.sizes.count * max(style.ranges.count, 1) * (style == .macroRing ? HealthMacroV5.allCases.count : 1)
    }
}

// The alternative designs a kind can be shown as, swiped between in the add and edit sheets.
// Each belongs to one kind, named for what it shows, and grouped in the kinds' order;
// `family` says which widget draws it.
enum HealthWidgetStyleV5: String, CaseIterable, Codable, Hashable, Identifiable {
    // MARK: Activity
    case totalEnergyBars
    case activeEnergyBars
    case stepBars

    // MARK: Heart
    case heartLine
    case heartNumber
    case vo2Line
    case vo2Number

    // MARK: Intake
    case intakeBars
    case intakeRing

    // MARK: Macros
    case macroBars
    case macroRings
    case macroRing

    // MARK: Menstrual
    case menstrualCycle

    // MARK: Sleep
    case sleepRings
    case sleepVitals
    case sleepStages

    // MARK: Water
    case waterBars
    case waterNumber
    case waterRing
    case waterTank

    // MARK: Weight
    case weightLine
    case weightNumber

    // Which widget draws it, grouped as the widget folders are.
    enum Family: CaseIterable {
        // MARK: Reusable, in Shared/Widgets/V5
        case bar
        case dottedLine
        case dottedRange
        case line
        case number
        case ring

        // MARK: Features, in Shared/Widgets/V5/Features
        case menstrual
        case sleep
        case water

        var title: String {
            switch self {
            case .bar: "BrightBarChartWidgetV5"
            case .dottedLine: "BrightDottedLineChartWidgetV5"
            case .dottedRange: "BrightDottedRangeChartWidgetV5"
            case .line: "BrightLineChartWidgetV5"
            case .number: "BrightLeadingNumberWidgetV5"
            case .ring: "BrightRingGroupWidgetV5"
            case .menstrual: "BrightMenstrualWidgetV5"
            case .sleep: "BrightSleepWidgetV5"
            case .water: "BrightWaterWidgetV5"
            }
        }
    }

    var id: Self { self }

    var family: Family {
        switch self {
        case .totalEnergyBars, .activeEnergyBars, .stepBars: .bar
        case .heartLine: .line
        case .heartNumber: .number
        case .vo2Line: .dottedLine
        case .vo2Number: .number
        case .intakeBars: .bar
        case .intakeRing: .ring
        case .macroBars: .bar
        case .macroRings, .macroRing: .ring
        case .menstrualCycle: .menstrual
        case .sleepRings: .ring
        case .sleepVitals: .dottedRange
        case .sleepStages: .sleep
        case .waterBars: .bar
        case .waterNumber: .number
        case .waterRing: .ring
        case .waterTank: .water
        case .weightLine: .dottedLine
        case .weightNumber: .number
        }
    }

    var sizes: [BrightWidgetSizeV5] {
        switch self {
        case .heartNumber: [.small]
        case .vo2Line: [.medium]
        case .vo2Number: [.small]
        case .intakeRing: [.small]
        case .macroBars: [.medium, .large]
        case .macroRings: [.small, .medium]
        case .macroRing: [.small]
        case .sleepRings: [.small, .medium]
        case .sleepVitals: [.small, .medium]
        case .sleepStages: [.small, .medium]
        case .waterNumber: [.small]
        case .waterRing: [.small, .medium]
        case .weightLine: [.medium, .large]
        case .weightNumber: [.small]
        default: BrightWidgetSizeV5.allCases
        }
    }

    // The ranges it can be set to, the first being where it starts; always at least one.
    var ranges: [BrightWidgetRangeV5] {
        switch self {
        case .totalEnergyBars, .activeEnergyBars, .stepBars: [.today, .rolling12h, .week]
        case .heartLine: [.rolling1h, .rolling6h, .rolling12h, .fixed6h, .fixed12h]
        case .heartNumber: [.latest]
        case .vo2Line: [.lastReadings]
        case .vo2Number: [.latest]
        case .intakeBars: [.today, .rolling12h, .week]
        case .intakeRing: [.today]
        case .macroBars: [.week]
        case .macroRings, .macroRing: [.today]
        case .menstrualCycle: [.today]
        case .sleepRings, .sleepVitals, .sleepStages: [.lastNight]
        case .waterBars: [.today, .rolling12h, .week]
        case .waterNumber: [.latest]
        case .waterRing, .waterTank: [.today]
        case .weightLine: [.lastReadings]
        case .weightNumber: [.latest]
        }
    }
}

struct HealthWidgetItemV5: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: HealthWidgetKindV5
    var style = HealthWidgetStyleV5.heartLine
    var size: BrightWidgetSizeV5
    var range = BrightWidgetRangeV5.rolling1h
    var macro = HealthMacroV5.carbs

    init(
        kind: HealthWidgetKindV5,
        style: HealthWidgetStyleV5 = .heartLine,
        size: BrightWidgetSizeV5,
        range: BrightWidgetRangeV5? = nil
    ) {
        self.kind = kind
        self.size = size
        adopt(style)
        if let range, style.ranges.contains(range) {
            self.range = range
        }
    }

    // Switches style, falling back to its first size and first range where the current
    // ones aren't offered.
    mutating func adopt(_ style: HealthWidgetStyleV5) {
        self.style = style
        if !style.sizes.contains(size), let first = style.sizes.first {
            size = first
        }
        if !style.ranges.isEmpty, !style.ranges.contains(range), let first = style.ranges.first {
            range = first
        }
    }
}

struct HealthGridPositionV5: Equatable, Hashable {
    var row: Int
    var col: Int
}

// Shared by the grid and the size picker so a preview is drawn at the size it lands at.
enum HealthWidgetGridMetricsV5 {
    static let columns = 2
    static let spacing: CGFloat = .spacing205x

    static func cellSize(containerWidth: CGFloat) -> CGFloat {
        max((containerWidth - spacing * CGFloat(columns + 1)) / CGFloat(columns), 1)
    }

    static func frame(for size: BrightWidgetSizeV5, cellSize: CGFloat) -> CGSize {
        CGSize(width: span(size.columns, cellSize: cellSize), height: span(size.rows, cellSize: cellSize))
    }

    private static func span(_ cells: Int, cellSize: CGFloat) -> CGFloat {
        let count = CGFloat(cells)
        return cellSize * count + spacing * (count - 1)
    }

    static func origin(of position: HealthGridPositionV5, cellSize: CGFloat) -> CGPoint {
        let stride = cellSize + spacing
        return CGPoint(x: CGFloat(position.col) * stride + spacing, y: CGFloat(position.row) * stride + spacing)
    }
}

@Observable
final class HealthWidgetLayoutV5 {
    private(set) var widgets: [HealthWidgetItemV5]
    private(set) var positions: [UUID: HealthGridPositionV5] = [:]

    static let defaultWidgets: [HealthWidgetItemV5] = [
        HealthWidgetItemV5(kind: .activity, style: .totalEnergyBars, size: .small, range: .week),
        HealthWidgetItemV5(kind: .activity, style: .stepBars, size: .small),
        HealthWidgetItemV5(kind: .macros, style: .macroBars, size: .medium),
        HealthWidgetItemV5(kind: .heartRate, style: .heartLine, size: .medium),
        HealthWidgetItemV5(kind: .sleep, style: .sleepStages, size: .medium),
        HealthWidgetItemV5(kind: .sleep, style: .sleepVitals, size: .medium),
        HealthWidgetItemV5(kind: .water, style: .waterRing, size: .medium),
        HealthWidgetItemV5(kind: .weight, style: .weightLine, size: .large),
        HealthWidgetItemV5(kind: .menstrual, style: .menstrualCycle, size: .medium),
    ]

    init() {
        widgets = Self.loadSaved() ?? Self.defaultWidgets
        pack()
    }

    // MARK: - Editing

    func add(_ widget: HealthWidgetItemV5) {
        widgets.append(widget)
        commit()
    }

    // Replaces the grid with every kind and style that comes in this size, once for each
    // range and macro it offers, to check them all side by side.
    func showAll(_ size: BrightWidgetSizeV5) {
        showAll { _, widgetSize in widgetSize == size }
    }

    // The same, for every size of one family of widget, such as all the line charts.
    func showAll(_ family: HealthWidgetStyleV5.Family) {
        showAll { style, _ in style.family == family }
    }

    private func showAll(where includes: (HealthWidgetStyleV5, BrightWidgetSizeV5) -> Bool) {
        widgets = HealthWidgetKindV5.allCases.flatMap { kind in
            kind.styles.flatMap { style in
                style.sizes.filter { includes(style, $0) }.flatMap { size in
                    style.ranges.flatMap { range in
                        (style == .macroRing ? HealthMacroV5.allCases : [HealthMacroV5.carbs]).map { macro in
                            var widget = HealthWidgetItemV5(kind: kind, style: style, size: size)
                            widget.range = range
                            widget.macro = macro
                            return widget
                        }
                    }
                }
            }
        }
        commit()
    }

    func removeAll() {
        widgets.removeAll()
        commit()
    }

    // Every kind in every style at every size it comes in, for checking them all at once.
    func addAll() {
        for kind in HealthWidgetKindV5.allCases {
            for style in kind.styles {
                for size in style.sizes {
                    widgets.append(HealthWidgetItemV5(kind: kind, style: style, size: size))
                }
            }
        }
        commit()
    }

    func remove(id: UUID) {
        widgets.removeAll { $0.id == id }
        commit()
    }

    func update(_ widget: HealthWidgetItemV5) {
        guard let index = widgets.firstIndex(where: { $0.id == widget.id }) else { return }
        widgets[index] = widget
        commit()
    }

    func reset() {
        widgets = Self.defaultWidgets
        commit()
    }

    // Repacks around a widget held at `position` while it is being dragged.
    func preview(_ widget: HealthWidgetItemV5, at position: HealthGridPositionV5) {
        let lastRow = widgets
            .filter { $0.id != widget.id }
            .compactMap { other in positions[other.id].map { $0.row + other.size.rows } }
            .max() ?? 0
        let pinned = HealthGridPositionV5(
            row: min(max(position.row, 0), lastRow + 1),
            col: min(position.col, HealthWidgetGridMetricsV5.columns - widget.size.columns)
        )
        pack(pinning: (widget, pinned))
    }

    // Adopts the dragged arrangement as the new reading order.
    func commitDrag() {
        widgets.sort { lhs, rhs in
            guard let left = positions[lhs.id], let right = positions[rhs.id] else { return false }
            return (left.row, left.col) < (right.row, right.col)
        }
        save()
    }

    // MARK: - Geometry

    func cell(at point: CGPoint, cellSize: CGFloat) -> HealthGridPositionV5? {
        let spacing = HealthWidgetGridMetricsV5.spacing
        let stride = cellSize + spacing
        guard point.x >= 0, point.y >= 0 else { return nil }

        let row = Int(point.y / stride)
        let col = point.x < stride + spacing / 2 ? 0 : 1
        guard point.x < stride * CGFloat(HealthWidgetGridMetricsV5.columns) + spacing else { return nil }

        let cellTop = CGFloat(row) * stride + spacing
        guard point.y >= cellTop - spacing / 2, point.y <= cellTop + cellSize + spacing / 2 else { return nil }
        return HealthGridPositionV5(row: row, col: col)
    }

    func height(cellSize: CGFloat) -> CGFloat {
        let rows = widgets
            .compactMap { widget in positions[widget.id].map { $0.row + widget.size.rows } }
            .max() ?? 0
        return CGFloat(rows) * (cellSize + HealthWidgetGridMetricsV5.spacing) + HealthWidgetGridMetricsV5.spacing
    }

    // MARK: - Private

    private func commit() {
        pack()
        save()
    }

    // First-fit packing in reading order. A pinned widget claims its cells first
    // and everything else flows around it.
    private func pack(pinning pinned: (widget: HealthWidgetItemV5, position: HealthGridPositionV5)? = nil) {
        var occupancy = Occupancy()
        var placed: [UUID: HealthGridPositionV5] = [:]

        if let pinned {
            occupancy.mark(pinned.position, size: pinned.widget.size)
            placed[pinned.widget.id] = pinned.position
        }

        for widget in widgets where widget.id != pinned?.widget.id {
            let position = occupancy.firstFit(for: widget.size)
            occupancy.mark(position, size: widget.size)
            placed[widget.id] = position
        }

        positions = placed
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(widgets) else { return }
        UserDefaults.standard.set(data, forKey: Constants.storageKey)
    }

    private static func loadSaved() -> [HealthWidgetItemV5]? {
        guard let data = UserDefaults.standard.data(forKey: Constants.storageKey) else { return nil }
        return try? JSONDecoder().decode([HealthWidgetItemV5].self, from: data)
    }

    private struct Occupancy {
        private var rows: [[Bool]] = []

        mutating func firstFit(for size: BrightWidgetSizeV5) -> HealthGridPositionV5 {
            var row = 0
            while true {
                for col in 0 ... (HealthWidgetGridMetricsV5.columns - size.columns) {
                    let position = HealthGridPositionV5(row: row, col: col)
                    if isFree(position, size: size) {
                        return position
                    }
                }
                row += 1
            }
        }

        mutating func mark(_ position: HealthGridPositionV5, size: BrightWidgetSizeV5) {
            grow(to: position.row + size.rows)
            for row in position.row ..< position.row + size.rows {
                for col in position.col ..< position.col + size.columns {
                    rows[row][col] = true
                }
            }
        }

        private mutating func isFree(_ position: HealthGridPositionV5, size: BrightWidgetSizeV5) -> Bool {
            grow(to: position.row + size.rows)
            for row in position.row ..< position.row + size.rows {
                for col in position.col ..< position.col + size.columns where rows[row][col] {
                    return false
                }
            }
            return true
        }

        private mutating func grow(to count: Int) {
            while rows.count < count {
                rows.append(Array(repeating: false, count: HealthWidgetGridMetricsV5.columns))
            }
        }
    }

    private enum Constants {
        static let storageKey = "healthWidgetLayoutV5"
    }
}
