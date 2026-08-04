//
//  ExerciseProgramPhaseWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 22/7/2026.
//

import SwiftUI

struct ExerciseProgramPhaseWidget: View {
    private let barHeight: CGFloat = 29
    private let labelWidth: CGFloat = 52

    @State private var status = ExerciseDemoData.programStatus

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            HStack(spacing: .spacing1x) {
                Image(systemName: "ellipsis.calendar")
                    .font(.standard(size: .body1, weight: .light))
                    .foregroundStyle(Color.textColor)
                BrightText("Mesocycle week:", size: .body1)
            }

            BrightText("\(status.mesocycleWeek)/\(status.mesocycleLength)", size: .standout1)
                .monospacedDigit()
                .padding(.bottom, .spacing2x)

            row("Macro") { macroBar }
            dashedDivider
            row("Meso") { mesoBar }
            dashedDivider
            row("Micro") { microBar }

            VStack(alignment: .leading, spacing: .spacing2x) {
                Image(systemName: "sparkles")
                    .font(.standard(size: .standout3, weight: .light))
                    .foregroundStyle(Color.textColor)

                BrightText(status.note, size: .body2, color: .semiLightTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: .spacing05x) {
                    ForEach(status.bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: .spacing1x) {
                            BrightText("\u{2022}", size: .body3, color: .semiLightTextColor)
                            BrightText(bullet, size: .body3, color: .semiLightTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.top, .spacing2x)
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
    }

    private func row(_ label: String, @ViewBuilder bar: () -> some View) -> some View {
        HStack(spacing: .spacing0x) {
            BrightText(label, size: .body3)
                .frame(width: labelWidth, alignment: .leading)
            bar()
        }
    }

    private var macroBar: some View {
        GeometryReader { proxy in
            HStack(spacing: .spacing0x) {
                UnevenRoundedRectangle(
                    cornerRadii: .init(bottomTrailing: .cornerRadius10, topTrailing: .cornerRadius10),
                    style: .continuous
                )
                .fill(Color.defaultGreen)
                .frame(width: proxy.size.width * status.macroProgress)

                BrightText(status.macroLabel, size: .body3)
                    .frame(maxWidth: .infinity)
            }
            .background(Color.defaultGreen.opacity(.veryMinimalOpacity))
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius10, style: .continuous))
        }
        .frame(height: barHeight)
    }

    private var mesoBar: some View {
        HStack(spacing: .spacing2x) {
            ForEach(0..<status.mesoCount, id: \.self) { i in
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Color.defaultSkyBlue.opacity(.veryMinimalOpacity)
                        UnevenRoundedRectangle(
                            cornerRadii: .init(bottomTrailing: .cornerRadius10, topTrailing: .cornerRadius10),
                            style: .continuous
                        )
                        .fill(Color.defaultSkyBlue)
                        .frame(width: proxy.size.width * mesoFraction(i))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius10, style: .continuous))
                }
                .frame(height: barHeight)
            }
        }
    }

    private func mesoFraction(_ index: Int) -> Double {
        if index < status.mesoCompleted { return 1 }
        if index == status.mesoCompleted { return status.mesoCurrentProgress }
        return 0
    }

    private var microBar: some View {
        HStack(spacing: .spacing2x) {
            ForEach(0..<status.microWeeks, id: \.self) { week in
                HStack(spacing: .spacing05x) {
                    ForEach(0..<status.microDaysPerWeek, id: \.self) { day in
                        microPill(isDone: week * status.microDaysPerWeek + day < status.microCompletedDays)
                    }
                }
            }
        }
    }

    private func microPill(isDone: Bool) -> some View {
        RoundedRectangle(cornerRadius: .cornerRadius10, style: .continuous)
            .fill(isDone ? Color.defaultOrange : .clear)
            .overlay {
                if !isDone {
                    RoundedRectangle(cornerRadius: .cornerRadius10, style: .continuous)
                        .strokeBorder(Color.defaultOrange.opacity(.veryLowOpacity), lineWidth: 0.5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: barHeight)
    }

    private var dashedDivider: some View {
        DashedLine()
            .stroke(Color.textColor.opacity(.ultraLowOpacity), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
            .frame(height: 1)
            .padding(.vertical, .spacing05x)
    }
}

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

#Preview {
    ExerciseProgramPhaseWidget()
        .padding(.spacing4x)
}
