//
//  VaultDatapointsWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI
import UIKit

// UIGestureRecognizerRepresentable (iOS 18 SwiftUI protocol) — cooperates with ScrollView natively
private struct GridLongPressGesture: UIGestureRecognizerRepresentable {
    var gridOrigin: CGPoint
    var onBegan: (CGPoint) -> Void
    var onMoved: (CGPoint) -> Void
    var onEnded: () -> Void

    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let g = UILongPressGestureRecognizer()
        g.minimumPressDuration = 0.5
        return g
    }

    func handleUIGestureRecognizerAction(_ r: UILongPressGestureRecognizer, context: Context) {
        guard let window = r.view?.window else { return }
        let windowPt = r.location(in: window)
        let localPt = CGPoint(x: windowPt.x - gridOrigin.x, y: windowPt.y - gridOrigin.y)
        switch r.state {
        case .began:    onBegan(localPt)
        case .changed:  onMoved(localPt)
        default:        onEnded()
        }
    }
}

struct GridCell: Equatable {
    let row: Int
    let col: Int
}

struct SpeechBubble: Shape {
    var cornerRadius: CGFloat
    var tailSize: CGFloat
    var tailX: CGFloat
    var tailOnBottom: Bool

    var animatableData: CGFloat {
        get { tailX }
        set { tailX = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let body = tailOnBottom
            ? CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - tailSize)
            : CGRect(x: rect.minX, y: rect.minY + tailSize, width: rect.width, height: rect.height - tailSize)

        path.addRoundedRect(in: body, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))

        let minBase = body.minX + cornerRadius + tailSize
        let maxBase = body.maxX - cornerRadius - tailSize
        let baseCenter = min(max(tailX, minBase), maxBase)
        let tip = min(max(tailX, body.minX + 6), body.maxX - 6)

        var tail = Path()
        if tailOnBottom {
            tail.move(to: CGPoint(x: baseCenter - tailSize, y: body.maxY - 0.5))
            tail.addLine(to: CGPoint(x: tip, y: rect.maxY))
            tail.addLine(to: CGPoint(x: baseCenter + tailSize, y: body.maxY - 0.5))
        } else {
            tail.move(to: CGPoint(x: baseCenter - tailSize, y: body.minY + 0.5))
            tail.addLine(to: CGPoint(x: tip, y: rect.minY))
            tail.addLine(to: CGPoint(x: baseCenter + tailSize, y: body.minY + 0.5))
        }
        tail.closeSubpath()
        path.addPath(tail)
        return path
    }
}

// MARK: - Widget

struct VaultDatapointsWidget: View {
    private let highlighted: Color = .defaultSkyBlue
    private let muted: Color = .defaultSkyBlue.opacity(.ultraLowOpacity)

    private let dpGap: CGFloat = .spacing1x / 2   // 3pt fixed gap

    private var gridCols: Int { datapoints.first?.count ?? 0 }
    private var gridRows: Int { datapoints.count }

    @State private var datapoints = VaultDemoData.randomGrid(rows: 16, columns: 24)
    @State private var hoveredCell: GridCell?
    @State private var cellPitch: CGFloat = 12
    @State private var measuredGridWidth: CGFloat = 200
    @State private var gridGlobalOrigin: CGPoint = .zero

    private var dpCell: CGFloat { max(cellPitch - dpGap, 1) }

    private var total: Int { datapoints.flatMap { $0 }.count }
    private var filled: Int { datapoints.flatMap { $0 }.filter { $0 }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing4x) {
            datapointsGrid
                .padding(.horizontal, .spacing3x)
                .padding(.top, .spacing3x)

            gridLegend
                .padding(.horizontal, .spacing3x)

            VStack(alignment: .leading, spacing: .spacing1x) {
                BrightText("\(filled)/\(total)", size: .huge2, weight: .light)
                BrightText("complete data points", size: .subheading2, color: Color.lightTextColor, weight: .light)
            }
            .padding(.horizontal, .spacing3x)
            .padding(.bottom, .spacing3x)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
        .overlay(alignment: .topLeading) {
            if let cell = hoveredCell {
                hoverOverlay(cell)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Interactive Grid

    private var datapointsGrid: some View {
        let cols = gridCols
        let flat = (0..<gridRows).flatMap { row in (0..<gridCols).map { col in (row, col) } }
        let columns = Array(repeating: GridItem(.flexible(), spacing: dpGap), count: cols)

        return LazyVGrid(columns: columns, spacing: dpGap) {
            ForEach(Array(flat.enumerated()), id: \.offset) { _, pair in
                dpDot(row: pair.0, col: pair.1)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .coordinateSpace(.named("dpgrid"))
        .contentShape(Rectangle())
        .gesture(
            GridLongPressGesture(
                gridOrigin: gridGlobalOrigin,
                onBegan: { setHovered(at: $0) },
                onMoved: { setHovered(at: $0) },
                onEnded: { hoveredCell = nil }
            )
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: hoveredCell)
        .sensoryFeedback(.selection, trigger: hoveredCell)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
            gridGlobalOrigin = frame.origin
            measuredGridWidth = frame.width
            let gapTotal = CGFloat(cols - 1) * dpGap
            let cell = (frame.width - gapTotal) / CGFloat(cols)
            cellPitch = cell + dpGap
        }
    }

    private func setHovered(at point: CGPoint) {
        let col = min(max(Int(point.x / cellPitch), 0), gridCols - 1)
        let row = min(max(Int(point.y / cellPitch), 0), gridRows - 1)
        hoveredCell = GridCell(row: row, col: col)
    }

    private func dpDot(row: Int, col: Int) -> some View {
        let lit = datapoints[row][col]
        let bump = magnification(row: row, col: col)
        return RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(lit ? highlighted : muted)
            .scaleEffect(1 + bump * 1.1)
            .shadow(color: highlighted.opacity(Double(bump) * 0.5), radius: bump * 6)
            .zIndex(Double(bump))
    }

    private func magnification(row: Int, col: Int) -> CGFloat {
        guard let hovered = hoveredCell else { return 0 }
        let dr = CGFloat(row - hovered.row)
        let dc = CGFloat(col - hovered.col)
        let distance = (dr * dr + dc * dc).squareRoot()
        let radius: CGFloat = 2.4
        return max(0, 1 - distance / radius)
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
            BrightText(label, size: .body5, color: Color.lightTextColor, weight: .regular)
        }
    }

    // MARK: - Hover Bubble

    private func hoverOverlay(_ cell: GridCell) -> some View {
        let centerX = CGFloat(cell.col) * cellPitch + dpCell / 2 + CGFloat.spacing3x
        let centerY = CGFloat(cell.row) * cellPitch + dpCell / 2 + CGFloat.spacing3x
        let isLit = datapoints[cell.row][cell.col]
        let metric = VaultDemoData.metric(forIndex: cell.row * gridCols + cell.col)

        let bubbleW: CGFloat = 160
        let bubbleH: CGFloat = 70
        let gap: CGFloat = .spacing8x

        let dotHalf = dpCell * 1.05
        let minX = cellPitch + dpCell / 2 + CGFloat.spacing3x
        let maxX = CGFloat(gridCols - 2) * cellPitch + dpCell / 2 + CGFloat.spacing3x
        let bubbleCenterX = min(max(centerX, minX), maxX)
        let bubbleCenterY = centerY - dotHalf - gap - bubbleH / 2

        return bubble(metric, hasData: isLit)
            .frame(width: bubbleW, height: bubbleH)
            .position(x: bubbleCenterX, y: bubbleCenterY)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func bubble(_ metric: VaultDemoData.Metric, hasData: Bool) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            BrightText(metric.title, size: .body1, weight: .medium)
            if hasData {
                BrightText(metric.value, size: .body1, color: Color.semiLightTextColor, weight: .regular)
                    .monospacedDigit()
            } else {
                BrightText("No data", size: .body1, color: Color.lightTextColor, weight: .regular)
            }
        }
        .padding(.spacing2x)
        .modifier(GlassEffect(shape: .roundedRect, cornerRadius: .cornerRadius20))
    }
}

#Preview {
    VaultDatapointsWidget()
        .padding(.spacing4x)
}
