//
//  ExerciseConsistencyWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct ExerciseConsistencyWidget: View {
    private let visibleColumns = 16

    private let cellSpacing: CGFloat = .spacing05x

    private let cellCornerRadius: CGFloat = 4

    private let dayLabelWidth: CGFloat = 14

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    @State private var months = ExerciseDemoData.consistencyMonths()

    @State private var activePage: Int? = 0

    @State private var gridWidth: CGFloat = 0

    @State private var showingYear = false

    var body: some View {
        VStack(spacing: .spacing2x) {
            ZStack {
                card(.combined)
                    .padding(.horizontal, .spacing3x)
                    .hidden()

                TabView(selection: pageSelection) {
                    ForEach(ExerciseConsistencyMode.allCases, id: \.rawValue) { page in
                        card(page)
                            .padding(.horizontal, .spacing3x)
                            .tag(page.rawValue)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .padding(.horizontal, -.spacing3x)

            BrightPageIndicator(total: ExerciseConsistencyMode.allCases.count, activeIndex: $activePage)
        }
        .animation(.brightEaseInOut, value: activePage)
        .sheet(isPresented: $showingYear) {
            ExerciseConsistencySheet(mode: activeMode)
        }
    }

    // MARK: - Heatmap

    private func card(_ page: ExerciseConsistencyMode) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(alignment: .top) {
                BrightText(page.title, size: .body1)

                Spacer()

                BrightRoundButton(systemImage: "arrow.down.backward.and.arrow.up.forward", size: .small) {
                    showingYear = true
                }
            }
            .padding(.bottom, .spacing2x)

            VStack(alignment: .leading, spacing: .spacing1x) {
                monthRow
                heatmap(page)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { gridWidth = $0 }

            Rectangle()
                .fill(Color.textColor.opacity(.ultraLowOpacity))
                .frame(height: 1)

            legend(page)
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
    }

    private var monthRow: some View {
        let visible = visibleMonths
        return HStack(spacing: cellSpacing) {
            ForEach(visible.indices, id: \.self) { i in
                BrightText(visible[i].name, size: .body3, color: .lightTextColor)
                    .frame(width: monthWidth(visible[i]), alignment: .leading)
            }
        }
        .padding(.leading, dayColumnWidth)
    }

    private func heatmap(_ page: ExerciseConsistencyMode) -> some View {
        HStack(alignment: .top, spacing: .spacing105x) {
            VStack(spacing: cellSpacing) {
                ForEach(dayLabels.indices, id: \.self) { i in
                    BrightText(dayLabels[i], size: .body4, color: .lightTextColor)
                        .frame(width: dayLabelWidth, height: cellSize)
                }
            }

            HStack(spacing: cellSpacing) {
                ForEach(visibleMonths.indices, id: \.self) { monthIndex in
                    ForEach(visibleMonths[monthIndex].columns.indices, id: \.self) { columnIndex in
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { row in
                                RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
                                    .fill(page.fill(for: visibleMonths[monthIndex].columns[columnIndex][row]))
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
        }
    }

    private func legend(_ page: ExerciseConsistencyMode) -> some View {
        HStack(spacing: .spacing3x) {
            ForEach(page.keyItems, id: \.title) { item in
                legendItem(item.title, fill: item.fill)
            }
        }
    }

    private func legendItem(_ title: String, fill: some ShapeStyle) -> some View {
        HStack(spacing: .spacing1x) {
            RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
                .fill(fill)
                .frame(width: 12, height: 12)
            BrightText(title, size: .body3, color: .lightTextColor)
        }
    }

    // MARK: - Derived state

    private var pageSelection: Binding<Int> {
        Binding(
            get: { activePage ?? 0 },
            set: { activePage = $0 }
        )
    }

    private var activeMode: ExerciseConsistencyMode {
        ExerciseConsistencyMode(rawValue: activePage ?? 0) ?? .combined
    }

    private var visibleMonths: [ExerciseMonthData] {
        var remaining = visibleColumns
        var result: [ExerciseMonthData] = []
        for month in months {
            guard remaining > 0 else { break }
            let columns = Array(month.columns.prefix(remaining))
            remaining -= columns.count
            result.append(ExerciseMonthData(name: month.name, columns: columns))
        }
        return result
    }

    private var cellSize: CGFloat {
        guard gridWidth > 0 else { return 14 }
        let gaps = CGFloat(visibleColumns - 1) * cellSpacing
        return (gridWidth - dayColumnWidth - gaps) / CGFloat(visibleColumns)
    }

    private var dayColumnWidth: CGFloat {
        dayLabelWidth + .spacing105x
    }

    private func monthWidth(_ month: ExerciseMonthData) -> CGFloat {
        CGFloat(month.columns.count) * (cellSize + cellSpacing) - cellSpacing
    }
}

#Preview {
    ExerciseConsistencyWidget()
        .padding(.spacing4x)
}
