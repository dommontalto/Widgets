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
    private let columns = 24

    private let datapoints = VaultDemoData.completeness.datapoints ?? []

    @State private var selectedCell: GridCell?

    private var sheetShown: Binding<Bool> {
        Binding(
            get: { selectedCell != nil },
            set: { if !$0 { selectedCell = nil } }
        )
    }

    private var total: Int { datapoints.count }
    private var filled: Int { datapoints.filter { $0.complete == true }.count }
    private var gridRows: Int { max(1, Int((Double(total) / Double(columns)).rounded(.up))) }

    private func index(row: Int, col: Int) -> Int? {
        let i = row * columns + col
        guard i < total else { return nil }
        return i
    }

    private func datapoint(_ cell: GridCell) -> VaultCompletenessDatapoint? {
        guard let i = index(row: cell.row, col: cell.col) else { return nil }
        return datapoints[i]
    }

    private func isLit(_ cell: GridCell) -> Bool {
        datapoint(cell)?.complete == true
    }

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
        .brightMiniSheet(isPresented: sheetShown) {
            if let cell = selectedCell, let dp = datapoint(cell) {
                VaultDatapointMiniSheet(
                    title: dp.name ?? "Data point",
                    unit: dp.unit ?? "",
                    hasData: dp.complete == true,
                    latestRecorded: VaultDemoData.displayDateTime(dp.lastUpdated),
                    onClose: { selectedCell = nil },
                    value: dp.value,
                    markerPosition: dp.markerPosition
                )
            }
        }
    }

    // MARK: - Grid

    private var datapointsGrid: some View {
        let flat = (0..<gridRows).flatMap { row in (0..<columns).map { col in GridCell(row: row, col: col) } }
        let gridColumns = Array(repeating: GridItem(.flexible(), spacing: dpGap), count: columns)

        return LazyVGrid(columns: gridColumns, spacing: dpGap) {
            ForEach(flat) { cell in
                dpDot(cell)
                    .aspectRatio(1, contentMode: .fit)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard datapoint(cell) != nil else { return }
                        selectedCell = cell
                    }
            }
        }
        .animation(.brightBouncy, value: selectedCell)
    }

    private func dpDot(_ cell: GridCell) -> some View {
        let isBlank = index(row: cell.row, col: cell.col) == nil
        let isSelected = selectedCell == cell
        return RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(isLit(cell) ? highlighted : muted)
            .opacity(isBlank ? 0 : 1)
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
