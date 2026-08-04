//
//  ExerciseLiveSessionSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import SwiftUI

struct ExerciseLiveSessionSheet: View {
    var sessionName = "Gym session"
    var templateItems: [ExerciseTemplateItem]? = nil
    /// Handed the logged session as this screen dismisses, so the presenter owns
    /// what comes next.
    var onFinish: (ExerciseSession) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss

    @State private var startDate = Date()
    @State private var exercises: [ExerciseActiveExercise]
    @State private var currentIndex = 0
    @State private var showAddExercise = false
    @State private var openedExercise: ExerciseDefinition?
    @State private var restEndDate: Date?
    @State private var isSideMenuExpanded = false

    init(
        sessionName: String = "Gym session",
        templateItems: [ExerciseTemplateItem]? = nil,
        onFinish: @escaping (ExerciseSession) -> Void = { _ in }
    ) {
        self.sessionName = sessionName
        self.templateItems = templateItems
        self.onFinish = onFinish
        _exercises = State(initialValue: templateItems.map(ExerciseActiveExercise.fromTemplate) ?? ExerciseDemoData.activeExercises)
    }

    var body: some View {
        BrightSideMenu(isExpanded: $isSideMenuExpanded) { _ in
            sideMenu
        } content: { _ in
            page
        }
    }

    private var page: some View {
        BrightPageView(
            horizontalPadding: .spacing0x,
            backgroundColor: .defaultBackground,
            toolbar: {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.brightSnappy) { isSideMenuExpanded.toggle() }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }

                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(title: currentExercise.name, file: #file)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        openedExercise = ExerciseDemoLibrary.exercise(named: currentExercise.name)
                    } label: {
                        Image(systemName: "dumbbell")
                            .font(.standardSFPro(size: .subheading, weight: .regular))
                            .foregroundStyle(Color.defaultPurple)
                    }
                }
            },
            content: {
                VStack(spacing: .spacing0x) {
                    logAllPill
                        .padding(.horizontal, .spacing3x)

                    // Runs edge to edge so a swipe-to-delete reaches the screen
                    // edge; the rows carry the margin themselves.
                    setRows
                        .padding(.top, .spacing3x)

                    Spacer(minLength: .spacing4x)

                    statusCard
                        .padding(.horizontal, .spacing3x)
                }
                .padding(.top, .spacing3x)
                .padding(.bottom, .spacing1x)
            }
        )
        .task(id: restEndDate) {
            guard let restEndDate else { return }
            let delay = restEndDate.timeIntervalSinceNow
            guard delay > 0 else {
                self.restEndDate = nil
                return
            }
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            withAnimation(.brightEaseInOut) { self.restEndDate = nil }
        }
        .animation(.brightEaseInOut, value: restEndDate)
        .animation(.brightEaseInOut, value: currentIndex)
        .animation(.brightEaseInOut, value: completedSets)
        .sheet(item: $openedExercise) { exercise in
            BrightPageSheetView(title: exercise.name, horizontalPadding: .spacing0x) {
                ExerciseDetailSheet(exercise: exercise)
            }
        }
        .sheet(isPresented: $showAddExercise) {
            BrightPageSheetView(title: "Exercises") {
                BrightPlaceholderView(
                    systemImage: "dumbbell",
                    title: "Exercise library",
                    subtitle: "This screen hasn\u{2019}t been ported yet."
                )
            }
        }
    }

    private var sideMenu: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing0x) {
                BrightText(sessionName, size: .standout1)
                    .padding(.top, .spacing2x)
                    .padding(.bottom, .spacing6x)

                VStack(alignment: .leading, spacing: .spacing4x) {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        sideMenuItem(
                            exercise.name,
                            symbol: index == currentIndex ? "checkmark" : "dumbbell",
                            color: index == currentIndex ? .defaultGreen : .textColor
                        ) {
                            currentIndex = index
                        }
                    }
                }

                VStack(alignment: .leading, spacing: .spacing4x) {
                    sideMenuItem("Add exercise", symbol: "plus", color: .defaultSkyBlue) {
                        showAddExercise = true
                    }

                    sideMenuItem("End workout", symbol: "flag.checkered", color: .defaultRed, isDestructive: true) {
                        finish()
                    }

                    sideMenuItem("Cancel workout", symbol: "xmark", color: .defaultRed, isDestructive: true) {
                        dismiss()
                    }
                }
                .padding(.top, .spacing6x)

                Spacer(minLength: .spacing8x)
            }
            .padding(.horizontal, .spacing3x)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaPadding(.vertical)
    }

    private func sideMenuItem(
        _ title: String,
        symbol: String,
        color: Color,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(.brightSnappy) { isSideMenuExpanded = false }
            action()
        } label: {
            HStack(spacing: .spacing2x) {
                Image(systemName: symbol)
                    .font(.standardSFPro(size: .subheading, weight: .light))
                    .foregroundStyle(color)
                    .frame(width: Constants.menuIconSize)

                BrightText(
                    title,
                    size: .subheading2,
                    color: isDestructive ? .defaultRed : .semiLightTextColor
                )

                Spacer(minLength: .spacing2x)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var logAllPill: some View {
        BrightPillButton(allSetsLogged ? "Clear all" : "Log all", buttonSize: .small) {
            setAllSets(done: !allSetsLogged)
        }
        .contentTransition(.numericText())
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Sets

    private var setRows: some View {
        VStack(spacing: .spacing105x) {
            setsList

            addSetButton
                .padding(.horizontal, .spacing3x)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var setsList: some View {
        List {
            ForEach($exercises[currentIndex].sets) { $set in
                ExerciseLiveSetRow(
                    set: $set,
                    index: workingIndex(of: $set.wrappedValue, in: currentExercise),
                    isActive: $set.wrappedValue.id == activeSet?.id
                )
                .listRowInsets(EdgeInsets(top: .spacing0x, leading: .spacing3x, bottom: .spacing0x, trailing: .spacing3x))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        withAnimation(.brightSnappy) {
                            exercises[currentIndex].sets.removeAll { $0.id == $set.wrappedValue.id }
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .listRowSpacing(.spacing105x)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .contentMargins(.vertical, .spacing0x, for: .scrollContent)
        .environment(\.defaultMinListRowHeight, Constants.rowHeight)
        .frame(height: (Constants.rowHeight + .spacing105x) * CGFloat(currentExercise.sets.count))
        .animation(.brightSnappy, value: currentExercise.sets.count)
    }

    private var addSetButton: some View {
        BrightRoundButton(systemImage: "plus", size: .medium) {
            let last = currentExercise.sets.last
            exercises[currentIndex].sets.append(
                ExerciseActiveSet(
                    weight: last?.weight ?? "20",
                    reps: last?.reps ?? "10",
                    previous: last?.previous ?? "\u{2014}",
                    kind: .working(currentExercise.sets.filter(\.kind.countsAsSet).count + 1)
                )
            )
        }
    }

    // MARK: - Status

    private var statusCard: some View {
        ExerciseSessionStatusCard(
            status: status,
            onTag: cycleActiveSetKind,
            onRestart: restart,
            onSkip: skip,
            onComplete: completeActiveSet
        )
    }

    private var status: ExerciseSessionStatusCard.Status {
        if let restEndDate {
            .resting(upNext: currentBlockName, until: restEndDate)
        } else if activeSet == nil {
            .allSetsComplete
        } else {
            .working(label: currentBlockName, upNext: upNextName)
        }
    }

    // MARK: - Actions

    private func finish() {
        onFinish(finishedSession)
        dismiss()
    }

    /// Only the done state flips, so a mis-tap doesn't wipe typed weights or RPE.
    private func setAllSets(done: Bool) {
        for index in exercises[currentIndex].sets.indices {
            exercises[currentIndex].sets[index].isDone = done
        }
    }

    private func completeActiveSet() {
        guard let activeSet, let index = currentExercise.sets.firstIndex(where: { $0.id == activeSet.id }) else {
            advance()
            return
        }
        exercises[currentIndex].sets[index].isDone = true
        if self.activeSet != nil {
            restEndDate = Date().addingTimeInterval(Constants.restSeconds)
        }
    }

    /// Tag cycles the active set between warm-up, working and drop set, matching
    /// the sets editor.
    private func cycleActiveSetKind() {
        guard let activeSet, let index = currentExercise.sets.firstIndex(where: { $0.id == activeSet.id }) else { return }
        exercises[currentIndex].sets[index].kind = switch activeSet.kind {
        case .warmUp: .working(0)
        case .working: .dropSet
        case .dropSet: .warmUp
        }
    }

    /// Resting restarts the countdown; mid-set it un-logs the set before this one.
    private func restart() {
        if restEndDate != nil {
            restEndDate = Date().addingTimeInterval(Constants.restSeconds)
            return
        }
        guard let index = currentExercise.sets.lastIndex(where: \.isDone) else { return }
        exercises[currentIndex].sets[index].isDone = false
    }

    /// Resting skips to the next set; mid-set it moves on to the next exercise.
    private func skip() {
        if restEndDate != nil {
            restEndDate = nil
        } else {
            advance()
        }
    }

    private func advance() {
        guard currentIndex + 1 < exercises.count else {
            finish()
            return
        }
        currentIndex += 1
    }

    // MARK: - Derived state

    private var currentExercise: ExerciseActiveExercise {
        exercises[currentIndex]
    }

    private var allSetsLogged: Bool {
        !currentExercise.sets.isEmpty && currentExercise.sets.allSatisfy(\.isDone)
    }

    private var activeSet: ExerciseActiveSet? {
        currentExercise.sets.first { !$0.isDone }
    }

    private var currentBlockName: String {
        guard let activeSet else { return "Finished" }
        if activeSet.isWarmup { return "Warmup" }
        return "Set \(workingIndex(of: activeSet, in: currentExercise))"
    }

    private var upNextName: String {
        guard activeSet != nil else {
            let next = currentIndex + 1
            return next < exercises.count ? exercises[next].name : "FINISH"
        }
        return "REST"
    }

    private var finishedSession: ExerciseSession {
        let logged = exercises.compactMap { exercise -> ExerciseLoggedExercise? in
            let done = exercise.sets.filter(\.isDone)
            guard !done.isEmpty else { return nil }
            return ExerciseLoggedExercise(
                name: exercise.name,
                sets: done.map {
                    ExerciseLoggedSet(weight: $0.weight, reps: $0.reps, kind: $0.kind, isRecord: $0.isRecord)
                }
            )
        }
        let duration = elapsedString(at: Date())

        return ExerciseSession(
            name: sessionName,
            timestamp: Date().formatted(date: .abbreviated, time: .shortened),
            type: .strength,
            summary: "\(duration) • \(volumeString) kg • \(completedSets) sets",
            detail: ExerciseSessionDetail(
                tiles: [
                    ExerciseStatTile(label: "Personal Best", value: personalBest, unit: "KG", symbol: "trophy.fill", color: .defaultYellow),
                    ExerciseStatTile(label: "EST. 1RM", value: estimatedOneRepMax, unit: "KG", symbol: "dial.high.fill", color: .defaultRed),
                    ExerciseStatTile(label: "Total volume", value: volumeString, unit: "kg", symbol: "text.line.3.summary", color: .defaultGreen),
                    ExerciseStatTile(label: "Total sets", value: "\(completedSets)", unit: "sets", symbol: "chart.line.flattrend.xyaxis", color: .defaultSkyBlue),
                    ExerciseStatTile(label: "AVG heart rate", value: Constants.demoHeartRate, unit: "bpm", symbol: "heart.fill", color: .defaultRed),
                    ExerciseStatTile(label: "Calories", value: Constants.demoCalories, unit: "kcal", symbol: "flame.fill", color: .defaultOrange),
                ],
                exercises: logged,
                splits: [],
                note: "Nice work — that's another session logged."
            )
        )
    }

    private func workingIndex(of set: ExerciseActiveSet, in exercise: ExerciseActiveExercise) -> Int {
        let counted = exercise.sets.filter(\.kind.countsAsSet)
        return (counted.firstIndex { $0.id == set.id } ?? 0) + 1
    }

    private var completedSets: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.isDone).count }
    }

    private var recordCount: Int {
        exercises.reduce(0) { $0 + $1.sets.filter { $0.isDone && $0.isRecord }.count }
    }

    private var heaviestSet: Int {
        exercises
            .flatMap(\.sets)
            .filter(\.isDone)
            .compactMap { Int($0.weight) }
            .max() ?? 0
    }

    private var personalBest: String {
        "\(heaviestSet)"
    }

    /// Epley-style estimate off the heaviest logged set.
    private var estimatedOneRepMax: String {
        "\(Int((Double(heaviestSet) * 1.12).rounded()))"
    }

    private var volumeString: String {
        let volume = exercises
            .flatMap(\.sets)
            .filter(\.isDone)
            .reduce(0) { $0 + (Int($1.weight) ?? 0) * (Int($1.reps) ?? 0) }
        return volume.formatted(.number.grouping(.automatic))
    }

    private func elapsedString(at date: Date) -> String {
        let elapsed = max(0, Int(date.timeIntervalSince(startDate)))
        return String(format: "%d:%02d", elapsed / 60, elapsed % 60)
    }

    fileprivate enum Constants {
        static let rowHeight = ExerciseSetRow.Constants.rowHeight
        static let restSeconds: TimeInterval = 90
        static let menuIconSize: CGFloat = 24
        /// Stands in for HealthKit until the session is wired to real samples.
        static let demoHeartRate = "132"
        static let demoCalories = "412"
    }
}

private struct ExerciseLiveSetRow: View {
    @Binding var set: ExerciseActiveSet
    let index: Int
    let isActive: Bool

    var body: some View {
        HStack(spacing: .spacing0x) {
            HStack(spacing: .spacing105x) {
                setLabel

                if let symbol = set.kind.symbol {
                    Image(systemName: symbol)
                        .font(.standard(size: .body1, weight: .light))
                        .foregroundStyle(set.kind.color)
                }
            }
            .frame(width: Constants.leadingColumnWidth, alignment: .leading)

            Spacer(minLength: .spacing2x)

            HStack(spacing: .spacing05x) {
                valueField($set.weight, placeholder: "0")
                    .frame(width: Constants.weightColumnWidth, alignment: .trailing)

                BrightText("kg", size: .subheading, weight: .regular)
                    .fixedSize()
            }

            divider

            valueField($set.reps, placeholder: "0")
                .frame(width: Constants.repsColumnWidth, alignment: .center)

            divider

            BrightText("RPE", size: .subheading, weight: .regular)
                .fixedSize()

            rpeField
                .padding(.leading, .spacing1x)

            Button {
                set.isDone.toggle()
            } label: {
                BrightTick(isTicked: set.isDone)
                    .padding(.leading, .spacing2x)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, .spacing2x)
        .frame(height: ExerciseLiveSessionSheet.Constants.rowHeight)
        .modifier(CardModifier(cornerRadius: .cornerRadius18))
    }

    @ViewBuilder private var setLabel: some View {
        if isActive {
            Image(systemName: "play.fill")
                .font(.standard(size: .body1, weight: .medium))
                .foregroundStyle(Color.defaultBrightPink)
        } else if set.kind.isWorking {
            BrightText("\(index)", size: .body1)
                .monospacedDigit()
        }
    }

    private var divider: some View {
        BrightVerticalDivider(height: Constants.dividerHeight)
            .padding(.horizontal, .spacing2x)
    }

    private var rpeField: some View {
        TextField("0", text: $set.rpe)
            .font(.standardSFPro(size: .body2, weight: .regular))
            .foregroundStyle(Color.textColor)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .monospacedDigit()
            .frame(width: Constants.rpeFieldWidth, height: Constants.rpeFieldHeight)
            .background(Color.defaultBackground, in: Capsule())
    }

    private func valueField(_ text: Binding<String>, placeholder: String) -> some View {
        TextField(placeholder, text: text)
            .font(.standardSFPro(size: .subheading, weight: .regular))
            .foregroundStyle(Color.textColor)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .monospacedDigit()
    }

    private enum Constants {
        static let leadingColumnWidth: CGFloat = 40
        static let weightColumnWidth: CGFloat = 48
        static let repsColumnWidth: CGFloat = 28
        static let dividerHeight: CGFloat = 28
        static let rpeFieldWidth: CGFloat = 43
        static let rpeFieldHeight: CGFloat = 30
    }
}

struct ExerciseTemplateItem: Identifiable, Sendable {
    let id = UUID()
    let exerciseName: String
    let target: String
    /// The planned sets. Empty falls back to a blank warm-up plus three working sets.
    var sets: [ExerciseTemplateSet] = []
}

struct ExerciseTemplateSet: Sendable {
    let weight: String
    let reps: String
    var kind: ExerciseSetKind = .working(0)
}

struct ExerciseActiveSet: Identifiable, Sendable {
    let id = UUID()
    var weight: String
    var reps: String
    var rpe = ""
    var previous = "\u{2014}"
    var kind: ExerciseSetKind = .working(0)
    var isRecord = false
    var isDone = false

    var isWarmup: Bool { kind == .warmUp }
}

struct ExerciseActiveExercise: Identifiable, Sendable {
    let id = UUID()
    var name: String
    var notes = ""
    var sets: [ExerciseActiveSet]

    nonisolated static func fresh(named name: String) -> ExerciseActiveExercise {
        ExerciseActiveExercise(name: name, sets: blankSets)
    }

    nonisolated static func fromTemplate(_ items: [ExerciseTemplateItem]) -> [ExerciseActiveExercise] {
        items.map { item in
            ExerciseActiveExercise(
                name: item.exerciseName,
                notes: item.target,
                sets: item.sets.isEmpty
                    ? blankSets
                    : item.sets.map {
                        ExerciseActiveSet(weight: $0.weight, reps: $0.reps, kind: $0.kind)
                    }
            )
        }
    }

    nonisolated private static var blankSets: [ExerciseActiveSet] {
        [
            ExerciseActiveSet(weight: "", reps: "", kind: .warmUp),
            ExerciseActiveSet(weight: "", reps: "", kind: .working(1)),
            ExerciseActiveSet(weight: "", reps: "", kind: .working(2)),
            ExerciseActiveSet(weight: "", reps: "", kind: .working(3)),
        ]
    }
}

#Preview {
    NavigationStack {
        ExerciseLiveSessionSheet()
    }
}
