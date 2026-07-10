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
    @State private var sheetHeight: CGFloat = 320

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
                VaultMetricSheet(
                    metric: VaultDemoData.metric(forIndex: cell.row * gridCols + cell.col),
                    hasData: datapoints[cell.row][cell.col],
                    onClose: { selectedCell = nil }
                )
                .onPreferenceChange(MetricSheetHeightKey.self) { if $0 > 0 { sheetHeight = $0 } }
                .presentationDetents([.height(sheetHeight)])
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
            }
        }
        .animation(.brightBouncy, value: selectedCell)
    }

    private func dpDot(_ cell: GridCell) -> some View {
        let isSelected = selectedCell == cell
        return RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(isSelected ? Color.defaultPurple : (datapoints[cell.row][cell.col] ? highlighted : muted))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color.defaultPurple, lineWidth: 1.5)
                        .padding(-2)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { selectedCell = cell }
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

// MARK: - Metric sheet

private struct MetricSheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct VaultMetricSheet: View {
    let metric: VaultDemoData.Metric
    let hasData: Bool
    let onClose: () -> Void

    @State private var showMore = false

    private var valueNumber: String {
        metric.value.split(separator: " ", maxSplits: 1).first.map(String.init) ?? metric.value
    }

    private var valueUnit: String {
        metric.value.split(separator: " ", maxSplits: 1).dropFirst().first.map(String.init) ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            VStack(alignment: .leading, spacing: .spacing1x) {
                BrightText(metric.title, size: .standout3)
                    .padding(.trailing, 52)
                if hasData {
                    BrightText("Latest: \(VaultDemoData.latestRecorded(metric))", size: .body3, color: .lightTextColor, weight: .regular)
                }
            }

            VStack(alignment: .leading, spacing: .spacing105x) {
                HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
                    BrightText(hasData ? valueNumber : "–", size: .huge)
                        .monospacedDigit()
                    BrightText(valueUnit, size: .subheading2, color: .lightTextColor, weight: .regular)
                }

                if hasData {
                    HStack(spacing: .spacing1x) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.standard(size: .subheading2, weight: .regular))
                            .foregroundStyle(Color.defaultBrightGreen)
                        BrightText("in normal range", size: .body3, color: .semiLightTextColor, weight: .regular)
                    }
                } else {
                    HStack(spacing: .spacing1x) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.standard(size: .subheading2, weight: .regular))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.defaultSkyBlue, Color.defaultLighthouseBlue)
                        BrightText("no data available", size: .body3, color: .semiLightTextColor, weight: .regular)
                    }
                }
            }

            VStack(alignment: .leading, spacing: .spacing2x) {
                BrightText("What is this datapoint?", size: .body3, color: .semiLightTextColor, weight: .regular)
                BrightText(VaultDemoData.whatIsIt(metric), size: .body3, color: .lightTextColor, weight: .regular)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(.lineSpacingMedium)
                if showMore {
                    BrightText(VaultDemoData.whyItMatters(metric), size: .body3, color: .lightTextColor, weight: .regular)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(.lineSpacingMedium)
                }
            }

            if !showMore {
                BrightPillButton("Show more", color: .defaultSkyBlue, buttonSize: .large) {
                    withAnimation(.brightBouncy) { showMore = true }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.spacing4x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: MetricSheetHeightKey.self, value: proxy.size.height)
            }
        )
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.textColor)
                    .frame(width: 44, height: 44)
                    .modifier(GlassEffect(shape: .circle, interactive: false))
                    .overlay(Circle().stroke(Color.textColor.opacity(.veryMinimalOpacity), lineWidth: 1))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, .spacing3x)
            .padding(.trailing, .spacing3x)
        }
    }
}

#Preview {
    VaultDatapointsWidget()
        .padding(.spacing4x)
}
