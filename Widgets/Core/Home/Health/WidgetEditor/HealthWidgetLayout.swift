//
//  HealthWidgetLayout.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import SwiftUI

enum HealthWidgetKind: String, CaseIterable, Codable, Hashable, Identifiable {
    case heartRate
    case intake
    case macros
    case activity
    case sleep
    case hydration
    case weight

    var id: Self { self }

    var title: String {
        switch self {
        case .heartRate: "Heart Rate"
        case .intake: "Intake"
        case .macros: "Weekly Macros"
        case .activity: "Total Energy"
        case .sleep: "Sleep"
        case .hydration: "Water"
        case .weight: "Weight"
        }
    }

    // The shorter name it's listed under in the add sheet.
    var rowTitle: String {
        switch self {
        case .heartRate: "Heart"
        case .intake: "Intake"
        case .macros: "Macros"
        case .activity: "Activity"
        case .sleep: "Sleep"
        case .hydration: "Hydration"
        case .weight: "Weight"
        }
    }

    var systemImage: String {
        switch self {
        case .heartRate: "heart.fill"
        case .intake: "arrow.right"
        case .macros: "chart.pie.fill"
        case .activity: "flame.fill"
        case .sleep: "bed.double.fill"
        case .hydration: "drop.fill"
        case .weight: "scalemass.fill"
        }
    }

    // The black-and-white icon its row shows in the add sheet.
    var rowIcon: String {
        switch self {
        case .heartRate: ImageNames.heartDashIconV4
        case .intake: ImageNames.logFoodIconV1
        case .macros: ImageNames.macronutrientGraphV5
        case .activity: ImageNames.activityAlertsIconV5
        case .sleep: ImageNames.sleepInfoV4
        case .hydration: ImageNames.waterIconV5
        case .weight: ImageNames.weightIconV4
        }
    }

    var tint: Color {
        switch self {
        case .heartRate: .defaultRed
        case .intake: .defaultGreen
        case .macros: .defaultGreen
        case .activity: .defaultOrange
        case .sleep: .defaultBlue
        case .hydration: .defaultCyan
        case .weight: .defaultPurple
        }
    }

    var styles: [HealthWidgetStyle] {
        switch self {
        case .heartRate: [.lineChart, .leadingNumber, .vo2Line, .vo2Number]
        case .intake: [.bars, .intakeRing]
        case .macros: [.macroBars, .macroRings, .macroRing]
        case .sleep: [.sleepRings]
        case .hydration: [.bars, .leadingNumber]
        case .weight: [.dottedLine, .leadingNumber]
        case .activity: [.bars, .activeEnergyBars, .stepBars]
        }
    }
}

enum HealthMacro: String, CaseIterable, Codable, Identifiable {
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
enum HealthWidgetCatalog {
    // Each kind's designs, paired with it.
    static var designs: [(kind: HealthWidgetKind, style: HealthWidgetStyle)] {
        HealthWidgetKind.allCases.flatMap { kind in kind.styles.map { (kind, $0) } }
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

    static func optionCount(of family: HealthWidgetStyle.Family) -> Int {
        designs.filter { $0.style.family == family }.reduce(0) { $0 + options(of: $1.style) }
    }

    // Every size, range and macro a design can be set to.
    private static func options(of style: HealthWidgetStyle) -> Int {
        style.sizes.count * max(style.ranges.count, 1) * (style == .macroRing ? HealthMacro.allCases.count : 1)
    }
}

// The alternative designs a kind can be shown as, swiped between in the add and edit sheets.
enum HealthWidgetStyle: String, CaseIterable, Codable, Hashable, Identifiable {
    case lineChart
    case leadingNumber
    // The kind's main measure as bars: intake, or total energy for activity.
    case bars
    case activeEnergyBars
    case stepBars
    case macroBars
    case macroRings
    // One macro on its own, picked in the sheet.
    case macroRing
    case intakeRing
    case sleepRings
    case dottedLine
    // VO2 Max as a dotted line, which only comes in medium.
    case vo2Line
    // VO2 Max's latest reading, alongside heart rate's own number.
    case vo2Number

    // Which shared widget draws it.
    enum Family: CaseIterable {
        case line
        case dottedLine
        case bar
        case number
        case ring

        var title: String {
            switch self {
            case .line: "BrightLineChartWidgetV5"
            case .dottedLine: "BrightDottedLineChartWidgetV5"
            case .bar: "BrightBarChartWidgetV5"
            case .number: "BrightLeadingNumberWidgetV5"
            case .ring: "BrightRingGroupWidgetV5"
            }
        }
    }

    var id: Self { self }

    var family: Family {
        switch self {
        case .lineChart: .line
        case .bars, .activeEnergyBars, .stepBars, .macroBars: .bar
        case .leadingNumber, .vo2Number: .number
        case .macroRings, .macroRing, .intakeRing, .sleepRings: .ring
        case .dottedLine, .vo2Line: .dottedLine
        }
    }

    var sizes: [BrightWidgetSizeV5] {
        switch self {
        case .leadingNumber, .vo2Number: [.small]
        case .macroBars: [.medium, .large]
        case .macroRings: [.small, .medium]
        case .macroRing, .intakeRing: [.small]
        case .sleepRings: [.small, .medium]
        case .dottedLine: [.medium, .large]
        case .vo2Line: [.medium]
        default: BrightWidgetSizeV5.allCases
        }
    }

    // The ranges it can be set to, the first being where it starts; always at least one.
    var ranges: [BrightWidgetRangeV5] {
        switch self {
        case .lineChart: [.rolling1h, .rolling6h, .rolling12h, .fixed6h, .fixed12h]
        case .leadingNumber, .vo2Number: [.latest]
        case .bars, .activeEnergyBars, .stepBars: [.today, .rolling12h, .week]
        case .macroBars: [.week]
        case .macroRings, .macroRing, .intakeRing: [.today]
        case .sleepRings: [.lastNight]
        case .dottedLine, .vo2Line: [.twoWeeks]
        }
    }
}

struct HealthWidgetItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: HealthWidgetKind
    var style = HealthWidgetStyle.lineChart
    var size: BrightWidgetSizeV5
    var range = BrightWidgetRangeV5.rolling1h
    var macro = HealthMacro.carbs

    init(kind: HealthWidgetKind, style: HealthWidgetStyle = .lineChart, size: BrightWidgetSizeV5) {
        self.kind = kind
        self.size = size
        adopt(style)
    }

    // Switches style, falling back to its first size and first range where the current
    // ones aren't offered.
    mutating func adopt(_ style: HealthWidgetStyle) {
        self.style = style
        if !style.sizes.contains(size), let first = style.sizes.first {
            size = first
        }
        if !style.ranges.isEmpty, !style.ranges.contains(range), let first = style.ranges.first {
            range = first
        }
    }
}

struct HealthGridPosition: Equatable, Hashable {
    var row: Int
    var col: Int
}

// Shared by the grid and the size picker so a preview is drawn at the size it lands at.
enum HealthWidgetGridMetrics {
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

    static func origin(of position: HealthGridPosition, cellSize: CGFloat) -> CGPoint {
        let stride = cellSize + spacing
        return CGPoint(x: CGFloat(position.col) * stride + spacing, y: CGFloat(position.row) * stride + spacing)
    }
}

@Observable
final class HealthWidgetLayout {
    private(set) var widgets: [HealthWidgetItem]
    private(set) var positions: [UUID: HealthGridPosition] = [:]

    static let defaultWidgets: [HealthWidgetItem] = [
        HealthWidgetItem(kind: .heartRate, size: .small),
        HealthWidgetItem(kind: .heartRate, size: .medium),
        HealthWidgetItem(kind: .heartRate, size: .large),
    ]

    init() {
        widgets = Self.loadSaved() ?? Self.defaultWidgets
        pack()
    }

    // MARK: - Editing

    func add(_ widget: HealthWidgetItem) {
        widgets.append(widget)
        commit()
    }

    // Replaces the grid with every kind and style that comes in this size, once for each
    // range and macro it offers, to check them all side by side.
    func showAll(_ size: BrightWidgetSizeV5) {
        showAll { _, widgetSize in widgetSize == size }
    }

    // The same, for every size of one family of widget, such as all the line charts.
    func showAll(_ family: HealthWidgetStyle.Family) {
        showAll { style, _ in style.family == family }
    }

    private func showAll(where includes: (HealthWidgetStyle, BrightWidgetSizeV5) -> Bool) {
        widgets = HealthWidgetKind.allCases.flatMap { kind in
            kind.styles.flatMap { style in
                style.sizes.filter { includes(style, $0) }.flatMap { size in
                    style.ranges.flatMap { range in
                        (style == .macroRing ? HealthMacro.allCases : [HealthMacro.carbs]).map { macro in
                            var widget = HealthWidgetItem(kind: kind, style: style, size: size)
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
        for kind in HealthWidgetKind.allCases {
            for style in kind.styles {
                for size in style.sizes {
                    widgets.append(HealthWidgetItem(kind: kind, style: style, size: size))
                }
            }
        }
        commit()
    }

    func remove(id: UUID) {
        widgets.removeAll { $0.id == id }
        commit()
    }

    func update(_ widget: HealthWidgetItem) {
        guard let index = widgets.firstIndex(where: { $0.id == widget.id }) else { return }
        widgets[index] = widget
        commit()
    }

    func reset() {
        widgets = Self.defaultWidgets
        commit()
    }

    // Repacks around a widget held at `position` while it is being dragged.
    func preview(_ widget: HealthWidgetItem, at position: HealthGridPosition) {
        let lastRow = widgets
            .filter { $0.id != widget.id }
            .compactMap { other in positions[other.id].map { $0.row + other.size.rows } }
            .max() ?? 0
        let pinned = HealthGridPosition(
            row: min(max(position.row, 0), lastRow + 1),
            col: min(position.col, HealthWidgetGridMetrics.columns - widget.size.columns)
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

    func cell(at point: CGPoint, cellSize: CGFloat) -> HealthGridPosition? {
        let spacing = HealthWidgetGridMetrics.spacing
        let stride = cellSize + spacing
        guard point.x >= 0, point.y >= 0 else { return nil }

        let row = Int(point.y / stride)
        let col = point.x < stride + spacing / 2 ? 0 : 1
        guard point.x < stride * CGFloat(HealthWidgetGridMetrics.columns) + spacing else { return nil }

        let cellTop = CGFloat(row) * stride + spacing
        guard point.y >= cellTop - spacing / 2, point.y <= cellTop + cellSize + spacing / 2 else { return nil }
        return HealthGridPosition(row: row, col: col)
    }

    func height(cellSize: CGFloat) -> CGFloat {
        let rows = widgets
            .compactMap { widget in positions[widget.id].map { $0.row + widget.size.rows } }
            .max() ?? 0
        return CGFloat(rows) * (cellSize + HealthWidgetGridMetrics.spacing) + HealthWidgetGridMetrics.spacing
    }

    // MARK: - Private

    private func commit() {
        pack()
        save()
    }

    // First-fit packing in reading order. A pinned widget claims its cells first
    // and everything else flows around it.
    private func pack(pinning pinned: (widget: HealthWidgetItem, position: HealthGridPosition)? = nil) {
        var occupancy = Occupancy()
        var placed: [UUID: HealthGridPosition] = [:]

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

    private static func loadSaved() -> [HealthWidgetItem]? {
        guard let data = UserDefaults.standard.data(forKey: Constants.storageKey) else { return nil }
        return try? JSONDecoder().decode([HealthWidgetItem].self, from: data)
    }

    private struct Occupancy {
        private var rows: [[Bool]] = []

        mutating func firstFit(for size: BrightWidgetSizeV5) -> HealthGridPosition {
            var row = 0
            while true {
                for col in 0 ... (HealthWidgetGridMetrics.columns - size.columns) {
                    let position = HealthGridPosition(row: row, col: col)
                    if isFree(position, size: size) {
                        return position
                    }
                }
                row += 1
            }
        }

        mutating func mark(_ position: HealthGridPosition, size: BrightWidgetSizeV5) {
            grow(to: position.row + size.rows)
            for row in position.row ..< position.row + size.rows {
                for col in position.col ..< position.col + size.columns {
                    rows[row][col] = true
                }
            }
        }

        private mutating func isFree(_ position: HealthGridPosition, size: BrightWidgetSizeV5) -> Bool {
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
                rows.append(Array(repeating: false, count: HealthWidgetGridMetrics.columns))
            }
        }
    }

    private enum Constants {
        static let storageKey = "healthWidgetLayout"
    }
}
