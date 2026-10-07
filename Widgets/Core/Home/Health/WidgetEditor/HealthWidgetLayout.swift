//
//  HealthWidgetLayout.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import SwiftUI

enum HealthWidgetKind: String, CaseIterable, Codable, Hashable, Identifiable {
    case heartRate

    var id: Self { self }

    var title: String {
        switch self {
        case .heartRate: "Heart Rate"
        }
    }

    var systemImage: String {
        switch self {
        case .heartRate: "heart.fill"
        }
    }

    var tint: Color {
        switch self {
        case .heartRate: .defaultRed
        }
    }

    var styles: [HealthWidgetStyle] {
        switch self {
        case .heartRate: HealthWidgetStyle.allCases
        }
    }
}

// The alternative designs a kind can be shown as, swiped between in the add and edit sheets.
enum HealthWidgetStyle: String, CaseIterable, Codable, Hashable, Identifiable {
    case lineChart
    case leadingNumber

    var id: Self { self }

    var sizes: [BrightWidgetSizeV5] {
        switch self {
        case .lineChart: BrightWidgetSizeV5.allCases
        case .leadingNumber: [.small, .medium]
        }
    }

    var hasWindow: Bool {
        self == .lineChart
    }
}

struct HealthWidgetItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: HealthWidgetKind
    var style = HealthWidgetStyle.lineChart
    var size: BrightWidgetSizeV5
    var window = BrightLineChartWidgetV5.Window.rolling1h
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
