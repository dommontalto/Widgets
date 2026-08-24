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

    // A tab that has nothing to draw for this part drops out of the pager
    // rather than opening onto an empty page.
    static func visible(for session: ExerciseCompleteSession) -> [ExerciseCompleteTab] {
        allCases.filter { $0.hasContent(for: session) }
    }

    private func hasContent(for session: ExerciseCompleteSession) -> Bool {
        let summary = session.summary
        switch self {
        case .summary:
            return true
        case .heart:
            return summary.hrAvg != nil
                || summary.heartGraph?.data?.isEmpty == false
                || summary.postWorkoutHeartGraph?.data?.isEmpty == false
                || summary.breakdown?.zones?.isEmpty == false
        case .performance:
            return session.hasPerformanceGraph
                || summary.splits?.isEmpty == false
                || summary.intervals?.isEmpty == false
                || !session.progressions.isEmpty
        }
    }

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
    // A session that holds both lifting and cardio arrives as one session per
    // part, and the picker above the title walks between them.
    let sessions: [ExerciseCompleteSession]

    var chrome: ExercisePageChrome = .sheet

    // Ends the whole run. Only the flow can do that from a pushed leg, where
    // `dismiss` would pop back instead.
    var onClose: (() -> Void)?

    init(
        sessions: [ExerciseCompleteSession],
        chrome: ExercisePageChrome = .sheet,
        initialPart: Int = 0,
        onClose: (() -> Void)? = nil
    ) {
        self.sessions = sessions
        self.chrome = chrome
        self.onClose = onClose
        _selectedPart = State(initialValue: initialPart)
    }

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

    private var summary: HeartWorkoutSummaryResponseData { session.summary }

    private var visibleTabs: [ExerciseCompleteTab] {
        ExerciseCompleteTab.visible(for: session)
    }

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
        return sessions.indices.filter { sessions[$0].summary.hasRoute }
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
                pages: visibleTabs.map {
                    SwipePage(title: $0.title, systemImage: $0.systemImage)
                },
                fakeLargeTitle: summary.title ?? "",
                titleSize: .standout4,
                titleWeight: .regular,
                titleSubtitle: AnyView(subtitle),
                pillFollowMaxShift: Constants.pillFollowMaxShift,
                selectedIndex: $selectedIndex
            ) { index in
                tabContent(for: visibleTabs.indices.contains(index) ? visibleTabs[index] : .summary)
                    .padding(.horizontal, .spacing3x)
                    .padding(.top, .spacing2x + .spacing05x)
                    .padding(.bottom, .spacing3x)
            }
            // Another part may carry fewer tabs, so the page the picker lands on
            // has to exist.
            .id(selectedPart)
            .onChange(of: selectedPart) { _, _ in
                selectedIndex = min(selectedIndex, max(0, visibleTabs.count - 1))
            }
            // Declared on the content rather than on the container: the sheet
            // makes its own NavigationStack, and a destination hung outside it
            // never fires.
            .navigationDestination(isPresented: $showingMap) {
                ExerciseCompleteMapWidget(
                    routeLatitudes: summary.routeLatitudes,
                    routeLongitudes: summary.routeLongitudes,
                    routeZoneIndexes: summary.routeZoneIndexes,
                    duration: summary.duration,
                    hrAvg: summary.hrAvg,
                    altitudeGainMetres: summary.altitudeGain?.value,
                    avgPaceSecondsPerKm: summary.avgPaceSecondsPerKm,
                    heartGraph: summary.heartGraph,
                    altitudeGraph: summary.altitudeGraph,
                    paceGraph: summary.paceGraph,
                    cadenceGraph: summary.cadenceGraph,
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

    // Names the parts of a mixed session. One button per part rather than a
    // segmented picker, which brings its own background and reads as a control
    // stacked on the bar. Grouped, so the bar glasses them together as one, and
    // the part being read is the one carrying its own colour.
    @ToolbarContentBuilder
    private var partPicker: some ToolbarContent {
        if visibleParts.count > 1 {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ForEach(visibleParts, id: \.self) { index in
                    Button {
                        guard index != selectedPart else { return }
                        selectedPart = index
                        BrightHaptic.light.play()
                    } label: {
                        Label(sessions[index].partTitle, systemImage: sessions[index].symbol)
                            .labelStyle(.iconOnly)
                            .symbolVariant(index == selectedPart ? .fill : .none)
                    }
                    .tint(index == selectedPart ? sessions[index].partTint : .lightTextColor)
                }
            }
        }
    }

    private var subtitle: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            if let startTime = summary.startTime, let endTime = summary.endTime {
                BrightText(
                    Date.brightTimeRange(
                        from: startTime.isoStringToDate(),
                        to: endTime.isoStringToDate()
                    ),
                    size: .body1
                )
            }

            if let source = summary.source {
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
            if summary.hasRoute {
                ExerciseCompleteMapWidget(
                    routeLatitudes: summary.routeLatitudes,
                    routeLongitudes: summary.routeLongitudes,
                    routeZoneIndexes: summary.routeZoneIndexes,
                    highlight: currentStep?.route,
                    highlightTint: currentStep?.tint ?? .defaultSkyBlue,
                    onOpen: { showingMap = true }
                )
            }

            if let intervals = session.intervals {
                ExerciseCompleteIntervalStripView(strip: intervals, selectedIndex: intervalIndex)
            }

            ExerciseCompleteMetricGrid(metrics: summaryMetrics)

            if let fatigue = session.fatigue {
                ExerciseWidgetSection(
                    icon: .symbol("arrow.left.and.right"),
                    title: "Session Fatigue"
                ) {
                    ExerciseCompleteFatigueWidget(fatigue: fatigue)
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
            if summary.hrAvg != nil || summary.heartGraph?.data?.isEmpty == false {
                ExerciseCompleteHeartRateWidget(
                    hrAvg: summary.hrAvg ?? 0,
                    hrPeak: summary.hrPeak,
                    startDate: summary.startTime ?? "",
                    endDate: summary.endTime ?? "",
                    data: summary.heartGraph ?? HeartWorkoutSummaryHeartGraphData()
                )
            }

            if summary.postWorkoutHeartGraph?.data?.isEmpty == false {
                ExerciseCompleteHeartRateDropWidget(
                    data: summary.postWorkoutHeartGraph ?? HeartWorkoutSummaryPostWorkoutHeartGraphData()
                )
            }

            if let breakdown = summary.breakdown, breakdown.zones?.isEmpty == false {
                ExerciseCompleteBreakdownWidget(data: breakdown)
            }
        }
    }

    // No strength/cardio fork: whatever the part's data carries is stacked in
    // order — live traces first, then the tables, and the set cards last, since
    // they can run on forever.
    private var performanceTab: some View {
        VStack(alignment: .leading, spacing: .spacing4x) {
            if session.hasPerformanceGraph {
                ExerciseCompletePerformanceGraphWidget(
                    hrAvg: summary.hrAvg ?? 0,
                    duration: summary.duration ?? TimeDuration(),
                    avgPace: summary.avgPaceSecondsPerKm ?? 0,
                    altitudeGain: summary.altitudeGain ?? Amount(unit: "M", value: 0),
                    data: ExerciseCompleteCombinedGraphData(
                        heartData: summary.heartGraph ?? HeartWorkoutSummaryHeartGraphData(),
                        altitudeData: summary.altitudeGraph ?? HeartWorkoutSummaryAltitudeGraphData(),
                        paceData: summary.paceGraph ?? HeartWorkoutSummaryPaceGraphData(),
                        cadenceData: summary.cadenceGraph ?? HeartWorkoutSummaryCadenceGraphData()
                    ),
                    selectedSecond: $selectedGraphSecond
                )
            }

            if let splits = summary.splits, !splits.isEmpty {
                ExerciseCompleteSplitWidget(data: splits)
            }

            if let intervals = summary.intervals, !intervals.isEmpty {
                ExerciseCompleteIntervalWidget(data: intervals)
            }

            ForEach(session.progressions) { progression in
                ExerciseCompleteProgressionWidget(progression: progression) { name in
                    openedExerciseName = name
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
