//
//  VaultSummaryWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 10/7/2026.
//

import SwiftUI

/// Vault → Summary hero: a cohort-percentile sentence with inline chips.
/// Edge-to-edge (no card) — sits at the top of the Vault section.
struct VaultSummaryWidget: View {
    @State private var gender = "men"
    @State private var ageRange = "18 & 24"

    private static let genderOptions = ["men", "women"]
    private static let ageOptions = ["18 & 24", "25 & 30", "31 & 35", "36 & 40",
                                     "41 & 45", "46 & 50", "51 & 55", "56 & 60", "60+"]

    var body: some View {
        headline
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Headline

    private enum Token {
        case text(String)
        case genderChip
        case ageChip
        case highlight(String, Color)
    }

    // One row per clause — the sentence breaks to a new line after each comma.
    private let lines: [[Token]] = [
        [.text("From"), .text("your"), .text("data"), .text("this"), .text("week,")],
        [.text("of"), .genderChip, .text("aged"), .text("between"), .ageChip],
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
        case .genderChip:
            pickerChip(
                selection: $gender,
                options: Self.genderOptions,
                color: gender == "women" ? .defaultPurple : .defaultSkyBlue
            )
        case .ageChip:
            HStack(spacing: .spacing0x) {
                pickerChip(selection: $ageRange, options: Self.ageOptions, color: .defaultPurple)
                BrightText(",", size: .standout4)
            }
        case let .highlight(value, color):
            HStack(alignment: .firstTextBaseline, spacing: .spacing0x) {
                BrightText(value, size: .standout28, color: color)
                BrightText(".", size: .standout4)
            }
        }
    }

    private func pickerChip(selection: Binding<String>, options: [String], color: Color) -> some View {
        Menu {
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
        } label: {
            chip(selection.wrappedValue, color: color)
        }
        .buttonStyle(.plain)
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
