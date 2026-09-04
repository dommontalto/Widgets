//
//  ExerciseConsistencySheet.swift
//  Widgets
//
//  Created by Dom Montalto on 26/8/2026.
//

import SwiftUI

enum ExerciseConsistencyMode: Int, CaseIterable {
    case strength
    case cardio
    case combined

    var title: String {
        switch self {
        case .strength: "Strength"
        case .cardio: "Cardio"
        case .combined: "Strength & Cardio"
        }
    }

    var shortTitle: String {
        switch self {
        case .strength: "Strength"
        case .cardio: "Cardio"
        case .combined: "Both"
        }
    }

    var keyItems: [(title: String, fill: AnyShapeStyle)] {
        switch self {
        case .strength:
            [("Strength", AnyShapeStyle(Color.defaultPurplePink)),
             ("Rest", AnyShapeStyle(Color.textColor.opacity(.ultraLowOpacity)))]
        case .cardio:
            [("Cardio", AnyShapeStyle(Color.defaultSkyBlueCyan)),
             ("Rest", AnyShapeStyle(Color.textColor.opacity(.ultraLowOpacity)))]
        case .combined:
            [("Strength", AnyShapeStyle(Color.defaultPurplePink)),
             ("Cardio", AnyShapeStyle(Color.defaultSkyBlueCyan)),
             ("Both", AnyShapeStyle(ExerciseDayType.bothGradient)),
             ("Rest", AnyShapeStyle(Color.textColor.opacity(.ultraLowOpacity)))]
        }
    }

    func fill(for type: ExerciseDayType?) -> AnyShapeStyle {
        guard let type else { return AnyShapeStyle(Color.clear) }
        switch self {
        case .strength:
            return type == .strength || type == .both
                ? AnyShapeStyle(Color.defaultPurplePink)
                : AnyShapeStyle(Color.textColor.opacity(.ultraLowOpacity))
        case .cardio:
            return type == .cardio || type == .both
                ? AnyShapeStyle(Color.defaultSkyBlueCyan)
                : AnyShapeStyle(Color.textColor.opacity(.ultraLowOpacity))
        case .combined:
            switch type {
            case .strength: return AnyShapeStyle(Color.defaultPurplePink)
            case .cardio: return AnyShapeStyle(Color.defaultSkyBlueCyan)
            case .both: return AnyShapeStyle(ExerciseDayType.bothGradient)
            case .rest: return AnyShapeStyle(Color.textColor.opacity(.ultraLowOpacity))
            }
        }
    }
}

struct ExerciseConsistencySheet: View {
    @State private var mode: ExerciseConsistencyMode

    @State private var months = ExerciseDemoData.consistencyYear()

    @State private var gridWidth: CGFloat = 0

    init(mode: ExerciseConsistencyMode = .combined) {
        _mode = State(initialValue: mode)
    }

    var body: some View {
        BrightPageSheetView(title: "Consistency") {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing3x) {
                    header
                    modePicker
                    grid

                    Rectangle()
                        .fill(Color.textColor.opacity(.ultraLowOpacity))
                        .frame(height: 1)

                    key
                }
                .padding(.vertical, .spacing3x)
            }
            .scrollIndicators(.hidden)
        }
        .animation(.brightEaseInOut, value: mode)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            BrightText("Last 12 months", size: .body1)
            BrightText(mode.title, size: .body2, color: .lightTextColor)
        }
    }

    private var modePicker: some View {
        HStack(spacing: .spacing2x) {
            ForEach(ExerciseConsistencyMode.allCases, id: \.rawValue) { option in
                BrightTag(title: option.shortTitle, isSelected: option == mode) {
                    mode = option
                }
            }
        }
    }

    private var grid: some View {
        VStack(alignment: .leading, spacing: .spacing4x) {
            ForEach(monthRows.indices, id: \.self) { row in
                HStack(alignment: .top, spacing: Constants.columnGap) {
                    ForEach(monthRows[row].indices, id: \.self) { column in
                        monthTile(monthRows[row][column])
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { gridWidth = $0 }
    }

    private func monthTile(_ month: ExerciseMonthData) -> some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            BrightText(month.name, size: .body1, color: .semiLightTextColor)

            HStack(spacing: Constants.cellSpacing) {
                ForEach(month.columns.indices, id: \.self) { column in
                    VStack(spacing: Constants.cellSpacing) {
                        ForEach(0..<7, id: \.self) { row in
                            Circle()
                                .fill(mode.fill(for: month.columns[column][row]))
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
        .frame(width: tileWidth, alignment: .leading)
    }

    private var key: some View {
        FlowLayout(spacing: .spacing2x) {
            ForEach(mode.keyItems, id: \.title) { item in
                HStack(spacing: .spacing1x) {
                    Circle()
                        .fill(item.fill)
                        .frame(width: Constants.keySwatchSize, height: Constants.keySwatchSize)

                    BrightText(item.title, size: .body3, color: .lightTextColor)
                }
            }
        }
    }

    // MARK: - Derived state

    private var monthRows: [[ExerciseMonthData]] {
        stride(from: 0, to: months.count, by: Constants.columnsPerRow).map { start in
            Array(months[start..<min(start + Constants.columnsPerRow, months.count)])
        }
    }

    private var tileWidth: CGFloat {
        guard gridWidth > 0 else { return 0 }
        let gaps = CGFloat(Constants.columnsPerRow - 1) * Constants.columnGap
        return (gridWidth - gaps) / CGFloat(Constants.columnsPerRow)
    }

    // Every month is sized for six week columns, so a five-column February's
    // cells still match the rest of the grid.
    private var cellSize: CGFloat {
        guard tileWidth > 0 else { return 12 }
        let gaps = CGFloat(Constants.maxWeekColumns - 1) * Constants.cellSpacing
        return (tileWidth - gaps) / CGFloat(Constants.maxWeekColumns)
    }

    private enum Constants {
        static let columnsPerRow = 3
        static let maxWeekColumns = 6
        static let columnGap: CGFloat = .spacing2x
        static let cellSpacing: CGFloat = .spacing05x
        static let keySwatchSize: CGFloat = 12
    }
}

#Preview {
    ExerciseConsistencySheet()
}
