//
//  BrightDotGridV5.swift
//  Bright
//
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI
import UIKit

struct BrightDotGridV5Dot: Identifiable {
    let id: String
    let fill: AnyShapeStyle
    let isSelectable: Bool

    init(id: String, fill: some ShapeStyle, isSelectable: Bool = true) {
        self.id = id
        self.fill = AnyShapeStyle(fill)
        self.isSelectable = isSelectable
    }
}

struct BrightDotGridV5Key {
    let title: String
    let fill: AnyShapeStyle

    init(title: String, fill: some ShapeStyle) {
        self.title = title
        self.fill = AnyShapeStyle(fill)
    }
}

struct BrightDotGridV5: View {
    let columns: [[BrightDotGridV5Dot?]]
    let legend: [BrightDotGridV5Key]
    var selection: Binding<String?>? = nil
    var spacing: CGFloat = .spacing05x
    var ringColor: Color = .defaultPurple

    @State private var width: CGFloat = 0
    @State private var isHolding = false

    private var rowCount: Int { columns.map(\.count).max() ?? 0 }

    private var cellSize: CGFloat {
        DotGridLayout.cellSize(width: width, columns: columns.count, spacing: spacing)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            grid
            legendRow
        }
    }

    private var grid: some View {
        DotGridLayout(columns: columns.count, rows: rowCount, spacing: spacing) {
            ForEach(columns.indices, id: \.self) { column in
                ForEach(0 ..< rowCount, id: \.self) { row in
                    dotView(dot(column: column, row: row))
                }
            }
        }
        .overlay(alignment: .topLeading) { selectionRing }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .local) { select(at: $0, clamped: false) }
        .gesture(
            DotGridHoldGesture { location in
                isHolding = true
                select(at: location, clamped: true)
            } onEnd: {
                isHolding = false
            }
        )
        .allowsHitTesting(selection != nil)
        .animation(.brightBouncy, value: selection?.wrappedValue)
        .animation(.brightBouncy, value: isHolding)
        .brightHapticV5(.light, trigger: selection?.wrappedValue)
    }

    private var legendRow: some View {
        HStack(spacing: .spacing3x) {
            ForEach(legend, id: \.title) { key in
                HStack(spacing: .spacing1x) {
                    Circle()
                        .fill(key.fill)
                        .frame(width: .spacing2x, height: .spacing2x)
                    BrightText(key.title, size: .body1, color: .lightTextColor)
                }
            }
        }
    }

    private func dotView(_ dot: BrightDotGridV5Dot?) -> some View {
        Circle()
            .fill(dot?.fill ?? AnyShapeStyle(Color.clear))
    }

    @ViewBuilder
    private var selectionRing: some View {
        if let id = selection?.wrappedValue, let position = position(of: id) {
            let pitch = cellSize + spacing
            let size = isHolding ? Constants.fingerSize : cellSize + Constants.ringOutset
            Circle()
                .stroke(ringColor, lineWidth: Constants.ringWidth)
                .frame(width: size, height: size)
                .position(
                    x: CGFloat(position.column) * pitch + cellSize / 2,
                    y: CGFloat(position.row) * pitch + cellSize / 2
                )
                .allowsHitTesting(false)
                .transition(.scale(scale: 0.6).combined(with: .opacity))
        }
    }

    private func position(of id: String) -> (column: Int, row: Int)? {
        for (column, dots) in columns.enumerated() {
            if let row = dots.firstIndex(where: { $0?.id == id }) {
                return (column, row)
            }
        }
        return nil
    }

    private func dot(column: Int, row: Int) -> BrightDotGridV5Dot? {
        guard columns.indices.contains(column), columns[column].indices.contains(row) else { return nil }
        return columns[column][row]
    }

    private func select(at location: CGPoint, clamped: Bool) {
        let pitch = cellSize + spacing
        guard pitch > 0, !columns.isEmpty, rowCount > 0 else { return }
        var column = Int(floor(location.x / pitch))
        var row = Int(floor(location.y / pitch))
        if clamped {
            column = min(max(column, 0), columns.count - 1)
            row = min(max(row, 0), rowCount - 1)
        }
        guard let selection,
              let dot = dot(column: column, row: row),
              dot.isSelectable,
              dot.id != selection.wrappedValue
        else { return }
        selection.wrappedValue = dot.id
    }
}

private struct DotGridHoldGesture: UIGestureRecognizerRepresentable {
    let onChange: (CGPoint) -> Void
    let onEnd: () -> Void

    func makeUIGestureRecognizer(context _: Context) -> UILongPressGestureRecognizer {
        let recognizer = UILongPressGestureRecognizer()
        recognizer.minimumPressDuration = 0.25
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        switch recognizer.state {
        case .began, .changed:
            onChange(context.converter.localLocation)
        case .ended, .cancelled, .failed:
            onEnd()
        default:
            break
        }
    }
}

private enum Constants {
    static let fingerSize: CGFloat = 44
    static let ringOutset: CGFloat = 4
    static let ringWidth: CGFloat = 1.5
}

private struct DotGridLayout: Layout {
    let columns: Int
    let rows: Int
    let spacing: CGFloat

    static func cellSize(width: CGFloat, columns: Int, spacing: CGFloat) -> CGFloat {
        guard width > 0, columns > 0 else { return 0 }
        return max(0, (width - CGFloat(columns - 1) * spacing) / CGFloat(columns))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews _: Subviews, cache _: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let cell = Self.cellSize(width: width, columns: columns, spacing: spacing)
        let height = rows > 0 ? CGFloat(rows) * cell + CGFloat(rows - 1) * spacing : 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        guard rows > 0 else { return }
        let cell = Self.cellSize(width: bounds.width, columns: columns, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            let column = index / rows
            let row = index % rows
            subview.place(
                at: CGPoint(
                    x: bounds.minX + CGFloat(column) * (cell + spacing),
                    y: bounds.minY + CGFloat(row) * (cell + spacing)
                ),
                proposal: ProposedViewSize(width: cell, height: cell)
            )
        }
    }
}

#Preview {
    @Previewable @State var selection: String?

    BrightDotGridV5(
        columns: (0 ..< 20).map { column in
            (0 ..< 8).map { row in
                BrightDotGridV5Dot(
                    id: "\(column)-\(row)",
                    fill: (column + row) % 3 == 0 ? Color.defaultGreen.opacity(.ultraLowOpacity) : Color.defaultGreen
                )
            }
        },
        legend: [
            BrightDotGridV5Key(title: "Recorded", fill: Color.defaultGreen),
            BrightDotGridV5Key(title: "No data", fill: Color.defaultGreen.opacity(.ultraLowOpacity))
        ],
        selection: $selection
    )
    .padding(.spacing4x)
}
