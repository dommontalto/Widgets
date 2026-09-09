//
//  ExerciseSplitBar.swift
//  Widgets
//
//  Created by Dom Montalto on 27/8/2026.
//

import SwiftUI

struct ExerciseSplitBar: View {
    let strengthPercent: Int
    let cardioPercent: Int

    var body: some View {
        VStack(spacing: .spacing105x) {
            HStack(spacing: .spacing0x) {
                percentLabel(strengthPercent, color: .defaultPink)
                    .frame(maxWidth: .infinity)
                percentLabel(cardioPercent, color: .defaultSkyBlue)
                    .frame(maxWidth: .infinity)
            }
            bar
        }
    }

    private func percentLabel(_ value: Int, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
            BrightText("\(value)", size: .standout1, color: color)
            BrightText("%", size: .body3, color: color)
        }
    }

    private var bar: some View {
        GeometryReader { proxy in
            let inset: CGFloat = .spacing05x
            let trackWidth = max(0, proxy.size.width - inset * 2 - Constants.notchWidth - inset * 2)
            HStack(spacing: inset) {
                segment("Strength", color: .defaultPink, width: width(of: strengthPercent, in: trackWidth))
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(Color.textColor)
                    .frame(width: Constants.notchWidth, height: 21)
                segment("Cardio", color: .defaultSkyBlue, width: width(of: cardioPercent, in: trackWidth))
            }
            .padding(inset)
        }
        .frame(height: Constants.barHeight)
        .overlay {
            RoundedRectangle(cornerRadius: Constants.barCornerRadius, style: .continuous)
                .strokeBorder(Color.textColor.opacity(.minimalOpacity), lineWidth: 0.5)
        }
    }

    private func segment(_ title: String, color: Color, width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: Constants.barCornerRadius - .spacing05x, style: .continuous)
            .fill(color.opacity(.veryMinimalOpacity))
            .frame(width: width)
            .overlay {
                BrightText(title, size: .body3, color: color)
            }
    }

    private func width(of percent: Int, in track: CGFloat) -> CGFloat {
        max(0, track * CGFloat(percent) / 100)
    }

    private enum Constants {
        static let barHeight: CGFloat = .spacing6x
        static let barCornerRadius: CGFloat = 13
        static let notchWidth: CGFloat = 2
    }
}

struct ExerciseSplitPlot: View {
    let strengthPercent: Int
    let cardioPercent: Int

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let boundary = boundary(in: width)

            VStack(spacing: .spacing0x) {
                pill("figure.strengthtraining.traditional", percent: strengthPercent, color: .defaultPink)
                    .padding(.leading, .spacing1x)
                    .padding(.trailing, max(0, width - boundary))
                    .frame(height: Constants.rowHeight)

                pill("figure.run", percent: cardioPercent, color: .defaultSkyBlue)
                    .padding(.leading, boundary)
                    .padding(.trailing, .spacing1x)
                    .frame(height: Constants.rowHeight)
            }
            .overlay { grid(in: proxy.size) }
        }
        .frame(height: Constants.rowHeight * 2)
    }

    private func pill(_ symbol: String, percent: Int, color: Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous)
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
                        BrightText("\(percent)", size: .standout3, color: color)
                        BrightText("%", size: .body1, color: color)
                    }
                }
                .padding(.horizontal, .spacing105x)
            }
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

    // Both pills are cut at the same x, so the strength pill's trailing edge meets
    // the cardio pill's leading edge, and neither falls below a legible width.
    private func boundary(in width: CGFloat) -> CGFloat {
        guard width.isFinite, width > 0 else { return 0 }
        let smallest = Constants.minPillWidth + .spacing1x
        guard width > smallest * 2 else { return width / 2 }
        return min(max(width * fraction(of: strengthPercent), smallest), width - smallest)
    }

    private enum Constants {
        static let rowHeight: CGFloat = 60
        static let pillHeight: CGFloat = .spacing6x
        static let minPillWidth: CGFloat = 90
        static let pillLineWidth: CGFloat = 1
        static let gridLineWidth: CGFloat = 0.5
        static let gridDash: CGFloat = 3
        static let columnCount = 4
        static let symbolSize: CGFloat = 20
    }
}

struct ExerciseSplitRow: View {
    let split: ExerciseWeekLoad

    var body: some View {
        HStack(spacing: .spacing2x) {
            BrightText(split.name, size: .body3, color: .lightTextColor)

            GeometryReader { proxy in
                let track = max(0, proxy.size.width - .spacing05x)
                HStack(spacing: .spacing05x) {
                    Capsule()
                        .fill(Color.defaultPink.opacity(.veryMinimalOpacity))
                        .frame(width: width(of: split.strengthFraction, in: track))
                    Capsule()
                        .fill(Color.defaultSkyBlue.opacity(.veryMinimalOpacity))
                        .frame(width: width(of: split.cardioFraction, in: track))
                }
            }
            .frame(height: Constants.rowBarHeight)

            BrightText(split.ratio, size: .body3, color: .lightTextColor)
        }
    }

    // The first layout pass reports no width, and a fraction can arrive as a
    // zero-over-zero NaN, either of which is an invalid frame.
    private func width(of fraction: CGFloat, in track: CGFloat) -> CGFloat {
        guard fraction.isFinite else { return 0 }
        return max(0, track * fraction)
    }

    private enum Constants {
        static let rowBarHeight: CGFloat = 15
    }
}

#Preview {
    VStack(spacing: .spacing4x) {
        ExerciseSplitPlot(strengthPercent: 45, cardioPercent: 55)
        ExerciseSplitBar(strengthPercent: 45, cardioPercent: 55)
        ExerciseSplitRow(split: ExerciseDemoData.trainingLoad.weeks[0])
    }
    .padding(.spacing4x)
}
