//
//  ExerciseConsistencyWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct ExerciseConsistencyWidget: View {
    private enum Page: Int, CaseIterable {
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
    }

    private let visibleColumns = 16
    private let cellSpacing: CGFloat = .spacing05x
    private let cellCornerRadius: CGFloat = 4
    private let dayLabelWidth: CGFloat = 14
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    @State private var months = ExerciseDemoData.consistencyMonths()
    @State private var activePage: Int? = 0
    @State private var gridWidth: CGFloat = 0

    private var cellSize: CGFloat {
        guard gridWidth > 0 else { return 14 }
        let gaps = CGFloat(visibleColumns - 1) * cellSpacing
        return (gridWidth - dayColumnWidth - gaps) / CGFloat(visibleColumns)
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

    private var pageSelection: Binding<Int> {
        Binding(
            get: { activePage ?? 0 },
            set: { activePage = $0 }
        )
    }

    var body: some View {
        VStack(spacing: .spacing2x) {
            ZStack {
                card(.combined)
                    .padding(.horizontal, .spacing3x)
                    .hidden()

                TabView(selection: pageSelection) {
                    ForEach(Page.allCases, id: \.rawValue) { page in
                        card(page)
                            .padding(.horizontal, .spacing3x)
                            .tag(page.rawValue)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .padding(.horizontal, -.spacing3x)

            BrightPageIndicator(total: Page.allCases.count, activeIndex: $activePage)
        }
        .animation(.brightEaseInOut, value: activePage)
    }

    private func card(_ page: Page) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(page.title, size: .body1, color: .textColor)
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

    private func heatmap(_ page: Page) -> some View {
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
                                    .fill(color(for: visibleMonths[monthIndex].columns[columnIndex][row], on: page))
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func legend(_ page: Page) -> some View {
        switch page {
        case .strength:
            HStack(spacing: .spacing3x) {
                legendItem("Session", color: .defaultPurple)
                legendItem("Rest", color: Color.defaultPurple.opacity(.veryMinimalOpacity))
            }
        case .cardio:
            HStack(spacing: .spacing3x) {
                legendItem("Session", color: .defaultSkyBlue)
                legendItem("Rest", color: Color.defaultSkyBlue.opacity(.veryMinimalOpacity))
            }
        case .combined:
            HStack(spacing: .spacing3x) {
                legendItem("Strength", color: .defaultPurple)
                legendItem("Cardio", color: .defaultSkyBlue)
                legendItem("Both", color: .defaultGreen)
                legendItem("Rest", color: .textColor.opacity(.ultraLowOpacity))
            }
        }
    }

    private func legendItem(_ title: String, color: Color) -> some View {
        HStack(spacing: .spacing1x) {
            RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
                .fill(color)
                .frame(width: 12, height: 12)
            BrightText(title, size: .body3, color: .lightTextColor)
        }
    }

    private func color(for type: ExerciseDayType?, on page: Page) -> Color {
        guard let type else { return .clear }
        switch page {
        case .strength:
            return type == .strength || type == .both
                ? .defaultPurple
                : Color.defaultPurple.opacity(.veryMinimalOpacity)
        case .cardio:
            return type == .cardio || type == .both
                ? .defaultSkyBlue
                : Color.defaultSkyBlue.opacity(.veryMinimalOpacity)
        case .combined:
            switch type {
            case .strength: return .defaultPurple
            case .cardio: return .defaultSkyBlue
            case .both: return .defaultGreen
            case .rest: return .textColor.opacity(.ultraLowOpacity)
            }
        }
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
