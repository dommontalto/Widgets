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
    @State private var isPickingRPE = false
    @State private var isPickingFailedRep = false
    // The set rows sit in a `List`, which re-derives its width when the rest
    // beam's full-screen overlay changes the safe area. Measured from the page
    // once and pinned, so the rows can't be squeezed mid-animation.
    @State private var pageWidth: CGFloat = 0
    @State private var columnWidths: [ExerciseSetColumn: CGFloat] = [:]
    @State private var isConfirmingWorkoutUpdate = false
    @State private var isConfirmingDiscard = false
    @State private var isConfirmingFinish = false
    @State private var isShowingProgression = false
    @State private var isEditingWorkout = false
    // Names the skip that was just tapped, in place of the clock, until its
    // window runs out.
    @State private var transportLabel: String?
    @State private var transportTaps = 0
    // Set while the run is paused: the clock and the disc both read from it, and
    // resuming pushes `startDate` forward by however long it stood still.
    @State private var pauseDate: Date?
    // The clock says PAUSED once the disc is taken hold of; while it's being
    // turned it has to show the time being wound instead.
    @State private var isScrubbing = false
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
        ExerciseSlideMenu(sideBarRatio: Constants.menuWidthRatio, isExpanded: $isSideMenuExpanded) {
            ExerciseLiveWorkoutMenu(
                exercises: $exercises,
                currentIndex: $currentIndex,
                isExpanded: $isSideMenuExpanded,
                startDate: startDate,
                pauseDate: pauseDate,
                // The chip on the record says what the run is doing, and during a
                // rest that's the rest rather than the set waiting behind it.
                blockName: isResting ? "Resting" : currentBlockName,
                onBack: {
                    if currentIndex > 0 { showTransport("PREV") }
                    goBack()
                },
                onTogglePause: togglePause,
                onScrub: scrub,
                onScrubEnd: { isScrubbing = false },
                onAdvance: {
                    if currentIndex + 1 < exercises.count { showTransport("NEXT") }
                    advance()
                },
                onEdit: { isEditingWorkout = true },
                onCancel: { isConfirmingDiscard = true },
                onEnd: confirmFinish
            )
        } content: {
            page
        }
    }

    private var isResting: Bool {
        restEndDate != nil
    }

    private var isPaused: Bool {
        pauseDate != nil
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
                        Image(systemName: "sidebar.left")
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
        .alert("Discard?", isPresented: $isConfirmingDiscard) {
            Button("Cancel", role: .cancel) {}

            Button("Discard", role: .destructive) {
                close()
            }
        } message: {
            Text("Your workout data will not be saved if you discard this workout.")
        }
        .alert("Finish", isPresented: $isConfirmingFinish) {
            Button("Cancel", role: .cancel) {}

            Button("Finish") {
                finish()
            }
        } message: {
            Text("You still have some exercises to complete. Are you sure you want to finish your workout?")
        }
        .sheet(isPresented: $isEditingWorkout) {
            ExerciseReorderSheet(exercises: exercises, onSave: applyEdits)
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

    // MARK: - Header

    private var elapsedPill: some View {
        Button {
            togglePause()
        } label: {
            TimelineView(.periodic(from: startDate, by: Constants.elapsedTick)) { context in
                BrightText(pillLabel(at: context.date), size: .standout3, color: pillColor)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.brightSnappy, value: pillLabel(at: context.date))
            }
            .padding(.horizontal, .spacing2x)
            .frame(height: Constants.pillHeight)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .brightHaptic(.light, trigger: pauseDate)
        .animation(.brightSnappy, value: pillColor)
        .background(pillColor.opacity(.veryMinimalOpacity), in: Capsule())
        .modifier(GlassEffect(shape: .capsule, interactive: false))
        .task(id: transportTaps) {
            guard transportLabel != nil else { return }
            // A fresh skip cancels this sleep; that tap's own window is what
            // puts the label away rather than this one cutting it short.
            do { try await Task.sleep(for: .seconds(Constants.transportReveal)) } catch { return }
            withAnimation(.brightSnappy) { transportLabel = nil }
        }
    }

    private var pillColor: Color {
        if transportLabel != nil { return .defaultBlue }
        return pauseDate == nil ? .defaultGreen : .defaultOrange
    }

    // The pill doubles as the transport's read-out: a skip names itself for a
    // moment, and a paused run says so instead of showing a clock that's stopped.
    private func pillLabel(at date: Date) -> String {
        if let transportLabel { return transportLabel }
        return pauseDate == nil || isScrubbing ? elapsed(at: date) : "PAUSED"
    }

    private func showTransport(_ label: String) {
        transportTaps += 1
        withAnimation(.brightSnappy) { transportLabel = label }
    }

    private func elapsed(at date: Date) -> String {
        let seconds = Int(max(0, (pauseDate ?? date).timeIntervalSince(startDate)))
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
                        Image(systemName: "figure.strengthtraining.traditional")
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
                    isPaused: isPaused,
                    focus: $focusedField,
                    onTickActiveSet: startRest,
                    columnWidths: columnWidths
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
        .onPreferenceChange(ExerciseSetChipWidths.self) { widths in
            columnWidths = widths
        }
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
            active: isResting && !isPaused,
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

    // Only worth asking while sets are still outstanding; a finished run just
    // finishes.
    private func confirmFinish() {
        if hasIncompleteSets {
            isConfirmingFinish = true
        } else {
            finish()
        }
    }

    private var hasIncompleteSets: Bool {
        exercises.contains { $0.sets.contains { !$0.isDone } }
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
    // Skips the rest while one's running; otherwise it's the set that's skipped,
    // and since it was never done there's nothing to log — it drops out of the
    // run and the next set takes over.
    private func skip() {
        if restEndDate != nil {
            restEndDate = nil
            return
        }

        guard let activeSet,
              let index = currentExercise.sets.firstIndex(where: { $0.id == activeSet.id }) else {
            advance()
            return
        }

        withAnimation(.brightSnappy) {
            exercises[currentIndex].sets.remove(at: index)
        }
    }

    // MARK: - Editing the run

    // The run follows the exercise it was on, not the slot it used to sit in, so
    // the index is re-found rather than shuffled along with the new order.
    private func applyEdits(_ edited: [ExerciseActiveExercise]) {
        guard !edited.isEmpty else { return }
        let playing = currentExercise.id
        withAnimation(.brightSnappy) { exercises = edited }
        currentIndex = exercises.firstIndex { $0.id == playing } ?? 0
    }

    private func advance() {
        guard currentIndex + 1 < exercises.count else {
            finish()
            return
        }
        currentIndex += 1
    }

    private func goBack() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    // Winding the disc moves the start rather than the clock, since the elapsed
    // time is the gap between the two — and it can't be wound back past zero.
    private func scrub(by seconds: TimeInterval) {
        isScrubbing = true

        // Rounded, so the notches land the clock on whole seconds however far
        // into one it was when the record was taken hold of.
        let reference = pauseDate ?? Date()
        let elapsed = (reference.timeIntervalSince(startDate) + seconds).rounded()
        startDate = reference.addingTimeInterval(-max(elapsed, 0))
    }

    // Resuming hands back the time the run stood still, so the clock and the
    // disc both carry on from where they stopped.
    private func togglePause() {
        if let pauseDate {
            startDate = startDate.addingTimeInterval(Date().timeIntervalSince(pauseDate))
            self.pauseDate = nil
        } else {
            pauseDate = Date()
        }
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
        let elapsed = max(0, Int((pauseDate ?? date).timeIntervalSince(startDate)))
        return String(format: "%d:%02d", elapsed / 60, elapsed % 60)
    }

    fileprivate enum Constants {
        // The live rows run taller than the ones on customise sets — the design
        // gives the chips more room here.
        // Set rows match the exercise cells everywhere else in the feature, so
        // the height lives in one place rather than being repeated as 68.
        static let rowHeight = ExerciseLibraryRow.Constants.minHeight
        static let keyboardGlyphSize: CGFloat = 30
        static let restSeconds: TimeInterval = 90
        static let pillHeight: CGFloat = 30
        // Until the screen has been measured. Only the very first frame, and the
        // menu starts closed.
        // The menu is designed at 354 of a 402pt screen.
        static let menuWidthRatio: CGFloat = 354.0 / 402.0
        static let elapsedTick: TimeInterval = 1
        static let transportReveal: TimeInterval = 2
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

enum ExerciseSetColumn: Hashable {
    case weight
    case reps
}

// Every chip reports what its own value needs; the list keeps the largest per
// column and hands it back, so "22.5 kg" can't be squeezed into a chip sized
// for "20 kg".
private struct ExerciseSetChipWidths: PreferenceKey {
    static let defaultValue: [ExerciseSetColumn: CGFloat] = [:]

    static func reduce(value: inout [ExerciseSetColumn: CGFloat], nextValue: () -> [ExerciseSetColumn: CGFloat]) {
        value.merge(nextValue()) { max($0, $1) }
    }
}

private struct ExerciseSetValueChip: View {
    @Binding var text: String
    let field: ExerciseSetField
    let column: ExerciseSetColumn
    var unit: String?
    let keyboard: UIKeyboardType
    @FocusState.Binding var focus: ExerciseSetField?
    var width: CGFloat?

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
        .frame(width: max(width ?? 0, Constants.minimumChipWidth), height: Constants.chipHeight)
        .background(Color.defaultBackground, in: Capsule())
        .background {
            measuringLabel
        }
        // The whole capsule takes the tap, not just where the digits happen to
        // land — a two-character number is a small target.
        .contentShape(Capsule())
        .onTapGesture { focus = field }
        .onChange(of: focus) { _, focused in
            guard focused == field else { return }
            selection = TextSelection(insertionPoint: text.endIndex)
        }
    }

    // A copy of the chip's content at its natural size, measured rather than
    // drawn — the visible content is inside a fixed frame, so it can't report
    // what it actually wants.
    private var measuringLabel: some View {
        HStack(spacing: .spacing05x) {
            BrightText(text.isEmpty ? "0" : text, size: .body2, weight: .regular)
                .monospacedDigit()

            if let unit {
                BrightText(unit, size: .body2, weight: .regular)
            }
        }
        .fixedSize()
        .hidden()
        .background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ExerciseSetChipWidths.self,
                    value: [column: proxy.size.width + 2 * .spacing2x]
                )
            }
        }
    }

    private enum Constants {
        static let minimumChipWidth: CGFloat = 60
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
    // Nothing is being worked on while the run stands still.
    let isPaused: Bool
    @FocusState.Binding var focus: ExerciseSetField?
    let onTickActiveSet: () -> Void
    // The widest value in each column, so every chip in it matches.
    var columnWidths: [ExerciseSetColumn: CGFloat] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            HStack(spacing: .spacing0x) {
                setChip

                divider

                ExerciseSetValueChip(
                    text: $set.weight,
                    field: .weight(set.id),
                    column: .weight,
                    unit: "kg",
                    keyboard: .decimalPad,
                    focus: $focus,
                    width: columnWidths[.weight]
                )

                divider

                ExerciseSetValueChip(
                    text: $set.reps,
                    field: .reps(set.id),
                    column: .reps,
                    keyboard: .numberPad,
                    focus: $focus,
                    width: columnWidths[.reps]
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
            active: isActive && !isResting && !isPaused,
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
    // What a run or a sport is chasing. Nil for anything logged set by set.
    var plan: ExerciseCardioPlan?
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

    var workingSetCount: Int {
        sets.filter(\.kind.countsAsSet).count
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

#Preview {
    NavigationStack {
        ExerciseLiveWorkoutSheet()
    }
    .environment(ExerciseBuilder())
}
