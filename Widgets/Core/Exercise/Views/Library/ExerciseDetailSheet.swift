//
//  ExerciseDetailSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import Charts
import SwiftUI

nonisolated struct ExerciseProgressionSample: Identifiable {
    let id: Int
    let value: Double
}

struct ExerciseDetailSheet: View {
    let exercise: ExerciseDefinition

    private enum Timescale: String, CaseIterable, Identifiable {
        case oneWeek = "1W"
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"

        var id: String { rawValue }

        var days: Int {
            switch self {
            case .oneWeek: 7
            case .oneMonth: 30
            case .threeMonths: 90
            case .sixMonths: 180
            case .oneYear: 365
            }
        }
    }

    @State private var selectedPage = 0
    @State private var timescale: Timescale = .oneMonth
    @State private var isFormExpanded = false
    @State private var summaryScrollPosition = ScrollPosition()

    var body: some View {
        GeometryReader { proxy in
            pager(
                expandedFormHeight: proxy.size.height
                    + proxy.safeAreaInsets.top
                    + proxy.safeAreaInsets.bottom,
                topInset: proxy.safeAreaInsets.top
            )
        }
    }

    private func pager(expandedFormHeight: CGFloat, topInset: CGFloat) -> some View {
        BrightSwipePageView(
            pages: [
                SwipePage(title: "Summary", systemImage: "ellipsis.calendar"),
                SwipePage(title: "Impact", systemImage: "arrow.down.circle.fill"),
                SwipePage(title: "Data", systemImage: "chart.xyaxis.line"),
            ],
            fakeLargeTitle: "",
            showInlineTabs: !isFormExpanded,
            disableHorizontalScroll: isFormExpanded,
            collapsesTitleToToolbar: false,
            verticalScrollPosition: $summaryScrollPosition,
            scrollControlledPageIndex: 0,
            verticalScrollDisabledPageIndex: isFormExpanded ? 0 : nil,
            bottomSafeArea: !isFormExpanded,
            navigationBarVisibility: isFormExpanded ? .hidden : .visible,
            selectedIndex: $selectedPage
        ) { index in
            Group {
                switch index {
                case 0: summaryPage(expandedFormHeight: expandedFormHeight, topInset: topInset)
                case 1: impactPage
                default: dataPage
                }
            }
            .padding(.top, isFormExpanded ? -Constants.reservedPillRow : .spacing0x)
        }
        .ignoresSafeArea(edges: isFormExpanded ? .top : [])
        .toolbar {
            ToolbarItem(placement: .principal) {
                ExerciseInlineTitle(title: exercise.name, file: #file)
            }
        }
        .onChange(of: isFormExpanded) { _, expanded in
            if expanded {
                withAnimation(.brightEaseInOut) {
                    summaryScrollPosition.scrollTo(edge: .top)
                }
            }
        }
    }

    // MARK: - Summary

    private func summaryPage(expandedFormHeight: CGFloat, topInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            formCard(expandedHeight: expandedFormHeight)
            muscleChips
            statsSection
            progressionCard
        }
        .padding(.top, isFormExpanded ? -topInset : .spacing3x)
        .padding([.horizontal, .bottom], .spacing3x)
    }

    private var muscleChips: some View {
        HStack(spacing: .spacing1x) {
            ForEach(tags, id: \.self) { tag in
                muscleChip(tag)
            }
        }
    }

    private var tags: [String] {
        [exercise.category.displayName, exercise.primaryMuscle.displayName]
            + exercise.secondaryMuscles.prefix(1).map(\.displayName)
    }

    private func muscleChip(_ title: String) -> some View {
        BrightText(title, size: .body1, color: .lightTextColor)
            .padding(.horizontal, .spacing105x)
            .padding(.vertical, .spacing05x)
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous)
                    .strokeBorder(Color.lightTextColor.opacity(.minimalOpacity), lineWidth: 1)
            }
    }

    private func formCard(expandedHeight: CGFloat) -> some View {
        ExerciseFormViewer(
            tint: exercise.category.accentColor,
            isExpanded: $isFormExpanded,
            expandedHeight: expandedHeight
        )
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText("Stats", size: .heading)

            ExerciseStatTileGrid(tiles: ExerciseDemoData.detailStats)
        }
    }

    private var progressionCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack {
                BrightText("Progression", size: .body1)

                Spacer()

                Menu {
                    Picker("Timescale", selection: $timescale) {
                        ForEach(Timescale.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    timescalePill
                }
                .buttonStyle(.plain)
                .modifier(GlassEffect(shape: .capsule))
                .padding(.trailing, .spacing05x)
            }

            HStack(alignment: .center, spacing: .spacing1x) {
                Image(systemName: "arrow.up")
                    .font(.system(size: Constants.progressionArrowSize, weight: .light))
                    .foregroundStyle(Color.defaultGreen)

                HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
                    BrightText("5.5", size: .huge, weight: .light)
                        .monospacedDigit()
                    BrightText("KG / mnth", size: .body2, color: .lightTextColor)
                }
            }

            chart
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    private var timescalePill: some View {
        ZStack {
            BrightText("1W", size: BrightButtonSizes.small.defaultFontSize)
                .hidden()

            BrightText(timescale.rawValue, size: BrightButtonSizes.small.defaultFontSize)
        }
        .padding(.horizontal, .spacing105x)
        .frame(height: BrightButtonSizes.small.rawValue)
        .compositingGroup()
    }

    private var chart: some View {
        let points = Array(ExerciseDemoData.detailProgression.suffix(timescale.days))
        let top = max(20, (((points.map(\.value).max() ?? 100) / 20).rounded(.up)) * 20)

        return Chart {
            ForEach(points) { point in
                AreaMark(
                    x: .value("Day", point.id),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.defaultGreen.opacity(.semiLowOpacity),
                            Color.defaultGreen.opacity(0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Day", point.id),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Color.defaultGreen)
                .lineStyle(StrokeStyle(lineWidth: 1.5, lineJoin: .round))
            }

            RuleMark(y: .value("Mid", top / 2))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(Color.textColor.opacity(.minimalOpacity))
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(values: [0, top]) { value in
                AxisValueLabel {
                    if let number = value.as(Double.self) {
                        BrightText(
                            number == 0 ? "0KG" : "\(Int(number))",
                            size: .body4,
                            color: .lightTextColor
                        )
                    }
                }
            }
        }
        .chartXScale(domain: (points.first?.id ?? 0) ... (points.last?.id ?? 1))
        .chartYScale(domain: 0 ... top)
        .animation(.brightEaseInOut, value: timescale)
        .frame(height: Constants.chartHeight)
    }

    // MARK: - Impact

    private var impactPage: some View {
        VStack(spacing: .spacing3x) {
            BrightImpactWidget(
                type: .summary,
                title: "Summary",
                data: ExerciseDemoData.detailImpact,
                cardColor: .defaultSheetModalCards
            )
        }
        .padding(.spacing3x)
    }

    // MARK: - Data

    private var dataPage: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing105x) {
                Image(systemName: "backward.end.alt")
                    .font(.system(size: Constants.statIconSize, weight: .medium))
                    .foregroundStyle(Color.textColor)
                BrightText("Workout history", size: .body1, weight: .regular)
            }
            .padding(.leading, .spacing2x)

            ExerciseSetHistoryList(groups: ExerciseDemoData.detailHistory)
        }
        .padding(.spacing3x)
    }

    private class Constants {
        static let reservedPillRow: CGFloat = SwipePageConstants.pillHeight + .spacing2x
        static let chartHeight: CGFloat = 130
        static let statIconSize: CGFloat = 18
        static let progressionArrowSize: CGFloat = 28
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailSheet(exercise: ExerciseDemoLibrary.strength[0])
            .background(Color.defaultSheetBackground.ignoresSafeArea())
    }
}

#Preview("Cardio") {
    NavigationStack {
        ExerciseDetailSheet(exercise: ExerciseDemoLibrary.cardio[0])
            .background(Color.defaultSheetBackground.ignoresSafeArea())
    }
}
