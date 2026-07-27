//
//  HeartWorkoutSummarySheet.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import SwiftUI

enum HeartWorkoutSummaryTab: Int, CaseIterable {
    case summary
    case heart
    case performance

    var displayTitle: String {
        switch self {
        case .summary: "Summary"
        case .heart: "Heart"
        case .performance: "Performance"
        }
    }

    var systemImage: String {
        switch self {
        case .summary: "ellipsis.calendar"
        case .heart: "heart.fill"
        case .performance: "chart.xyaxis.line"
        }
    }
}

struct HeartWorkoutSummarySheet: View {
    let workout: HeartWorkoutSummaryData

    @State private var selectedIndex = HeartWorkoutSummaryTab.summary.rawValue
    @State private var selectedGraphSecond: Double?
    @State private var isMapExpanded = false

    var body: some View {
        // Measured out here rather than inside the pager: along the scroll axis a
        // containerRelativeFrame resolves as unbounded. The bottom inset is added
        // back so the expanded map reaches the screen edge, not the safe area.
        GeometryReader { proxy in
            sheet(expandedMapHeight: proxy.size.height + proxy.safeAreaInsets.bottom)
        }
    }

    private func sheet(expandedMapHeight: CGFloat) -> some View {
        BrightPageSheetView(
            horizontalPadding: .spacing0x,
            bottomSafeArea: !isMapExpanded
        ) {
            BrightSwipePageView(
                pages: HeartWorkoutSummaryTab.allCases.map {
                    SwipePage(title: $0.displayTitle, systemImage: $0.systemImage)
                },
                fakeLargeTitle: isMapExpanded ? "" : workout.title,
                titleSize: .standout4,
                titleWeight: .medium,
                titleSubtitle: isMapExpanded ? nil : AnyView(subtitle),
                pillFollowMaxShift: Constants.pillFollowMaxShift,
                showInlineTabs: !isMapExpanded,
                disableHorizontalScroll: isMapExpanded,
                collapsesTitleToToolbar: !isMapExpanded,
                verticalScrollDisabledPageIndex: isMapExpanded
                ? HeartWorkoutSummaryTab.summary.rawValue
                    : nil,
                bottomSafeArea: !isMapExpanded,
                navigationBarVisibility: isMapExpanded ? .hidden : .visible,
                selectedIndex: $selectedIndex
            ) { index in
                tabContent(
                    for: HeartWorkoutSummaryTab(rawValue: index) ?? .summary,
                    expandedMapHeight: expandedMapHeight
                )
                    .padding(.horizontal, .spacing3x)
                    // Collapsed: matches HeartView / SleepView, where
                    // BrightCalendarWidget's own top padding sits under the pills.
                    // Expanded: cancels the row the pager reserves for the pills so
                    // the map reaches the top of the page.
                    .padding(.top, isMapExpanded ? -Constants.reservedPillRow : .spacing2x)
                    .padding(.bottom, isMapExpanded ? .spacing0x : .spacing3x)
            }
        }
    }

    private var subtitle: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            HStack(spacing: .spacing2x) {
                if let startTime = workout.startTime, let endTime = workout.endTime {
                    BrightText(timeRange(from: startTime, to: endTime), size: .body2)
                }

                if let temperature = workout.temperature {
                    HStack(spacing: .spacing1x) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: Constants.sourceIconSize))
                            .foregroundStyle(Color.defaultYellow)
                            .frame(width: Constants.sourceIconBox, height: Constants.sourceIconBox)

                        BrightText(temperature, size: .body2)
                    }
                }
            }

            if let source = workout.source {
                HStack(spacing: .spacing1x) {
                    Image(systemName: "applewatch")
                        .font(.system(size: Constants.sourceIconSize))
                        .foregroundStyle(Color.textColor)
                        .frame(width: Constants.sourceIconBox, height: Constants.sourceIconBox)

                    BrightText(source, size: .body2)
                }
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: HeartWorkoutSummaryTab, expandedMapHeight: CGFloat) -> some View {
        switch tab {
        case .summary: summaryTab(expandedMapHeight: expandedMapHeight)
        case .heart: heartTab
        case .performance: performanceTab
        }
    }

    private func summaryTab(expandedMapHeight: CGFloat) -> some View {
        HeartWorkoutOverviewWidget(
            duration: workout.duration,
            distanceKm: workout.distance.map { ($0.value ?? 0) / 1000 },
            altitudeGainMetres: workout.altitudeGain?.value,
            avgPaceSecondsPerKm: workout.avgPaceSecondsPerKm,
            caloriesBurnt: workout.energyOut,
            hrAvg: workout.hrAvg,
            routeLatitudes: workout.routeLatitudes,
            routeLongitudes: workout.routeLongitudes,
            routeZoneIndexes: workout.routeZoneIndexes,
            heartGraph: workout.heartGraph,
            altitudeGraph: workout.altitudeGraph,
            paceGraph: workout.paceGraph,
            cadenceGraph: workout.cadenceGraph,
            isMapExpanded: $isMapExpanded,
            expandedMapHeight: expandedMapHeight
        )
    }

    private var heartTab: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            HeartWorkoutSummaryBreakdownWidget(
                data: workout.breakdown ?? HeartWorkoutSummaryBreakdownData()
            )

            HeartWorkoutSummaryGraphWidget(
                hrAvg: workout.hrAvg ?? 0,
                zoneAvg: workout.zoneAvg ?? 0,
                duration: workout.duration ?? TimeDuration(),
                startDate: workout.startTime ?? "",
                endDate: workout.endTime ?? "",
                data: workout.heartGraph ?? HeartWorkoutSummaryHeartGraphData()
            )

            HeartWorkoutSummaryPostWorkoutWidget(
                data: workout.postWorkoutHeartGraph ?? HeartWorkoutSummaryPostWorkoutHeartGraphData()
            )
        }
    }

    private var performanceTab: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            HeartWorkoutPerformanceGraphWidget(
                hrAvg: workout.hrAvg ?? 0,
                duration: workout.duration ?? TimeDuration(),
                avgPace: workout.avgPaceSecondsPerKm ?? 0,
                altitudeGain: workout.altitudeGain ?? Amount(unit: "M", value: 0),
                data: HeartWorkoutCombinedGraphData(
                    heartData: workout.heartGraph ?? HeartWorkoutSummaryHeartGraphData(),
                    altitudeData: workout.altitudeGraph ?? HeartWorkoutSummaryAltitudeGraphData(),
                    paceData: workout.paceGraph ?? HeartWorkoutSummaryPaceGraphData(),
                    cadenceData: workout.cadenceGraph ?? HeartWorkoutSummaryCadenceGraphData()
                ),
                selectedSecond: $selectedGraphSecond
            )

            if let splits = workout.splits {
                HeartWorkoutSplitWidget(data: splits)
            }

            if let cardioFitness = workout.cardioFitness {
                HeartCardioFitnessWidget(data: cardioFitness, showSecondaryLabel: false, sheet: true)
            }
        }
    }

    private func timeRange(from startTime: String, to endTime: String) -> String {
        let start = startTime.isoStringToDate()
        let end = endTime.isoStringToDate()

        return start.stringFromDate(strFormatter: "h:mm")
            + " - " + end.stringFromDate(strFormatter: "h:mm")
            + " " + end.stringFromDate(strFormatter: "a").uppercased()
    }

    private enum Constants {
        /// The pill-row slot BrightSwipePageView keeps above every page, plus the
        /// stack spacing under it.
        static let reservedPillRow: CGFloat = SwipePageConstants.pillHeight + .spacing2x
        static let pillFollowMaxShift: CGFloat = .spacing12x + .spacing4x
        static let sourceIconSize: CGFloat = 20
        static let sourceIconBox: CGFloat = 24
    }
}

#Preview {
    HeartWorkoutSummarySheet(workout: HeartDemoData.workout)
}
