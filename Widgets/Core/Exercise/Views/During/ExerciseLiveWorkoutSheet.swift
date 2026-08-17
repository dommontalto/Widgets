//
//  ExerciseLiveWorkoutSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import SwiftUI

struct ExerciseLiveWorkoutSheet: View {
    var workoutName = "Gym workout"
    var templateItems: [ExerciseTemplateItem]? = nil
    // Ends the whole run. Only the flow can do that from a pushed leg, where
    // `dismiss` would pop back to the pre-workout screen instead.
    var onClose: (() -> Void)?
    // Handed the run's exercises when the user wants them folded back into the
    // workout they started from.
    var onUpdateWorkout: ([ExerciseTemplateItem]) -> Void = { _ in }
    // Handed the logged workout, so the presenter owns what comes next — it
    // swaps this screen for the summary inside the same presentation.
    var onFinish: (ExerciseWorkout) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss

    @State private var startDate = Date()
    @State private var exercises: [ExerciseActiveExercise]
    @State private var currentIndex = 0
    @State private var openedExerciseName: String?
    @State private var restEndDate: Date?
    @State private var isSideMenuExpanded = false
    @State private var visibleRows: Set<Int> = []
    @State private var isPickingRPE = false
    @State private var isPickingFailedRep = false
    // The set rows sit in a `List`, which re-derives its width when the rest
    // beam's full-screen overlay changes the safe area. Measured from the page
    // once and pinned, so the rows can't be squeezed mid-animation.
    @State private var pageWidth: CGFloat = 0
    @State private var isConfirmingWorkoutUpdate = false
    @State private var isShowingProgression = false
    @FocusState private var focusedField: ExerciseSetField?

    init(
        workoutName: String = "Gym workout",
        templateItems: [ExerciseTemplateItem]? = nil,
        onClose: (() -> Void)? = nil,
        onUpdateWorkout: @escaping ([ExerciseTemplateItem]) -> Void = { _ in },
        onFinish: @escaping (ExerciseWorkout) -> Void = { _ in }
    ) {
        self.workoutName = workoutName
        self.templateItems = templateItems
        self.onClose = onClose
        self.onUpdateWorkout = onUpdateWorkout
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

    private var isResting: Bool {
        restEndDate != nil
    }

    private var page: some View {
        BrightPageView(
            horizontalPadding: .spacing0x,
            backgroundColor: .defaultBackground,
            bottomSafeArea: false,
            toolbar: {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.brightSnappy) { isSideMenuExpanded.toggle() }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                }

                ToolbarItem(placement: .principal) {
                    elapsedPill
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        close()
                    } label: {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.standard(size: .subheading, weight: .regular))
                            .foregroundStyle(Color.textColor)
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    keyboardBar
                }
            },
            content: {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: .spacing0x) {
                        exerciseHeader
                            .padding(.horizontal, .spacing3x)
                            .padding(.leading, .spacing1x)
                            .padding(.bottom, .spacing3x)

                        // Runs edge to edge so a swipe-to-delete reaches the
                        // screen edge; the rows carry the margin themselves.
                        setRows
                    }
                    .padding(.top, .spacing3x)
                    .padding(.bottom, .spacing4x)
                }
                // Floats above the rows while they scroll underneath.
                .safeAreaInset(edge: .bottom) {
                    statusWidget
                        // Pinned rather than padded: the card's controls can ask
                        // for more than the screen, and an inset that wide drags
                        // the whole page out with it, taking the margins off.
                        .frame(width: pageWidth > 0 ? pageWidth - 2 * .spacing3x : nil)
                        .padding(.horizontal, .spacing3x)
                        .padding(.bottom, .spacing3x)
                }
                // The keyboard is in there so a tapped weight field doesn't lift
                // the card off the bottom of the screen.
                .ignoresSafeArea([.container, .keyboard], edges: .bottom)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { width in
                    guard width > 0, pageWidth == 0 else { return }
                    pageWidth = width
                }
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
        .alert("Workout Changed", isPresented: $isConfirmingWorkoutUpdate) {
            Button {
                onUpdateWorkout(runTemplateItems)
                onFinish(finishedWorkout)
            } label: {
                Text("Update Workout")
                    .foregroundStyle(Color.defaultSkyBlue)
            }

            Button("Keep Original Workout", role: .cancel) {
                onFinish(finishedWorkout)
            }
        } message: {
            Text("This run added sets or exercises the workout doesn't have.")
        }
        .animation(.brightEaseInOut, value: restEndDate)
        .animation(.brightEaseInOut, value: currentIndex)
        .animation(.brightEaseInOut, value: completedSets)
        .navigationDestination(item: $openedExerciseName) { name in
            if let exercise = ExerciseDemoLibrary.exercise(named: name) {
                ExerciseDetailSheet(exercise: exercise, cardColor: .defaultCards)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(Color.defaultBackground.ignoresSafeArea())
            }
        }
    }

    private var sideMenu: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing0x) {
                BrightText(workoutName, size: .standout1)
                    .padding(.top, .spacing2x)
                    .padding(.bottom, .spacing6x)
                    .staggered(at: 0, in: visibleRows)

                VStack(alignment: .leading, spacing: .spacing4x) {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        sideMenuItem(
                            exercise.name,
                            symbol: index == currentIndex ? "checkmark" : "dumbbell",
                            color: index == currentIndex ? .defaultGreen : .textColor
                        ) {
                            currentIndex = index
                        }
                        .staggered(at: index + 1, in: visibleRows)
                    }
                }

                VStack(alignment: .leading, spacing: .spacing4x) {
                    sideMenuItem("Cancel workout", symbol: "xmark", color: .defaultRed, isDestructive: true) {
                        close()
                    }
                    .staggered(at: exercises.count + 1, in: visibleRows)

                    sideMenuItem("End workout", symbol: "flag", color: .defaultRed, isDestructive: true) {
                        finish()
                    }
                    .staggered(at: exercises.count + 2, in: visibleRows)
                }
                .padding(.top, .spacing6x)

                Spacer(minLength: .spacing8x)
            }
            .padding(.horizontal, .spacing3x)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaPadding(.vertical)
        .onChange(of: isSideMenuExpanded) { _, isExpanded in
            animateRows(in: isExpanded)
        }
    }

    // Rows fall in one after another as the menu opens, and drop together on the
    // way out — matching the app's main side menu.
    private func animateRows(in expanded: Bool) {
        guard expanded else {
            withAnimation(.easeOut(duration: Constants.rowExitDuration)) { visibleRows.removeAll() }
            return
        }

        visibleRows = []
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Constants.rowStartDelay))
            for row in 0...(exercises.count + 2) {
                withAnimation(.bouncy(duration: Constants.rowDuration, extraBounce: Constants.rowBounce)) {
                    _ = visibleRows.insert(row)
                }
                try? await Task.sleep(for: .seconds(Constants.rowStaggerDelay))
            }
        }
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
                    .font(.standard(size: .subheading, weight: .light))
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

    // MARK: - Header

    private var elapsedPill: some View {
        TimelineView(.periodic(from: startDate, by: Constants.elapsedTick)) { context in
            BrightText(elapsed(at: context.date), size: .heading)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.brightSnappy, value: elapsed(at: context.date))
        }
        .padding(.horizontal, .spacing2x)
        .frame(height: Constants.pillHeight)
        .modifier(GlassEffect(shape: .capsule, interactive: false))
    }

    private func elapsed(at date: Date) -> String {
        let seconds = Int(max(0, date.timeIntervalSince(startDate)))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds / 60) % 60, seconds % 60)
    }

    private var exerciseHeader: some View {
        HStack(spacing: .spacing2x) {
            Button {
                openedExerciseName = currentExercise.name
            } label: {
                RoundedRectangle(cornerRadius: .cornerRadius14, style: .continuous)
                    .fill(Color.defaultCards)
                    .frame(width: Constants.thumbnailSize, height: Constants.thumbnailSize)
                    .overlay {
                        Image(systemName: "dumbbell")
                            .font(.standard(size: .standout3, weight: .light))
                            .foregroundStyle(Color.lightTextColor)
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            BrightText(currentExercise.name, size: .standout3)
                .lineLimit(1)

            Spacer(minLength: .spacing2x)

            BrightRoundButton(systemImage: "chart.line.uptrend.xyaxis", size: .medium) {
                isShowingProgression = true
            }
        }
        .brightMiniSheet(isPresented: $isShowingProgression) {
            ExerciseProgressionMiniSheet(
                lastSessionDate: Constants.demoLastSession,
                sets: lastSessionSets,
                weightChange: Constants.demoWeightChange
            ) {
                isShowingProgression = false
            } onClose: {
                isShowingProgression = false
            }
        }
    }

    // The previous run's sets, so the sheet can show what this one is building
    // on. Demo data until the workout history is wired up.
    private var lastSessionSets: [ExerciseProgressionSet] {
        currentExercise.sets
            .filter(\.kind.countsAsSet)
            .enumerated()
            .map { index, set in
                ExerciseProgressionSet(
                    label: "Set \(index + 1)",
                    weight: set.previous.filter { $0.isNumber || $0 == "." },
                    reps: set.reps.isEmpty ? "5" : set.reps,
                    rpe: set.rpe ?? Constants.demoLastRPE
                )
            }
    }

    // MARK: - Keyboard

    private var keyboardBar: some View {
        HStack(spacing: .spacing2x) {
            keyboardButton("chevron.left") { moveFocus(by: -1) }
                .disabled(neighbourField(at: -1) == nil)
                .padding(.leading, .spacing1x)

            keyboardButton("chevron.right") { moveFocus(by: 1) }
                .disabled(neighbourField(at: 1) == nil)

            Spacer(minLength: .spacing2x)

            keyboardButton("checkmark") { focusedField = nil }
                .padding(.trailing, .spacing2x)
        }
        .frame(maxWidth: .infinity)
    }

    private func keyboardButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.standard(size: .subheading, weight: .regular))
                .foregroundStyle(Color.textColor)
                .frame(width: Constants.keyboardGlyphSize, height: Constants.keyboardGlyphSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // The chevrons walk down a column rather than across the row, so kg leads to
    // the next kg and reps to the next reps.
    private func column(of field: ExerciseSetField) -> [ExerciseSetField] {
        switch field {
        case .weight: currentExercise.sets.map { .weight($0.id) }
        case .reps: currentExercise.sets.map { .reps($0.id) }
        }
    }

    private func neighbourField(at offset: Int) -> ExerciseSetField? {
        guard let focusedField else { return nil }
        let fields = column(of: focusedField)
        guard let index = fields.firstIndex(of: focusedField) else { return nil }
        let neighbour = index + offset
        guard fields.indices.contains(neighbour) else { return nil }
        return fields[neighbour]
    }

    private func moveFocus(by offset: Int) {
        guard let neighbour = neighbourField(at: offset) else { return }
        focusedField = neighbour
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
                    isActive: $set.wrappedValue.id == activeSet?.id,
                    isResting: isResting,
                    focus: $focusedField,
                    onTickActiveSet: startRest
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
                    // The Bright app tints its whole TabView, which outranks the
                    // destructive role's red on a swipe action.
                    .tint(.defaultRed)

                    if $set.wrappedValue.isTagged {
                        Button {
                            withAnimation(.brightSnappy) { clearTags(of: $set.wrappedValue) }
                        } label: {
                            Image(systemName: "tag.slash")
                        }
                        // Same reason as the trash: the app's tint would colour
                        // this one too, so it states its own.
                        .tint(.defaultMainGrey)
                    }
                }
            }
        }
        .listStyle(.plain)
        .listRowSpacing(.spacing2x)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .contentMargins(.vertical, .spacing0x, for: .scrollContent)
        .environment(\.defaultMinListRowHeight, Constants.rowHeight)
        .frame(width: pageWidth > 0 ? pageWidth : nil, height: setsHeight)
        .animation(.brightSnappy, value: setsHeight)
    }

    // A failed set carries a second line, so the list can't multiply one row
    // height by the count.
    private var setsHeight: CGFloat {
        currentExercise.sets.reduce(.spacing0x) { total, set in
            total + ExerciseLiveSetRow.height(for: set) + .spacing2x
        }
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

    private var statusWidget: some View {
        ExerciseLiveWorkoutStatusWidget(
            status: status,
            heartRate: Constants.demoHeartRate,
            onRPE: { isPickingRPE = true },
            onFailedSet: { isPickingFailedRep = true },
            onExtendRest: { restEndDate = restEndDate?.addingTimeInterval($0) },
            onSkip: skip,
            onComplete: completeActiveSet
        )
        // Rest rings the status card; working is signalled on the active set row.
        .borderBeam(
            .md,
            colorVariant: .defaultBlue,
            theme: .auto,
            active: isResting,
            borderRadius: Constants.statusBeamRadius
        )
        .brightMiniSheet(isPresented: $isPickingRPE) {
            ExerciseValuePicker.rpe(ratedSet(\.rpe)) { isPickingRPE = false }
        }
        .brightMiniSheet(isPresented: $isPickingFailedRep) {
            ExerciseValuePicker.failedSet(targetReps: ratedSetReps, failedRep: ratedSet(\.failedRep)) {
                isPickingFailedRep = false
            }
        }
    }

    // The set the pickers write to: the one being worked on, or the last one
    // logged once the exercise is done.
    private var ratedIndex: Int? {
        currentExercise.sets.firstIndex { !$0.isDone } ?? currentExercise.sets.indices.last
    }

    private func ratedSet(_ field: WritableKeyPath<ExerciseActiveSet, Int?>) -> Binding<Int?> {
        guard let ratedIndex else { return .constant(nil) }
        return Binding(
            get: { exercises[currentIndex].sets[ratedIndex][keyPath: field] },
            set: { newValue in
                exercises[currentIndex].sets[ratedIndex][keyPath: field] = newValue
                // Rating a set or logging the rep it failed on is only something
                // you do once it's been worked, so it logs the set as well.
                guard newValue != nil, !exercises[currentIndex].sets[ratedIndex].isDone else { return }
                exercises[currentIndex].sets[ratedIndex].isDone = true
                startRest()
            }
        )
    }

    private var ratedSetReps: Int {
        guard let ratedIndex else { return 0 }
        return Int(currentExercise.sets[ratedIndex].reps) ?? 0
    }

    private var status: ExerciseLiveWorkoutStatusWidget.Status {
        if let restEndDate {
            .resting(upNext: currentBlockName, until: restEndDate)
        } else if activeSet == nil {
            isLastExercise ? .allSetsComplete : .nextExercise(name: exercises[currentIndex + 1].name)
        } else {
            .working(label: currentBlockName)
        }
    }

    private var isLastExercise: Bool {
        currentIndex == exercises.count - 1
    }

    // MARK: - Actions

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private func finish() {
        guard divergesFromTemplate else {
            onFinish(finishedWorkout)
            return
        }
        isConfirmingWorkoutUpdate = true
    }

    // True once the run has more (or fewer) exercises or sets than the workout
    // it started from — a typed weight isn't a change to the plan.
    private var divergesFromTemplate: Bool {
        guard let templateItems else { return false }
        guard templateItems.count == exercises.count else { return true }
        return zip(templateItems, exercises).contains { template, live in
            plannedSetCount(for: template) != live.sets.count
        }
    }

    private func plannedSetCount(for item: ExerciseTemplateItem) -> Int {
        item.sets.isEmpty ? ExerciseActiveExercise.blankSetCount : item.sets.count
    }

    private var runTemplateItems: [ExerciseTemplateItem] {
        exercises.map { exercise in
            let working = exercise.sets.filter(\.kind.countsAsSet).count
            return ExerciseTemplateItem(
                exerciseName: exercise.name,
                target: "\(working) sets",
                sets: exercise.sets.map {
                    ExerciseTemplateSet(weight: $0.weight, reps: $0.reps, kind: $0.kind)
                }
            )
        }
    }

    private func completeActiveSet() {
        guard let activeSet, let index = currentExercise.sets.firstIndex(where: { $0.id == activeSet.id }) else {
            advance()
            return
        }
        exercises[currentIndex].sets[index].isDone = true
        startRest()
    }

    // No rest once the last set is ticked — the exercise is over.
    private func startRest() {
        guard activeSet != nil else { return }
        restEndDate = Date().addingTimeInterval(Constants.restSeconds)
    }

    // Clears the row's tags together — the rating and the failed rep are one
    // gesture's worth of undo.
    private func clearTags(of set: ExerciseActiveSet) {
        guard let index = currentExercise.sets.firstIndex(where: { $0.id == set.id }) else { return }
        exercises[currentIndex].sets[index].rpe = nil
        exercises[currentIndex].sets[index].failedRep = nil
    }

    // Cuts rest short so the next set becomes active straight away.
    private func skip() {
        restEndDate = nil
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

    private var activeSet: ExerciseActiveSet? {
        currentExercise.sets.first { !$0.isDone }
    }

    private var currentBlockName: String {
        guard let activeSet else { return "Finished" }
        if activeSet.isWarmup { return "Warmup" }
        return "Set \(workingIndex(of: activeSet, in: currentExercise))"
    }

    private var finishedWorkout: ExerciseWorkout {
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

        return ExerciseWorkout(
            name: workoutName,
            timestamp: Date().formatted(date: .abbreviated, time: .shortened),
            type: .strength,
            summary: "\(duration) • \(volumeString) kg • \(completedSets) sets",
            detail: ExerciseWorkoutDetail(
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
                note: "Nice work — that's another workout logged."
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

    // Epley-style estimate off the heaviest logged set.
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
        // The live rows run taller than the ones on customise sets — the design
        // gives the chips more room here.
        // Set rows match the exercise cells everywhere else in the feature, so
        // the height lives in one place rather than being repeated as 68.
        static let rowHeight = ExerciseLibraryRow.Constants.minHeight
        static let rowDuration: TimeInterval = 0.3
        static let rowBounce: TimeInterval = 0.1
        static let rowStaggerDelay: TimeInterval = 0.03
        static let rowStartDelay: TimeInterval = 0.02
        static let rowExitDuration: TimeInterval = 0.15
        static let keyboardGlyphSize: CGFloat = 30
        static let restSeconds: TimeInterval = 90
        static let menuIconSize: CGFloat = 24
        static let pillHeight: CGFloat = 30
        static let elapsedTick: TimeInterval = 1
        static let thumbnailSize: CGFloat = 60
        // The status card's corners run 36 at the top and 44 at the bottom; the
        // beam takes one radius, so it splits them.
        // The beam takes one radius for all four corners, so it follows the
        // status card's softer top rather than splitting the difference with
        // the tighter bottom, which sits at the screen edge.
        static let statusBeamRadius: Double = 36
        // Stands in for HealthKit until the workout is wired to real samples.
        static let demoHeartRate = "132"
        static let demoLastSession = "Fri, 7 Aug"
        static let demoWeightChange = 2.5
        static let demoLastRPE = 8
        static let demoCalories = "412"
    }
}

private struct ExerciseSetValueChip: View {
    @Binding var text: String
    let field: ExerciseSetField
    var unit: String?
    let keyboard: UIKeyboardType
    @FocusState.Binding var focus: ExerciseSetField?

    @State private var selection: TextSelection?

    var body: some View {
        HStack(spacing: .spacing05x) {
            TextField("0", text: $text, selection: $selection)
                .font(.standard(size: .body2, weight: .regular))
                .foregroundStyle(Color.textColor)
                .focused($focus, equals: field)
                .keyboardType(keyboard)
                .multilineTextAlignment(unit == nil ? .center : .trailing)
                .monospacedDigit()
                .fixedSize()

            if let unit {
                BrightText(unit, size: .body2, weight: .regular)
                    .fixedSize()
            }
        }
        .frame(width: Constants.chipWidth, height: Constants.chipHeight)
        .background(Color.defaultBackground, in: Capsule())
        // The whole capsule takes the tap, not just where the digits happen to
        // land — a two-character number is a small target.
        .contentShape(Capsule())
        .onTapGesture { focus = field }
        .onChange(of: focus) { _, focused in
            guard focused == field else { return }
            selection = TextSelection(insertionPoint: text.endIndex)
        }
    }

    private enum Constants {
        static let chipWidth: CGFloat = 60
        static let chipHeight: CGFloat = 34
    }
}

// The text fields the keyboard bar walks between.
enum ExerciseSetField: Hashable {
    case weight(UUID)
    case reps(UUID)
}

private struct ExerciseLiveSetRow: View {
    @Binding var set: ExerciseActiveSet
    let index: Int
    let isActive: Bool
    // The active row still marks what's up next during rest, but the beam is the
    // working signal, so it stands down while the sheet's rest ring is up.
    let isResting: Bool
    @FocusState.Binding var focus: ExerciseSetField?
    let onTickActiveSet: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            HStack(spacing: .spacing0x) {
                setChip

                divider

                ExerciseSetValueChip(
                    text: $set.weight,
                    field: .weight(set.id),
                    unit: "kg",
                    keyboard: .decimalPad,
                    focus: $focus
                )

                divider

                ExerciseSetValueChip(
                    text: $set.reps,
                    field: .reps(set.id),
                    keyboard: .numberPad,
                    focus: $focus
                )

                Spacer(minLength: .spacing2x)

                if let rpe = set.rpe {
                    BrightStatus(status: "RPE \(rpe)")
                        .padding(.trailing, .spacing2x)
                        .transition(.scale.combined(with: .opacity))
                }

                Button {
                    set.isDone.toggle()
                    // Ticking the working set by hand is the same event as
                    // tapping Next, so it starts rest too.
                    if isActive, set.isDone { onTickActiveSet() }
                } label: {
                    BrightTick(isTicked: set.isDone)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .frame(height: ExerciseLiveWorkoutSheet.Constants.rowHeight)

            if let failedRep = set.failedRep {
                failedLine(failedRep)
            }
        }
        .padding(.horizontal, .spacing3x)
        .frame(height: ExerciseLiveSetRow.height(for: set))
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
        // Marks the set you're working on.
        .borderBeam(
            .md,
            colorVariant: .orange,
            theme: .auto,
            active: isActive && !isResting,
            borderRadius: CGFloat.cornerRadius24
        )
        // The pickers write straight through their bindings, so the row owns the
        // animation for the chip, the rep and the cross landing on it.
        .animation(.brightSnappy, value: set.rpe)
        .animation(.brightSnappy, value: set.failedRep)
    }

    // The list sizes itself off the rows, so the failed line's cost is declared
    // here rather than measured.
    static func height(for set: ExerciseActiveSet) -> CGFloat {
        let base = ExerciseLiveWorkoutSheet.Constants.rowHeight
        return set.failedRep == nil ? base : base + Constants.failedLineHeight + .spacing2x
    }

    private func failedLine(_ rep: Int) -> some View {
        HStack(spacing: .spacing1x) {
            Image(systemName: "xmark.octagon")
                .font(.standard(size: .standout2, weight: .light))
                .foregroundStyle(Color.defaultRed)

            BrightText("Failed at rep \(rep)", size: .body2, color: .semiLightTextColor, weight: .regular)

            Spacer(minLength: .spacing2x)
        }
        .frame(height: Constants.failedLineHeight)
        .padding(.bottom, .spacing2x)
        .transition(.opacity)
    }

    private var setChip: some View {
        Menu {
            ForEach(ExerciseSetKind.pickable, id: \.self) { kind in
                Button(kind.pickerLabel, systemImage: kind.pickerSymbol) {
                    withAnimation(.brightSnappy) { set.kind = kind }
                }
            }
        } label: {
            // The Menu owns the tap, so the chip is label only.
            chipLabel
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder private var chipLabel: some View {
        Group {
            if let symbol = set.kind.symbol {
                Image(systemName: symbol)
                    .font(.standard(size: .body1, weight: .regular))
                    .foregroundStyle(set.kind.color)
            } else {
                BrightText("\(index)", size: .body1)
                    .monospacedDigit()
            }
        }
        .frame(width: Constants.chipHeight, height: Constants.chipHeight)
        .modifier(GlassEffect(shape: .circle))
    }

    private var divider: some View {
        BrightVerticalDivider(height: Constants.dividerHeight)
            .padding(.horizontal, .spacing2x)
    }

    private enum Constants {
        static let chipHeight: CGFloat = 30
        static let dividerHeight: CGFloat = 34
        static let failedLineHeight: CGFloat = 26
    }
}

struct ExerciseTemplateItem: Identifiable, Sendable {
    let id = UUID()
    let exerciseName: String
    let target: String
    // The planned sets. Empty falls back to a blank warm-up plus three working sets.
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
    // Rated after the set is logged, so it stays empty until the picker sets it.
    var rpe: Int?
    // The rep the set went down on, once it's been marked as failed.
    var failedRep: Int?
    var previous = "\u{2014}"
    var kind: ExerciseSetKind = .working(0)
    var isRecord = false
    var isDone = false

    var isWarmup: Bool { kind == .warmUp }

    // Carries a rating or a failed rep, so the row has something to clear.
    var isTagged: Bool { rpe != nil || failedRep != nil }
}

struct ExerciseActiveExercise: Identifiable, Sendable {
    let id = UUID()
    var name: String
    var notes = ""
    var sets: [ExerciseActiveSet]

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

    // Kept beside `blankSets` so the two can't drift.
    nonisolated static let blankSetCount = 4

    nonisolated private static var blankSets: [ExerciseActiveSet] {
        [
            ExerciseActiveSet(weight: "", reps: "", kind: .warmUp),
            ExerciseActiveSet(weight: "", reps: "", kind: .working(1)),
            ExerciseActiveSet(weight: "", reps: "", kind: .working(2)),
            ExerciseActiveSet(weight: "", reps: "", kind: .working(3)),
        ]
    }
}

private extension View {
    func staggered(at index: Int, in visibleRows: Set<Int>) -> some View {
        let isVisible = visibleRows.contains(index)
        return opacity(isVisible ? .opaque : .zero)
            .offset(x: isVisible ? 0 : -40)
    }
}

#Preview {
    NavigationStack {
        ExerciseLiveWorkoutSheet()
    }
}
