//
//  ExerciseConsistencyWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct ExerciseConsistencyWidget: View {
    private let cellSize: CGFloat = 14
    private let cellSpacing: CGFloat = .spacing05x
    private let cellCornerRadius: CGFloat = 4
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    @State private var months = ExerciseDemoData.consistencyMonths()

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText("Strength & Cardio", size: .body1, color: .textColor)
                .padding(.bottom, .spacing2x)

            VStack(alignment: .leading, spacing: .spacing1x) {
                monthRow
                heatmap
            }

            Rectangle()
                .fill(Color.textColor.opacity(.ultraLowOpacity))
                .frame(height: 1)

            legend
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
    }

    private var monthRow: some View {
        HStack(spacing: cellSpacing) {
            ForEach(months.indices, id: \.self) { i in
                BrightText(months[i].name, size: .body3, color: .lightTextColor)
                    .frame(width: monthWidth(months[i]), alignment: .leading)
            }
        }
        .padding(.leading, dayColumnWidth)
    }

    private var heatmap: some View {
        HStack(alignment: .top, spacing: .spacing105x) {
            VStack(spacing: cellSpacing) {
                ForEach(dayLabels.indices, id: \.self) { i in
                    BrightText(dayLabels[i], size: .body4, color: .lightTextColor)
                        .frame(width: cellSize, height: cellSize)
                }
            }

            HStack(spacing: cellSpacing) {
                ForEach(months.indices, id: \.self) { monthIndex in
                    ForEach(months[monthIndex].columns.indices, id: \.self) { columnIndex in
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { row in
                                RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
                                    .fill(color(for: months[monthIndex].columns[columnIndex][row]))
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: .spacing3x) {
            legendItem("Strength", color: color(for: .strength))
            legendItem("Cardio", color: color(for: .cardio))
            legendItem("Both", color: color(for: .both))
            legendItem("Rest", color: color(for: .rest))
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

    private func color(for type: ExerciseDayType?) -> Color {
        switch type {
        case .strength: .defaultPurple
        case .cardio: .defaultSkyBlue
        case .both: .defaultGreen
        case .rest: .textColor.opacity(.ultraLowOpacity)
        case nil: .clear
        }
    }

    private var dayColumnWidth: CGFloat {
        cellSize + .spacing105x
    }

    private func monthWidth(_ month: ExerciseMonthData) -> CGFloat {
        CGFloat(month.columns.count) * (cellSize + cellSpacing) - cellSpacing
    }
}

#Preview {
    ExerciseConsistencyWidget()
        .padding(.spacing4x)
}
