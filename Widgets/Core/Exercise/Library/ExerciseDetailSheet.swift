//
//  ExerciseDetailSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import Charts
import SwiftUI

struct ExerciseDetailSheet: View {
    let exercise: ExerciseDefinition

    private enum ChartRange: Int, CaseIterable, Identifiable {
        case threeMonths
        case sixMonths
        case year

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .threeMonths: "3M"
            case .sixMonths: "6M"
            case .year: "1Y"
            }
        }

        var weeks: Int {
            switch self {
            case .threeMonths: 13
            case .sixMonths: 26
            case .year: 52
            }
        }
    }

    @State private var range: ChartRange = .sixMonths

    private let statTileHeight: CGFloat = 67
    private let chartHeight: CGFloat = 150

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing4x) {
                header
                formCard
                statsGrid
                progressionCard
                howToCard
                historyCard
            }
            .padding(.top, .spacing2x)
            .padding(.bottom, .spacing4x)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: .spacing2x) {
            Image(systemName: exercise.category.symbol)
                .resizable()
                .scaledToFit()
                .fontWeight(.light)
                .frame(width: 40, height: 40)
                .foregroundStyle(exercise.category.accentColor)

            VStack(alignment: .leading, spacing: .spacing1x) {
                BrightText(exercise.name, size: .standout3)
                HStack(spacing: .spacing1x) {
                    muscleChip(exercise.equipmentLabel, color: .lightTextColor)
                    muscleChip(exercise.primaryMuscle.displayName, color: exercise.category.accentColor)
                    ForEach(exercise.secondaryMuscles.prefix(2)) { muscle in
                        muscleChip(muscle.displayName, color: .lightTextColor)
                    }
                }
            }
        }
    }

    private func muscleChip(_ title: String, color: Color) -> some View {
        BrightText(title, size: .body5, color: color)
            .padding(.horizontal, .spacing105x)
            .padding(.vertical, .spacing05x)
            .overlay {
                Capsule()
                    .strokeBorder(color.opacity(.minimalOpacity), lineWidth: 1)
            }
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText("Form", size: .body1)
            ExerciseFormViewer(tint: exercise.category.accentColor)
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    private var statsGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: .spacing2x), count: 2),
            spacing: .spacing2x
        ) {
            ForEach(exercise.records.indices, id: \.self) { i in
                statTile(exercise.records[i])
            }
        }
    }

    private func statTile(_ stat: ExerciseSessionStat) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                BrightText(stat.value, size: .standout3, weight: .regular)
                    .monospacedDigit()
                if let unit = stat.unit {
                    BrightText(unit, size: .body4, color: .lightTextColor)
                }
            }
            BrightText(stat.label, size: .body4, color: .semiLightTextColor)
        }
        .padding(.horizontal, .spacing2x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: statTileHeight)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius18))
    }

    private var progressionCard: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            HStack {
                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText("Progression", size: .body1)
                    BrightText(exercise.progressionMetric, size: .body3, color: .lightTextColor)
                }

                Spacer()

                HStack(spacing: .spacing05x) {
                    ForEach(ChartRange.allCases) { option in
                        Button {
                            withAnimation(.brightEaseInOut) { range = option }
                        } label: {
                            BrightText(
                                option.title,
                                size: .body4,
                                color: range == option ? .textColor : .lightTextColor
                            )
                            .padding(.horizontal, .spacing105x)
                            .padding(.vertical, .spacing05x)
                            .background(
                                Color.textColor.opacity(range == option ? .ultraLowOpacity : 0),
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            chart
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    private var chart: some View {
        let points = exercise.progression.filter { $0.weeksAgo < range.weeks }
        let accent = exercise.category.accentColor
        return Chart(points) { point in
            AreaMark(
                x: .value("Week", -point.weeksAgo),
                y: .value("Value", point.value)
            )
            .foregroundStyle(accent.opacity(.ultraLowOpacity))
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Week", -point.weeksAgo),
                y: .value("Value", point.value)
            )
            .foregroundStyle(accent)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) {
                AxisGridLine()
                    .foregroundStyle(Color.textColor.opacity(.ultraLowOpacity))
                AxisValueLabel()
                    .foregroundStyle(Color.lightTextColor)
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .frame(height: chartHeight)
    }

    private var howToCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText("How to", size: .body1)

            VStack(alignment: .leading, spacing: .spacing105x) {
                ForEach(exercise.instructions.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: .spacing105x) {
                        BrightText("\(i + 1)", size: .body3, color: exercise.category.accentColor, weight: .regular)
                            .monospacedDigit()
                            .frame(width: Constants.stepNumberWidth, alignment: .leading)
                        BrightText(exercise.instructions[i], size: .body3, color: .semiLightTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText("Recent", size: .body1)

            VStack(spacing: .spacing0x) {
                ForEach(exercise.history) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: .spacing05x) {
                            BrightText(entry.summary, size: .body2, color: .semiLightTextColor, weight: .regular)
                                .monospacedDigit()
                            BrightText(entry.bestSet, size: .body3, color: .lightTextColor)
                                .monospacedDigit()
                        }
                        Spacer(minLength: .spacing2x)
                        BrightText(entry.date, size: .body3, color: .lightTextColor)
                    }
                    .padding(.vertical, .spacing105x)

                    if entry.id != exercise.history.last?.id {
                        Rectangle()
                            .fill(Color.textColor.opacity(.ultraLowOpacity))
                            .frame(height: 1)
                    }
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    private class Constants {
        static let stepNumberWidth: CGFloat = 18
    }
}

#Preview {
    ExerciseDetailSheet(exercise: ExerciseDemoLibrary.strength[0])
}

#Preview("Cardio") {
    ExerciseDetailSheet(exercise: ExerciseDemoLibrary.cardio[0])
}
