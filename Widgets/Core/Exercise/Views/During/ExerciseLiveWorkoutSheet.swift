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
    /// Ends the whole run. Only the flow can do that from a pushed leg, where
    /// `dismiss` would pop back to the pre-workout screen instead.
    var onClose: (() -> Void)?
    /// Handed the logged workout, so the presenter owns what comes next — it
    /// swaps this screen for the summary inside the same presentation.
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
    /// The set rows sit in a `List`, which re-derives its width when the rest
    /// beam's full-screen overlay changes the safe area. Measured from the page
    /// once and pinned, so the rows can't be squeezed mid-animation.
    @State private var pageWidth: CGFloat = 0

    init(
        workoutName: String = "Gym workout",
        templateItems: [ExerciseTemplateItem]? = nil,
        onClose: (() -> Void)? = nil,
        onFinish: @escaping (ExerciseWorkout) -> Void = { _ in }
    ) {
        self.workoutName = workoutName
        self.templateItems = templateItems
        self.onClose = onClose
        self.onFinish = onFinish
        _exercises = State(initialValue: templateItems.map(ExerciseActiveExercise.fromTemplate) ?? ExerciseDemoData.activeExercises)
    }

    var body: some View {
        BrightSideMenu(isExpanded: $isSideMenuExpanded) { _ in
            sideMenu
        } content: { _ in
            page
        }
        // Rest rings the whole sheet; working is signalled on the active set row
        // itself. Outside the side menu so the ring stays put while the content
        // slides, and past every safe-area edge so the nav bar doesn't clip its
        // top run.
        .overlay {
            BrightScreenEdgeBeam(
                isActive: isResting,
                colorVariant: .defaultBlue
            )
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
                            .font(.standardSFPro(size: .subheading, weight: .regular))
                            .foregroundStyle(Color.textColor)
                    }
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
                        .padding(.horizontal, .spacing3x)
                        .padding(.bottom, .spacing2x)
                }
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
        .animation(.brightEaseInOut, value: restEndDate)
        .animation(.brightEaseInOut, value: currentIndex)
        .animation(.brightEaseInOut, value: completedSets)
        .navigationDestination(item: $openedExerciseName) { name in
            if let exercise = ExerciseDemoLibrary.exercise(named: name) {
                ExerciseDetailSheet(exercise: exercise)
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
                    sideMenuItem("Cancel workout", symbol: "xmark", color: .defaultRed, isDestructive: true) {
                        close()
                    }

                    sideMenuItem("End workout", symbol: "flag", color: .defaultRed, isDestructive: true) {
                        finish()
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
                            .font(.standardSFPro(size: .standout3, weight: .light))
                            .foregroundStyle(Color.lightTextColor)
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            BrightText(currentExercise.name, size: .standout3)
                .lineLimit(1)

            Spacer(minLength: .spacing2x)

            BrightRoundButton(systemImage: "chart.line.uptrend.xyaxis", size: .medium) {
                openedExerciseName = currentExercise.name
            }
        }
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
                    isResting: isResting
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
        .listRowSpacing(.spacing2x)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .contentMargins(.vertical, .spacing0x, for: .scrollContent)
        .environment(\.defaultMinListRowHeight, Constants.rowHeight)
        .frame(
            width: pageWidth > 0 ? pageWidth : nil,
            height: (Constants.rowHeight + .spacing2x) * CGFloat(currentExercise.sets.count)
        )
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
        .brightMiniSheet(isPresented: $isPickingRPE) {
            ExerciseValuePicker.rpe(ratedSet(\.rpe)) { isPickingRPE = false }
        }
        .brightMiniSheet(isPresented: $isPickingFailedRep) {
            ExerciseValuePicker.failedSet(targetReps: ratedSetReps, failedRep: failedRep) {
                isPickingFailedRep = false
            }
        }
    }

    /// The set the pickers write to: the one being worked on, or the last one
    /// logged once the exercise is done.
    private var ratedIndex: Int? {
        currentExercise.sets.firstIndex { !$0.isDone } ?? currentExercise.sets.indices.last
    }

    /// A failed set is over, so recording the rep logs it and moves on exactly
    /// the way the tick does.
    private var failedRep: Binding<Int?> {
        let rated = ratedSet(\.failedRep)

        return Binding(
            get: { rated.wrappedValue },
            set: { rep in
                rated.wrappedValue = rep
                guard rep != nil else { return }
                withAnimation(.brightSnappy) { completeActiveSet() }
            }
        )
    }

    private func ratedSet(_ field: WritableKeyPath<ExerciseActiveSet, Int?>) -> Binding<Int?> {
        guard let ratedIndex else { return .constant(nil) }
        return Binding(
            get: { exercises[currentIndex].sets[ratedIndex][keyPath: field] },
            set: { exercises[currentIndex].sets[ratedIndex][keyPath: field] = $0 }
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
        onFinish(finishedWorkout)
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

    /// Cuts rest short so the next set becomes active straight away.
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
        /// The live rows run taller than the ones on customise sets — the design
        /// gives the chips more room here.
        /// Set rows match the exercise cells everywhere else in the feature, so
        /// the height lives in one place rather than being repeated as 68.
        static let rowHeight = ExerciseLibraryRow.Constants.minHeight
        static let restSeconds: TimeInterval = 90
        static let menuIconSize: CGFloat = 24
        static let pillHeight: CGFloat = 30
        static let elapsedTick: TimeInterval = 1
        static let thumbnailSize: CGFloat = 60
        /// Stands in for HealthKit until the workout is wired to real samples.
        static let demoHeartRate = "132"
        static let demoCalories = "412"
    }
}

private struct ExerciseLiveSetRow: View {
    @Binding var set: ExerciseActiveSet
    let index: Int
    let isActive: Bool
    /// The active row still marks what's up next during rest, but the beam is the
    /// working signal, so it stands down while the sheet's rest ring is up.
    let isResting: Bool

    var body: some View {
        HStack(spacing: .spacing0x) {
            setChip

            divider

            valueChip($set.weight, unit: "kg", keyboard: .decimalPad)

            divider

            valueChip($set.reps, keyboard: .numberPad)

            Spacer(minLength: .spacing2x)

            if let rpe = set.rpe {
                BrightStatus(status: "RPE \(rpe)")
                    .padding(.trailing, .spacing2x)
                    .transition(.scale.combined(with: .opacity))
            }

            if let failedRep = set.failedRep {
                BrightText("Rep \(failedRep)", size: .body2, color: .defaultRed, weight: .regular)
                    .monospacedDigit()
                    .fixedSize()
                    .padding(.trailing, .spacing2x)
                    .transition(.scale.combined(with: .opacity))
            }

            Button {
                set.isDone.toggle()
            } label: {
                tickControl
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, .spacing3x)
        .frame(height: ExerciseLiveWorkoutSheet.Constants.rowHeight)
        .modifier(CardModifier(cornerRadius: .cornerRadius24))
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

    /// A failed set takes the cross in the tick's place. Both stay mounted so the
    /// cross lands with its own symbol replace and haptic, the way the tick does,
    /// rather than being swapped in cold — and the tick holds its unticked state
    /// while the cross is up so only one of them speaks.
    private var tickControl: some View {
        ZStack {
            BrightTick(isTicked: set.isDone && !isFailed)
                .opacity(isFailed ? .zero : .opaque)
                .scaleEffect(isFailed ? Constants.hiddenTickScale : 1)

            BrightCross(isCrossed: isFailed)
                .opacity(isFailed ? .opaque : .zero)
                .scaleEffect(isFailed ? 1 : Constants.hiddenTickScale)
        }
    }

    private var isFailed: Bool {
        // Qualified: a bare `set` at the head of an accessor body parses as the
        // setter keyword, not the binding.
        self.set.failedRep != nil
    }

    @ViewBuilder private var setChip: some View {
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
        .background(Color.defaultCapsule, in: Circle())
    }

    private var divider: some View {
        BrightVerticalDivider(height: Constants.dividerHeight)
            .padding(.horizontal, .spacing2x)
    }

    private func valueChip(
        _ text: Binding<String>,
        unit: String? = nil,
        keyboard: UIKeyboardType
    ) -> some View {
        HStack(spacing: .spacing05x) {
            TextField("0", text: text)
                .font(.standard(size: .body2, weight: .regular))
                .foregroundStyle(Color.textColor)
                .keyboardType(keyboard)
                .multilineTextAlignment(unit == nil ? .center : .trailing)
                .monospacedDigit()
                .fixedSize()

            if let unit {
                BrightText(unit, size: .body2, weight: .regular)
                    .fixedSize()
            }
        }
        .frame(width: Constants.valueChipWidth, height: Constants.chipHeight)
        .background(Color.defaultBackground, in: Capsule())
    }

    private enum Constants {
        static let chipHeight: CGFloat = 30
        static let valueChipWidth: CGFloat = 60
        static let dividerHeight: CGFloat = 34
        static let hiddenTickScale: CGFloat = 0.6
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
    /// Rated after the set is logged, so it stays empty until the picker sets it.
    var rpe: Int?
    /// The rep the set went down on, once it's been marked as failed.
    var failedRep: Int?
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
        ExerciseLiveWorkoutSheet()
    }
}
