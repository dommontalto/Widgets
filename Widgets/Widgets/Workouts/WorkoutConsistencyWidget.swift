//
//  WorkoutConsistencyWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

// MARK: - Supporting Views

struct HeatmapHeader: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: .spacing105x) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .fontWeight(.semibold)
                .frame(width: 24, height: 24)
                .foregroundStyle(Color.defaultBrightViolet)
            BrightText(title, size: .body1, weight: .regular)
        }
    }
}

struct HeatmapGrid: View {
    let cells: [[Bool]]
    let cellSpacing: CGFloat
    let highlighted: Color
    let muted: Color

    var body: some View {
        let cols = cells.first?.count ?? 1
        let flat = cells.flatMap { $0 }
        let columns = Array(repeating: GridItem(.flexible(), spacing: cellSpacing), count: cols)

        LazyVGrid(columns: columns, spacing: cellSpacing) {
            ForEach(flat.indices, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(flat[i] ? highlighted : muted)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}

// MARK: - Widget

struct WorkoutConsistencyWidget: View {
    private let highlighted: Color = .defaultSkyBlue
    private let muted: Color = .defaultSkyBlue.opacity(.ultraLowOpacity)
    private let cellSize: CGFloat = .spacing3x    // 18pt
    private let cellSpacing: CGFloat = .spacing1x // 6pt
    private let febColumn = 6
    
    @State private var cells = WorkoutsDemoData.randomGrid(rows: 4, columns: 12)
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            VStack(alignment: .leading, spacing: .spacing2x) {
                HeatmapHeader(icon: "figure.arms.open", title: "Consistency")

                HStack(spacing: 0) {
                    BrightText("Jan", size: .body1, weight: .regular)
                        .frame(width: columnOffset(febColumn), alignment: .leading)
                    BrightText("Feb", size: .body1, weight: .regular)
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, .spacing3x)

            HeatmapGrid(
                cells: cells,
                cellSpacing: cellSpacing,
                highlighted: highlighted,
                muted: muted
            )
            .padding(.horizontal, .spacing3x)
            .padding(.bottom, .spacing3x)
        }
        .padding(.top, .spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
    }
    private func columnOffset(_ index: Int) -> CGFloat {
        CGFloat(index) * (cellSize + cellSpacing)
    }
}

#Preview {
    WorkoutConsistencyWidget()
        .padding(.spacing4x)
}
