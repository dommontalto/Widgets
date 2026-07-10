//
//  VaultSummaryWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 10/7/2026.
//

import SwiftUI
import Charts

/// Vault → Summary hero: a cohort-percentile sentence with inline chips, above a
/// week-long percentile line chart. Edge-to-edge (no card) — sits at the top of
/// the Vault section.
struct VaultSummaryWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .spacing5x) {
            headline
            chart
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Headline

    private enum Token {
        case text(String)
        case chip(String, Color)
        case chipComma(String, Color)
        case highlight(String, Color)
    }

    // One row per clause — the sentence breaks to a new line after each comma.
    private let lines: [[Token]] = [
        [.text("From"), .text("your"), .text("data"), .text("this"), .text("week,")],
        [.text("of"), .chip("men", .defaultSkyBlue), .text("aged"), .text("between"),
         .chipComma("18 & 24", .defaultPurple)],
        [.text("you're"), .text("in"), .text("the"), .text("top"), .highlight("8%", .defaultGreen)],
    ]

    private var headline: some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HeadlineFlowLayout(hSpacing: .spacing1x, vSpacing: .spacing105x) {
                    ForEach(Array(line.enumerated()), id: \.offset) { _, token in
                        tokenView(token)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tokenView(_ token: Token) -> some View {
        switch token {
        case let .text(value):
            BrightText(value, size: .standout4)
        case let .chip(value, color):
            chip(value, color: color)
        case let .chipComma(value, color):
            HStack(spacing: .spacing0x) {
                chip(value, color: color)
                BrightText(",", size: .standout4)
            }
        case let .highlight(value, color):
            HStack(alignment: .firstTextBaseline, spacing: .spacing0x) {
                BrightText(value, size: .standout28, color: color)
                BrightText(".", size: .standout4)
            }
        }
    }

    private func chip(_ text: String, color: Color) -> some View {
        BrightText(text, size: .standout4, color: color)
            .padding(.horizontal, .spacing105x)
            .padding(.vertical, .spacing05x)
            .background(
                RoundedRectangle(cornerRadius: .cornerRadius10, style: .continuous)
                    .fill(color.opacity(.veryMinimalOpacity))
            )
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadius10, style: .continuous)
                    .stroke(color, lineWidth: 1)
            }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            RuleMark(y: .value("Baseline", VaultWeekPoint.week.first?.value ?? 50))
                .foregroundStyle(Color.textColor.opacity(.ultraLowOpacity))
                .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [3, 3]))

            ForEach(VaultWeekPoint.week) { point in
                LineMark(x: .value("Day", point.day), y: .value("Percentile", point.value))
                    .foregroundStyle(Color.defaultSkyBlue.opacity(.mediumOpacity))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .interpolationMethod(.catmullRom)
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(position: .trailing, values: [0, 20, 40, 60, 80, 100]) { value in
                AxisValueLabel {
                    if let pct = value.as(Double.self) {
                        Text(pct == 0 ? "0%" : "\(Int(pct))")
                            .font(.standard(size: .body4, weight: .regular))
                            .foregroundStyle(Color.lightTextColor)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                    .foregroundStyle(Color.textColor.opacity(.ultraLowOpacity))
                AxisValueLabel {
                    if let day = value.as(String.self) {
                        Text(day)
                            .font(.standard(size: .body4, weight: .regular))
                            .foregroundStyle(Color.semiLightTextColor)
                    }
                }
            }
        }
        // Hollow dots drawn in overlay so they read as sky-blue rings on the bG.
        .chartOverlay { proxy in
            GeometryReader { geo in
                if let plot = proxy.plotFrame {
                    let frame = geo[plot]
                    ForEach(VaultWeekPoint.week) { point in
                        if let x = proxy.position(forX: point.day),
                           let y = proxy.position(forY: point.value) {
                            ZStack {
                                Circle().fill(Color.bG)
                                Circle().stroke(Color.defaultSkyBlue, lineWidth: 2.5)
                            }
                            .frame(width: 7, height: 7)
                            .position(x: frame.minX + x, y: frame.minY + y)
                        }
                    }
                }
            }
        }
        .frame(height: 220)
    }
}

// MARK: - Flow layout

/// Wraps its subviews left-to-right onto new rows, centring each item within its
/// row. Lets the headline's words + chips flow naturally without clipping.
private struct HeadlineFlowLayout: Layout {
    var hSpacing: CGFloat = .spacing1x
    var vSpacing: CGFloat = .spacing2x

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = rows(subviews: subviews, maxWidth: maxWidth)
        let height = rows.reduce(0) { $0 + $1.height } + vSpacing * CGFloat(max(0, rows.count - 1))
        let widest = rows.map(\.width).max() ?? 0
        return CGSize(width: maxWidth.isFinite ? maxWidth : widest, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var y = bounds.minY
        for row in rows(subviews: subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + hSpacing
            }
            y += row.height + vSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if current.width + size.width > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.indices.append(index)
            current.width += size.width + hSpacing
            current.height = max(current.height, size.height)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

#Preview {
    VaultSummaryWidget()
        .padding(.spacing3x)
}
