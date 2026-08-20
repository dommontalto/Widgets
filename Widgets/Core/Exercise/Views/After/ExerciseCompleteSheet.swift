//
//  ExerciseCompleteSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import SwiftUI

enum ExerciseCompleteTab: Int, CaseIterable {
    case summary
    case heart
    case performance

    var title: String {
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

struct ExerciseCompleteSheet: View {
    // A workout that holds both lifting and cardio arrives as one session per
    // part, and the picker above the title walks between them.
    let sessions: [ExerciseCompleteSession]

    var chrome: ExercisePageChrome = .sheet

    // Ends the whole run. Only the flow can do that from a pushed leg, where
    // `dismiss` would pop back instead.
    var onClose: (() -> Void)?

    @State private var selectedIndex = ExerciseCompleteTab.summary.rawValue
    @State private var selectedGraphSecond: Double?
    @State private var showingMap = false
    @State private var openedExerciseName: String?
    @State private var selectedPart = 0
    // Nil until a step is tapped, so the strip opens where the demo put it.
    @State private var selectedInterval: Int?

    private var session: ExerciseCompleteSession {
        sessions[min(selectedPart, sessions.count - 1)]
    }

    private var workout: HeartWorkoutSummaryResponseData { session.workout }

    private var intervalIndex: Binding<Int> {
        Binding(
            get: { selectedInterval ?? session.intervals?.selectedIndex ?? 0 },
            set: { selectedInterval = $0 }
        )
    }

    private var currentStep: ExerciseCompleteIntervalStep? {
        guard let steps = session.intervals?.steps else { return nil }
        let index = intervalIndex.wrappedValue
        return steps.indices.contains(index) ? steps[index] : nil
    }

    // The finish carries no numbers of its own, so it falls back to the run's.
    private var summaryMetrics: [ExerciseCompleteMetric] {
        currentStep?.metrics ?? session.metrics
    }

    // The pushed map can only show a part that has a route, so a lifting part
    // drops out of the picker for as long as the map is open.
    private var visibleParts: [Int] {
        guard showingMap else { return Array(sessions.indices) }
        return sessions.indices.filter { sessions[$0].workout.hasRoute }
    }

    var body: some View {
        page
    }

    // MARK: - Chrome

    @ViewBuilder
    private func container<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        switch chrome {
        case .sheet:
            BrightPageSheetView(
                horizontalPadding: .spacing0x,
                trailing: { partPicker },
                content: { content() }
            )
        case .pushed:
            BrightPageView(
                horizontalPadding: .spacing0x,
                toolbar: {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            onClose?()
                        } label: {
                            Label("Close", systemImage: "xmark")
                                .labelStyle(.iconOnly)
                        }
                    }

                    partPicker
                },
                content: { content() }
            )
        }
    }

    private var page: some View {
        container {
            BrightSwipePageView(
                pages: ExerciseCompleteTab.allCases.map {
                    SwipePage(title: $0.title, systemImage: $0.systemImage)
                },
                fakeLargeTitle: workout.title ?? "",
                titleSize: .standout4,
                titleWeight: .regular,
                titleSubtitle: AnyView(subtitle),
                pillFollowMaxShift: Constants.pillFollowMaxShift,
                selectedIndex: $selectedIndex
            ) { index in
                tabContent(for: ExerciseCompleteTab(rawValue: index) ?? .summary)
                    .padding(.horizontal, .spacing3x)
                    .padding(.top, .spacing2x + .spacing05x)
                    .padding(.bottom, .spacing3x)
            }
            // Declared on the content rather than on the container: the sheet
            // makes its own NavigationStack, and a destination hung outside it
            // never fires.
            .navigationDestination(isPresented: $showingMap) {
                ExerciseCompleteMapWidget(
                    routeLatitudes: workout.routeLatitudes,
                    routeLongitudes: workout.routeLongitudes,
                    routeZoneIndexes: workout.routeZoneIndexes,
                    duration: workout.duration,
                    hrAvg: workout.hrAvg,
                    altitudeGainMetres: workout.altitudeGain?.value,
                    avgPaceSecondsPerKm: workout.avgPaceSecondsPerKm,
                    heartGraph: workout.heartGraph,
                    altitudeGraph: workout.altitudeGraph,
                    paceGraph: workout.paceGraph,
                    cadenceGraph: workout.cadenceGraph,
                    isFullScreen: true
                )
                // The bar keeps its stock back button but loses its background,
                // so the map still runs to the top of the screen.
                .toolbarBackground(.hidden, for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
            }
            .navigationDestination(item: $openedExerciseName) { name in
                if let exercise = ExerciseDemoLibrary.exercise(named: name) {
                    // Pushed inside the sheet, so it keeps the sheet's card
                    // colour rather than a screen's.
                    ExerciseDetailSheet(exercise: exercise)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .background(Color.defaultSheetBackground.ignoresSafeArea())
                }
            }
        }
    }

    // Names the parts of a mixed workout. Palette style lays the parts out as a
    // row of glyphs and marks the selected one itself, so the bar carries no
    // background of its own on top of the glass.
    @ToolbarContentBuilder
    private var partPicker: some ToolbarContent {
        if visibleParts.count > 1 {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("Part", selection: $selectedPart) {
                    ForEach(visibleParts, id: \.self) { index in
                        Label(sessions[index].partTitle, systemImage: sessions[index].symbol)
                            .tag(index)
                    }
                }
                .pickerStyle(.palette)
                .brightHaptic(.light, trigger: selectedPart)
            }
        }
    }

    private var subtitle: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            if let startTime = workout.startTime, let endTime = workout.endTime {
                BrightText(
                    Date.brightTimeRange(
                        from: startTime.isoStringToDate(),
                        to: endTime.isoStringToDate()
                    ),
                    size: .body1
                )
            }

            if let source = workout.source {
                HStack(spacing: .spacing1x) {
                    Image(systemName: sourceIcon(for: source))
                        .font(.system(size: Constants.sourceIconSize))
                        .foregroundStyle(Color.textColor)
                        .frame(width: Constants.sourceIconBox, height: Constants.sourceIconBox)

                    BrightText(source, size: .body1)
                }
            }
        }
    }

    private func sourceIcon(for source: String) -> String {
        if source.localizedCaseInsensitiveContains("iPhone") { return "iphone" }
        if source.localizedCaseInsensitiveContains("Garmin") { return "figure.run.circle" }
        if source.localizedCaseInsensitiveContains("manually") { return "hand.tap" }
        return "applewatch"
    }

    // MARK: - Tabs

    @ViewBuilder
    private func tabContent(for tab: ExerciseCompleteTab) -> some View {
        switch tab {
        case .summary: summaryTab
        case .heart: heartTab
        case .performance: performanceTab
        }
    }

    private var summaryTab: some View {
        VStack(alignment: .leading, spacing: .spacing4x) {
            if workout.hasRoute {
                ExerciseCompleteMapWidget(
                    routeLatitudes: workout.routeLatitudes,
                    routeLongitudes: workout.routeLongitudes,
                    routeZoneIndexes: workout.routeZoneIndexes,
                    highlight: currentStep?.route,
                    highlightTint: currentStep?.tint ?? .defaultSkyBlue,
                    onOpen: { showingMap = true }
                )
            }

            if let intervals = session.intervals {
                ExerciseCompleteIntervalStripView(strip: intervals, selectedIndex: intervalIndex)
            }

            ExerciseCompleteMetricGrid(metrics: summaryMetrics)

            if let strain = session.strain {
                ExerciseWidgetSection(
                    icon: .symbol("arrow.left.and.right"),
                    title: "Session Strain"
                ) {
                    ExerciseCompleteStrainWidget(strain: strain)
                }
            }

            if let exertion = session.exertion {
                ExerciseWidgetSection(icon: .symbol("scope"), title: "Exertion breakdown") {
                    ExerciseCompleteExertionWidget(exertion: exertion) { name in
                        openedExerciseName = name
                    }
                }
            }

            if !session.records.isEmpty {
                ExerciseWidgetSection(icon: .symbol("trophy.fill"), title: "Personal Records") {
                    ExercisePersonalRecordsWidget(records: session.records) { name in
                        openedExerciseName = name
                    }
                }
            }
        }
        .animation(.brightSnappy, value: selectedInterval)
    }

    private var heartTab: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            ExerciseCompleteHeartRateWidget(
                hrAvg: workout.hrAvg ?? 0,
                hrPeak: workout.hrPeak,
                startDate: workout.startTime ?? "",
                endDate: workout.endTime ?? "",
                data: workout.heartGraph ?? HeartWorkoutSummaryHeartGraphData()
            )

            ExerciseCompletePostWorkoutWidget(
                data: workout.postWorkoutHeartGraph ?? HeartWorkoutSummaryPostWorkoutHeartGraphData()
            )

            if session.kind.showsZoneBreakdown {
                ExerciseCompleteBreakdownWidget(
                    data: workout.breakdown ?? HeartWorkoutSummaryBreakdownData()
                )
            }
        }
    }

    @ViewBuilder
    private var performanceTab: some View {
        if session.kind == .strength {
            VStack(alignment: .leading, spacing: .spacing4x) {
                ForEach(session.progressions) { progression in
                    ExerciseCompleteProgressionWidget(progression: progression) { name in
                        openedExerciseName = name
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: .spacing4x) {
                ExerciseCompletePerformanceGraphWidget(
                    hrAvg: workout.hrAvg ?? 0,
                    duration: workout.duration ?? TimeDuration(),
                    avgPace: workout.avgPaceSecondsPerKm ?? 0,
                    altitudeGain: workout.altitudeGain ?? Amount(unit: "M", value: 0),
                    data: ExerciseCompleteCombinedGraphData(
                        heartData: workout.heartGraph ?? HeartWorkoutSummaryHeartGraphData(),
                        altitudeData: workout.altitudeGraph ?? HeartWorkoutSummaryAltitudeGraphData(),
                        paceData: workout.paceGraph ?? HeartWorkoutSummaryPaceGraphData(),
                        cadenceData: workout.cadenceGraph ?? HeartWorkoutSummaryCadenceGraphData()
                    ),
                    selectedSecond: $selectedGraphSecond
                )

                if let splits = workout.splits, !splits.isEmpty {
                    ExerciseCompleteSplitWidget(data: splits)
                }

                if let intervals = workout.intervals, !intervals.isEmpty {
                    ExerciseCompleteIntervalWidget(data: intervals)
                }
            }
        }
    }

    private enum Constants {
        static let pillFollowMaxShift: CGFloat = .spacing12x + .spacing4x
        static let sourceIconSize: CGFloat = 20
        static let sourceIconBox: CGFloat = 24
    }
}

#Preview("Strength") {
    ExerciseCompleteSheet(sessions: [ExerciseDemoComplete.strength])
}

#Preview("Cardio") {
    ExerciseCompleteSheet(sessions: [ExerciseDemoComplete.cardio])
}

#Preview("Both") {
    ExerciseCompleteSheet(sessions: [ExerciseDemoComplete.strength, ExerciseDemoComplete.cardio])
}
