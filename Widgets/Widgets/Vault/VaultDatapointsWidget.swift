//
//  VaultDatapointsWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct VaultDatapointsWidget: View {
    private let highlighted: Color = .defaultGreen
    private let muted: Color = .defaultGreen.opacity(.ultraLowOpacity)

    private let dpGap: CGFloat = .spacing1x / 2

    private var gridCols: Int { datapoints.first?.count ?? 0 }
    private var gridRows: Int { datapoints.count }

    @State private var datapoints = VaultDemoData.randomGrid(rows: 16, columns: 24)
    @State private var selectedCell: GridCell?

    private let sheetHeight: CGFloat = 220

    private var sheetShown: Binding<Bool> {
        Binding(
            get: { selectedCell != nil },
            set: { if !$0 { selectedCell = nil } }
        )
    }

    private var total: Int { datapoints.flatMap { $0 }.count }
    private var filled: Int { datapoints.flatMap { $0 }.filter { $0 }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    BrightText("\(filled) ", size: .huge2)
                    BrightText("/\(total)", size: .standout4, color: .lightTextColor)
                }
                BrightText("recorded data points", size: .body2, color: Color.lightTextColor)
            }
            .padding(.leading, .spacing2x)

            VStack(alignment: .leading, spacing: .spacing4x) {
                datapointsGrid
                    .padding(.horizontal, .spacing3x)
                    .padding(.top, .spacing3x)

                gridLegend
                    .padding(.horizontal, .spacing3x)
                    .padding(.bottom, .spacing3x)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(CardModifier())
        }
        .sheet(isPresented: sheetShown) {
            if let cell = selectedCell {
                VaultDatapointMiniSheet(
                    metric: VaultDemoData.metric(forIndex: cell.row * gridCols + cell.col),
                    hasData: datapoints[cell.row][cell.col],
                    onClose: { selectedCell = nil }
                )
                .presentationDetents([.height(sheetHeight)])
                .presentationCornerRadius(.cornerRadius50)
                .presentationDragIndicator(.hidden)
                .presentationBackgroundInteraction(.enabled)
            }
        }
    }

    // MARK: - Grid

    private var datapointsGrid: some View {
        let flat = (0..<gridRows).flatMap { row in (0..<gridCols).map { col in GridCell(row: row, col: col) } }
        let columns = Array(repeating: GridItem(.flexible(), spacing: dpGap), count: gridCols)

        return LazyVGrid(columns: columns, spacing: dpGap) {
            ForEach(flat) { cell in
                dpDot(cell)
                    .aspectRatio(1, contentMode: .fit)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedCell = cell }
            }
        }
        .animation(.brightBouncy, value: selectedCell)
    }

    private func dpDot(_ cell: GridCell) -> some View {
        let isSelected = selectedCell == cell
        return RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(datapoints[cell.row][cell.col] ? highlighted : muted)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color.defaultPurple, lineWidth: 1.5)
                        .padding(-2)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
    }

    // MARK: - Legend

    private var gridLegend: some View {
        HStack(spacing: .spacing3x) {
            legendItem(color: highlighted, label: "Data recorded")
            legendItem(color: muted, label: "No data")
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: .spacing1x) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(width: 8, height: 8)
            BrightText(label, size: .body2, color: Color.lightTextColor, weight: .regular)
        }
    }
}

// MARK: - Supporting Types

struct GridCell: Equatable, Identifiable {
    let row: Int
    let col: Int

    var id: String { "\(row)-\(col)" }
}

#Preview {
    VaultDatapointsWidget()
        .padding(.spacing4x)
}
