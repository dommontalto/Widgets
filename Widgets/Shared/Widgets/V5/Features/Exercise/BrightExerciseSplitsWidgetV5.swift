//
//  BrightExerciseSplitsWidgetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 13/10/2026.
//

import SwiftUI

struct BrightExerciseSplitsWidgetV5: View {
    struct Week: Identifiable, Hashable {
        let name: String
        let strengthFraction: CGFloat
        let cardioFraction: CGFloat
        let ratio: String

        var id: String { name }
    }

    let title: String
    let subtitle: String
    let strengthPercent: Int
    let cardioPercent: Int
    let weeks: [Week]
    let size: BrightWidgetSizeV5
    var allowsSelection = true

    @State private var heldWeek: String?
    @State private var isHoldingThisWeek = false
    @State private var touch: UnitPoint?
    @Environment(\.brightWidgetIsEmpty) private var isEmpty
    @State private var cardHeight: CGFloat = 0
    @State private var rowMids: [String: CGFloat] = [:]
    @State private var isRevealed = false

    private var isLarge: Bool {
        size == .large
    }

    private var held: Week? {
        isHoldingThisWeek ? weeks.last : weeks.first { $0.id == heldWeek }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isLarge ? .spacing4x : .spacing1x) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(title, size: .body1)
                    BrightText(isHoldingThisWeek ? "This week" : held?.name ?? subtitle, size: .body2, color: .lightTextColor)
                        .contentTransition(.numericText())
                }

                Spacer()
            }

            SplitsPlot(
                strengthPercent: held.map { Int(($0.strengthFraction * 100).rounded()) } ?? strengthPercent,
                cardioPercent: held.map { Int(($0.cardioFraction * 100).rounded()) } ?? cardioPercent,
                rowHeight: isLarge ? Constants.largeRowHeight : Constants.mediumRowHeight,
                isRevealed: isRevealed
            )
            .padding(.horizontal, .spacing1x)

            if isLarge {
                VStack(spacing: .spacing2x) {
                    ForEach(weeks) { week in
                        SplitsRow(split: week, isRevealed: isRevealed)
                            .opacity(heldWeek == nil || heldWeek == week.id ? .opaque : .semiLowOpacity)
                            .onGeometryChange(for: CGFloat.self) { proxy in
                                proxy.frame(in: .named(Constants.space)).midY
                            } action: {
                                rowMids[week.id] = $0
                            }
                    }
                }
                .padding(.top, .spacing2x)
                .padding(.horizontal, .spacing1x)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacing205x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .coordinateSpace(.named(Constants.space))
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { cardHeight = $0 }
        .overlay {
            if allowsSelection, !isEmpty {
                BrightWidgetTouchLayerV5(touch: $touch)
            }
        }
        .onChange(of: touch) { resolveTouch() }
        .animation(.brightEaseInOut, value: heldWeek)
        .animation(.brightEaseInOut, value: isHoldingThisWeek)
        .modifier(BrightCardModifierV5(color: .defaultHomeCards))
        .brightRevealV5($isRevealed)
    }

    private enum Constants {
        static let space = "exerciseSplitsCard"
        static let largeRowHeight: CGFloat = 60
        static let mediumRowHeight: CGFloat = 48
    }
}

extension BrightExerciseSplitsWidgetV5 {
    // MARK: - Holding

    private func resolveTouch() {
        guard let touch else {
            heldWeek = nil
            isHoldingThisWeek = false
            return
        }
        let y = touch.y * cardHeight
        let rowsTop = weeks.compactMap { rowMids[$0.id] }.min().map { $0 - .spacing2x }
        guard isLarge, let rowsTop, y >= rowsTop else {
            guard !isHoldingThisWeek || heldWeek != nil else { return }
            heldWeek = nil
            isHoldingThisWeek = true
            BrightHaptic.light.play()
            return
        }
        let nearest = weeks.min { abs((rowMids[$0.id] ?? 0) - y) < abs((rowMids[$1.id] ?? 0) - y) }?.id
        guard nearest != heldWeek || isHoldingThisWeek else { return }
        isHoldingThisWeek = false
        heldWeek = nearest
        BrightHaptic.light.play()
    }
}

private struct SplitsPlot: View {
    let strengthPercent: Int
    let cardioPercent: Int
    let rowHeight: CGFloat
    let isRevealed: Bool

    @Environment(\.brightWidgetIsEmpty) private var isEmpty

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let boundary = boundary(in: width)

            VStack(spacing: .spacing0x) {
                pill("figure.strengthtraining.traditional", percent: strengthPercent, color: .strengthColor)
                    .padding(.leading, .spacing1x)
                    .padding(.trailing, isRevealed ? max(0, width - boundary) : max(0, width - .spacing1x))
                    .frame(height: rowHeight)

                pill("figure.run", percent: cardioPercent, color: .cardioColor)
                    .padding(.leading, isRevealed ? boundary : max(0, width - .spacing1x))
                    .padding(.trailing, .spacing1x)
                    .frame(height: rowHeight)
            }
            .animation(.brightBouncy, value: isRevealed)
            .overlay { grid(in: proxy.size) }
        }
        .frame(height: rowHeight * 2)
    }

    private func pill(_ symbol: String, percent: Int, color: Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: .squareCornerRadius, style: .continuous)
        return shape
            .fill(color.opacity(.ultraLowOpacity))
            .overlay {
                shape.strokeBorder(color.opacity(.veryLowOpacity), lineWidth: Constants.pillLineWidth)
            }
            .overlay {
                HStack(spacing: .spacing0x) {
                    Image(systemName: symbol)
                        .font(.system(size: Constants.symbolSize))
                        .foregroundStyle(color)

                    Spacer(minLength: .spacing1x)

                    HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                        BrightText(isEmpty ? .brightEmptyValue : isRevealed ? "\(percent)" : "\(percent)".zeroedDigits, size: .standout3, color: color)
                            .contentTransition(.numericText())
                        BrightText("%", size: .body1, color: color)
                    }
                }
                .padding(.horizontal, .spacing105x)
            }
            .clipShape(shape)
            .frame(height: Constants.pillHeight)
    }

    private func grid(in size: CGSize) -> some View {
        let color = Color.textColor.opacity(.ultraLowOpacity)
        let column = size.width / CGFloat(Constants.columnCount)

        return ZStack(alignment: .topLeading) {
            Rectangle()
                .strokeBorder(color, lineWidth: Constants.gridLineWidth)

            ForEach(1..<Constants.columnCount, id: \.self) { index in
                Rectangle()
                    .fill(color)
                    .frame(width: Constants.gridLineWidth)
                    .offset(x: column * CGFloat(index))
            }

            Path { path in
                path.move(to: CGPoint(x: 0, y: size.height / 2))
                path.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            }
            .stroke(color, style: StrokeStyle(lineWidth: Constants.gridLineWidth, dash: [Constants.gridDash]))
        }
    }

    private func fraction(of percent: Int) -> CGFloat {
        min(1, max(0, CGFloat(percent) / 100))
    }

    private func boundary(in width: CGFloat) -> CGFloat {
        guard width.isFinite, width > 0 else { return 0 }
        let smallest = Constants.minPillWidth + .spacing1x
        guard width > smallest * 2 else { return width / 2 }
        return min(max(width * fraction(of: strengthPercent), smallest), width - smallest)
    }

    private enum Constants {
        static let pillHeight: CGFloat = .spacing6x
        static let minPillWidth: CGFloat = 90
        static let pillLineWidth: CGFloat = 1
        static let gridLineWidth: CGFloat = 0.5
        static let gridDash: CGFloat = 3
        static let columnCount = 4
        static let symbolSize: CGFloat = 20
    }
}

private struct SplitsRow: View {
    let split: BrightExerciseSplitsWidgetV5.Week
    let isRevealed: Bool

    @Environment(\.brightWidgetIsEmpty) private var isEmpty

    var body: some View {
        HStack(spacing: .spacing2x) {
            BrightText(split.name, size: .body3, color: .lightTextColor)

            GeometryReader { proxy in
                let track = max(0, proxy.size.width - .spacing05x)
                HStack(spacing: .spacing05x) {
                    Capsule()
                        .fill(Color.strengthColor.opacity(.veryMinimalOpacity))
                        .frame(width: isRevealed && !isEmpty ? width(of: split.strengthFraction, in: track) : 0)
                    Capsule()
                        .fill(Color.cardioColor.opacity(.veryMinimalOpacity))
                        .frame(width: isRevealed && !isEmpty ? width(of: split.cardioFraction, in: track) : 0)
                }
                .animation(.brightBouncy, value: isRevealed)
            }
            .frame(height: Constants.rowBarHeight)

            BrightText(isEmpty ? .brightEmptyValue : split.ratio, size: .body3, color: .lightTextColor)
        }
    }

    private func width(of fraction: CGFloat, in track: CGFloat) -> CGFloat {
        guard fraction.isFinite else { return 0 }
        return max(0, track * fraction)
    }

    private enum Constants {
        static let rowBarHeight: CGFloat = 15
    }
}

#Preview {
    let weeks = [(0.60, "60/40"), (0.64, "64/36"), (0.70, "70/30"), (0.78, "78/22")].enumerated().map { index, week in
        BrightExerciseSplitsWidgetV5.Week(name: "Week \(index + 1)", strengthFraction: week.0, cardioFraction: 1 - week.0, ratio: week.1)
    }

    VStack(spacing: .spacing205x) {
        BrightExerciseSplitsWidgetV5(title: "Exercise", subtitle: "Past 4 weeks", strengthPercent: 68, cardioPercent: 32, weeks: weeks, size: .medium)
            .frame(width: 363, height: 174)

        BrightExerciseSplitsWidgetV5(title: "Exercise", subtitle: "Past 4 weeks", strengthPercent: 68, cardioPercent: 32, weeks: weeks, size: .large)
            .frame(width: 363, height: 363)
    }
    .padding(.spacing205x)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.defaultBackground)
}
