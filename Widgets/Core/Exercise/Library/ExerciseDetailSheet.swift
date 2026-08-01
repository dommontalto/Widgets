//
//  ExerciseDetailSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import Charts
import SwiftUI

nonisolated struct ExerciseStatTile: Identifiable {
    let label: String
    let value: String
    let unit: String
    let symbol: String
    let color: Color

    var id: String { label }
}

nonisolated struct ExerciseHistorySet: Identifiable {
    let id = UUID()
    let label: String?
    let reps: String
    let weight: String

    var isWarmUp: Bool { label == nil }
}

nonisolated struct ExerciseHistorySession: Identifiable {
    let date: String
    var prLabel: String?
    let sets: [ExerciseHistorySet]

    var id: String { date }
}

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
            pager(expandedFormHeight: proxy.size.height + proxy.safeAreaInsets.bottom)
        }
    }

    private func pager(expandedFormHeight: CGFloat) -> some View {
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
                case 0: summaryPage(expandedFormHeight: expandedFormHeight)
                case 1: impactPage
                default: dataPage
                }
            }
            .padding(.top, isFormExpanded ? -Constants.reservedPillRow : .spacing0x)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                BrightText(exercise.name, size: .subheading)
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

    private func summaryPage(expandedFormHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            formCard(expandedHeight: expandedFormHeight)
            muscleChips
            statsSection
            progressionCard
        }
        .padding(.top, isFormExpanded ? .spacing0x : .spacing1x)
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

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: .spacing2x + .spacing05x), count: 2),
                spacing: .spacing2x + .spacing05x
            ) {
                ForEach(ExerciseDemoData.detailStats) { stat in
                    statTile(stat)
                }
            }
        }
    }

    private func statTile(_ stat: ExerciseStatTile) -> some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            Image(systemName: stat.symbol)
                .font(.system(size: Constants.statIconSize, weight: .regular))
                .foregroundStyle(stat.color)

            BrightText(stat.label, size: .body2)

            Spacer(minLength: .spacing0x)

            HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                BrightText(stat.value, size: .huge, weight: .light)
                    .monospacedDigit()
                BrightText(stat.unit, size: .subheading, color: .lightTextColor)
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(1, contentMode: .fit)
        .modifier(CardModifier(color: .defaultSheetModalCards))
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
        .padding(.top, .spacing1x)
        .padding(.horizontal, .spacing3x)
        .padding(.bottom, .spacing4x)
    }

    // MARK: - Data

    private var dataPage: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing105x) {
                Image(systemName: "backward.end.alt")
                    .font(.system(size: Constants.statIconSize, weight: .medium))
                    .foregroundStyle(Color.textColor)
                BrightText("Session history", size: .body1, weight: .regular)
            }
            .padding(.leading, .spacing2x)

            VStack(spacing: .spacing3x) {
                ForEach(ExerciseDemoData.detailHistory) { session in
                    historyCard(session)
                }
            }
        }
        .padding(.top, .spacing1x)
        .padding(.horizontal, .spacing3x)
        .padding(.bottom, .spacing4x)
    }

    private func historyCard(_ session: ExerciseHistorySession) -> some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            HStack(spacing: .spacing105x) {
                BrightText(session.date, size: .body2, color: .lightTextColor)

                Spacer()

                if let prLabel = session.prLabel {
                    BrightText(prLabel, size: .body2, color: .lightTextColor)
                    prBadge
                } else {
                    BrightText("Weight PR", size: .body2, color: .lightTextColor)
                        .hidden()
                    prBadge
                        .hidden()
                }
            }
            .padding(.vertical, .spacing2x)

            ForEach(session.sets) { set in
                historyRow(set, weightTemplate: weightTemplate(for: session))

                if set.id != session.sets.last?.id {
                    BrightDivider()
                }
            }
        }
        .padding(.horizontal, .spacing3x)
        .padding(.bottom, .spacing1x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    private var prBadge: some View {
        ZStack {
            Image(ImageNames.exerciseRecordHexagonGoldV5)
                .resizable()
                .scaledToFit()

            Image(systemName: "trophy.fill")
                .font(.system(size: Constants.prBadgeIconSize, weight: .regular))
                .foregroundStyle(Color.defaultBlack)
                .blendMode(.overlay)
        }
        .frame(width: Constants.prBadgeWidth, height: Constants.prBadgeHeight)
    }

    private func weightTemplate(for session: ExerciseHistorySession) -> String {
        session.sets.map(\.weight).max(by: { $0.count < $1.count }) ?? ""
    }

    private func historyRow(_ set: ExerciseHistorySet, weightTemplate: String) -> some View {
        HStack(spacing: .spacing2x) {
            if set.isWarmUp {
                Image(systemName: "figure.cooldown")
                    .font(.system(size: Constants.statIconSize, weight: .light))
                    .foregroundStyle(Color.defaultGreen)
                    .frame(width: Constants.setLabelWidth, alignment: .leading)
            } else {
                BrightText(set.label ?? "", size: .subheading)
                    .monospacedDigit()
                    .frame(width: Constants.setLabelWidth, alignment: .leading)
            }

            Spacer()

            BrightText(set.reps, size: .body2, color: .semiLightTextColor, weight: .regular)
                .monospacedDigit()

            Rectangle()
                .fill(Color.textColor.opacity(.minimalOpacity))
                .frame(width: 1, height: Constants.setDividerHeight)

            ZStack(alignment: .trailing) {
                BrightText(weightTemplate, size: .body2, weight: .regular)
                    .monospacedDigit()
                    .hidden()

                BrightText(set.weight, size: .body2, color: .semiLightTextColor, weight: .regular)
                    .monospacedDigit()
            }
            .lineLimit(1)
        }
        .padding(.vertical, .spacing2x)
    }

    private class Constants {
        static let reservedPillRow: CGFloat = SwipePageConstants.pillHeight + .spacing2x
        static let chartHeight: CGFloat = 130
        static let statIconSize: CGFloat = 18
        static let progressionArrowSize: CGFloat = 28
        static let setLabelWidth: CGFloat = 24
        static let setDividerHeight: CGFloat = 16
        static let prBadgeWidth: CGFloat = 30
        static let prBadgeHeight: CGFloat = 33
        static let prBadgeIconSize: CGFloat = 13
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
