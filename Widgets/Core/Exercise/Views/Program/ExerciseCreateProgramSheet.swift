//
//  ExerciseCreateProgramSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 21/8/2026.
//

import SwiftUI

enum ExerciseProgramRoute: Hashable {
    case sessions(creates: Bool, block: UUID? = nil)
}

nonisolated struct ExerciseTrainingBlock: Identifiable, Equatable {
    let id: UUID
    var name: String
    // A block is a week long until its own planner says otherwise.
    var weeks: Int

    init(id: UUID = UUID(), name: String, weeks: Int = 1) {
        self.id = id
        self.name = name
        self.weeks = weeks
    }
}

nonisolated struct ExercisePeriodHandover: Identifiable {
    let id: UUID
    let stopping: ExerciseTrainingPeriod
}

nonisolated enum ExercisePeriodState {
    case upcoming
    case running
    case finished
}

nonisolated enum ExerciseBlockStatus {
    case upcoming
    case inProgress
    case done
}

nonisolated struct ExerciseTrainingPeriod: Identifiable, Equatable {
    let id: UUID
    var name: String
    var blocks: [ExerciseTrainingBlock]
    var isStarted: Bool
    var completedWeeks: Int

    init(
        id: UUID = UUID(),
        name: String = "",
        blocks: [ExerciseTrainingBlock],
        isStarted: Bool = false,
        completedWeeks: Int = 0
    ) {
        self.id = id
        self.name = name
        self.blocks = blocks
        self.isStarted = isStarted
        self.completedWeeks = completedWeeks
    }

    static var empty: Self {
        ExerciseTrainingPeriod(blocks: [ExerciseTrainingBlock(name: "Block 1")])
    }

    var totalWeeks: Int {
        blocks.map(\.weeks).reduce(0, +)
    }

    var fractionComplete: CGFloat {
        guard totalWeeks > 0 else { return 0 }
        return min(1, CGFloat(completedWeeks) / CGFloat(totalWeeks))
    }

    var percentComplete: Int {
        Int((fractionComplete * 100).rounded())
    }

    var isFinished: Bool {
        totalWeeks > 0 && completedWeeks >= totalWeeks
    }

    // Where the weeks done so far land tells each block whether it is behind,
    // under way, or still ahead.
    func status(of block: ExerciseTrainingBlock, isRunning: Bool) -> ExerciseBlockStatus {
        guard isRunning else { return .upcoming }

        var start = 0
        for item in blocks {
            let length = item.weeks
            if item.id == block.id {
                if completedWeeks >= start + length, length > 0 { return .done }
                return completedWeeks >= start ? .inProgress : .upcoming
            }
            start += length
        }
        return .upcoming
    }
}

// Builds a program in one sheet: an intro, a guided-or-custom fork, the template
// style and — when the template periodises — how many weeks it runs and the
// training periods it splits into, before pushing a block's week to the planner.
struct ExerciseCreateProgramSheet: View {
    // Entered from the calendar's edit button: the flow opens on the plan
    // itself, so the blocks screen is the root and the week sits on top of it.
    var startsAtBlocks = false

    @Environment(\.dismiss) private var dismiss

    @FocusState private var isTyping: Bool

    @State private var step: Step

    @State private var stylePage: Int? = ProgramStyle.guided.rawValue

    @State private var sportIndex = 0

    @State private var name: String

    @State private var template: Template?

    @State private var weeks = Constants.defaultWeeks

    @State private var nameNudge = 0

    @State private var periodNudge = 0

    // The period whose name field is being pointed at, and the card the list
    // should bring into view.
    @State private var nudgedPeriod: UUID?

    @State private var scrollTarget: UUID?

    // Bumped whenever a period is started or finished, so the change is felt.
    @State private var periodTick = 0

    // Set while the athlete is being asked about jumping ahead of a period that
    // is part way through.
    @State private var pendingStart: ExercisePeriodHandover?

    @State private var isAtBottom = true

    @State private var periods: [ExerciseTrainingPeriod]

    @State private var path: NavigationPath

    @State private var insertionEdge = Edge.trailing

    @State private var showingDeleteProgram = false

    private let initialName: String
    private let initialPeriods: [ExerciseTrainingPeriod]

    init(startsAtBlocks: Bool = false) {
        self.startsAtBlocks = startsAtBlocks
        _step = State(initialValue: startsAtBlocks ? .periods : .intro)
        _path = State(initialValue: NavigationPath())
        // Editing opens on the program that already exists; creating starts from
        // the one empty block the first step fills in.
        let seed = startsAtBlocks ? Constants.guidedPeriods : [ExerciseTrainingPeriod.empty]
        _periods = State(initialValue: seed)
        _name = State(initialValue: startsAtBlocks ? Constants.guidedName : "")
        initialName = startsAtBlocks ? Constants.guidedName : ""
        initialPeriods = seed
    }

    var body: some View {
        BrightPageSheetView(
            horizontalPadding: .spacing0x,
            // The root step has nothing to go back to, so it closes instead.
            showBackButton: step != rootStep,
            backButtonCallback: goBack,
            path: $path,
            trailing: {
                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(file: #file)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if let trailingTitle {
                        Button(trailingTitle, action: advance)
                            .buttonStyle(.borderedProminent)
                            .tint(canAdvance ? .defaultSkyBlue : .defaultMainGrey)
                            .id(canAdvance)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
            },
            content: {
                ZStack {
                    // Always in the tree and faded rather than swapped in and
                    // out — re-inserting the wash mid-transition flashes the
                    // plain sheet through for a beat.
                    ExerciseProgramBackground()
                        .opacity(step.showsWash ? .opaque : 0)

                    stepContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                    .safeAreaInset(edge: .bottom) {
                        if let ctaTitle {
                            BrightFullWidthButton(ctaTitle, color: .defaultWhite, textColor: .defaultBlack) {
                                advance()
                            }
                            .padding(.horizontal, .spacing3x)
                            .opacity(canAdvance ? .opaque : .semiLowOpacity)
                            .animation(.brightEaseInOut, value: canAdvance)
                        }
                    }
                    .navigationDestination(for: ExerciseProgramRoute.self) { route in
                        destination(for: route)
                    }
            }
        )
    }

    @ViewBuilder
    private func destination(for route: ExerciseProgramRoute) -> some View {
        switch route {
        case let .sessions(creates, block):
            ExerciseAddSessionsSheet(
                isCreating: creates,
                startsEmpty: chosenStyle == .custom,
                title: block.map(sessionsTitle),
                blockLength: block.map(blockLength),
                onDone: creates ? { dismiss() } : nil
            )
        }
    }

    // MARK: - Steps

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .intro: intro.transition(slide)
        case .style: stylePager.transition(slide)
        case .goals: chatStep.transition(slide)
        case .name: nameField.transition(slide)
        case .template: templatePicker.transition(slide)
        case .weeks: lengthPicker.transition(slide)
        case .periods: periodList.transition(slide)
        }
    }

    // Forward arrives from the right and back from the left, so the wizard
    // reads as a stack even without a progress indicator. The outgoing step
    // fades in place rather than sliding across the incoming one — two views
    // moving at full opacity ghost each other.
    private var slide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .opacity
        )
    }

    // MARK: Intro

    private var intro: some View {
        VStack(spacing: .spacing0x) {
            Spacer(minLength: .spacing0x)

            sportIcon
                .padding(.bottom, .spacing7x)

            heroTitle("Programs")

            blurb("Welcome to Exercise. Here you can create and plan your sessions to suit your goals and schedule.")
                .padding(.top, .spacing4x)

            Spacer(minLength: .spacing0x)
        }
        .padding(.horizontal, .spacing3x)
    }

    // The sports a program can be built from, one at a time: on a beat the
    // glyph morphs into the next with the symbol replace effect.
    private var sportIcon: some View {
        Image(systemName: Constants.sportSymbols[sportIndex])
            .font(.system(size: Constants.sportIconSize, weight: .light))
            .foregroundStyle(Color.defaultSlateBlue)
            .contentTransition(.symbolEffect(.replace))
            .frame(height: Constants.sportIconSize)
            .task {
                while true {
                    do {
                        try await Task.sleep(for: .seconds(Constants.sportSwapEvery))
                    } catch {
                        return
                    }
                    withAnimation(.brightEaseInOut) {
                        sportIndex = (sportIndex + 1) % Constants.sportSymbols.count
                    }
                }
            }
    }

    // MARK: Guided or custom

    private var stylePager: some View {
        VStack(spacing: .spacing3x) {
            Spacer(minLength: .spacing0x)

            BrightCarousel(items: ProgramStyle.allCases, activeIndex: $stylePage) { style, width in
                styleCard(style, width: width)
            }

            BrightPageIndicator(total: ProgramStyle.allCases.count, activeIndex: $stylePage)
                .padding(.top, .spacing4x)

            Spacer(minLength: .spacing0x)
        }
    }

    // The glyph sits at the top and the words at the foot, so the two cards read
    // as a matched pair however long their copy runs.
    private func styleCard(_ style: ProgramStyle, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            Image(systemName: style.symbol)
                .font(.system(size: Constants.styleIconSize, weight: .light))
                .foregroundStyle(Color.defaultBlack)
                .frame(width: Constants.styleIconSize, height: Constants.styleIconSize, alignment: .leading)

            Spacer(minLength: .spacing4x)

            BrightText(style.title, size: .subheading, color: .defaultBlack, weight: .regular)

            BrightText(style.blurb, size: .body2, color: .defaultBlack.opacity(.lowOpacity))
                .multilineTextAlignment(.leading)
                .lineSpacing(.lineSpacingMedium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacing3x)
        .frame(width: width, height: width * Constants.styleCardAspect, alignment: .leading)
        .background(
            Color.defaultWhite,
            in: RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous)
        )
    }

    // MARK: Guided — AI chat

    // The guided fork talks to the coach: describe the goals, get the proposed
    // weeks back, and the chat's own confirm carries the flow to the blocks.
    private var chatStep: some View {
        ExerciseChatView {
            seedGuidedPlan()
            go(to: .periods)
        }
    }

    // MARK: Custom — program name

    private var nameField: some View {
        VStack(spacing: .spacing0x) {
            Spacer(minLength: .spacing0x)

            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: Constants.heroIconSize, weight: .light))
                .foregroundStyle(Color.defaultSlateBlue)
                .padding(.bottom, .spacing3x)

            TextField("", text: $name)
                .focused($isTyping)
                .font(.standard(size: .huge205, weight: .light))
                .foregroundStyle(Color.defaultSlateBlue)
                .multilineTextAlignment(.center)
                .submitLabel(.done)
                .onSubmit(advance)
                .brightWiggle(trigger: nameNudge)
                .overlay {
                    if name.isEmpty {
                        BrightText("Name your program", size: .huge205, color: .defaultSlateBlue)
                            .allowsHitTesting(false)
                    }
                }

            Spacer(minLength: .spacing0x)
            Spacer(minLength: .spacing0x)
        }
        .padding(.horizontal, .spacing3x)
        .onAppear { isTyping = true }
    }

    // MARK: Template style

    private var templatePicker: some View {
        VStack(spacing: .spacing3x) {
            twoToneTitle(blue: "Template", plain: "style")
                .padding(.top, .spacing6x)
                .padding(.vertical, .spacing3x)

            ForEach(Template.allCases) { option in
                templateCard(option)
            }

            Spacer(minLength: .spacing0x)
        }
        .padding(.horizontal, .spacing3x)
        .brightHaptic(.light, trigger: template)
    }

    private func templateCard(_ option: Template) -> some View {
        let isSelected = template == option
        // The selected fill is white in both modes, so its copy is always black.
        let copyColor: Color = isSelected ? .defaultBlack : .textColor
        let detailColor: Color = isSelected ? .defaultBlack.opacity(.lowOpacity) : .lightTextColor

        return Button {
            withAnimation(.brightSnappy) { template = option }
        } label: {
            VStack(alignment: .leading, spacing: .spacing105x) {
                Image(systemName: option.symbol)
                    .font(.system(size: Constants.promptIconSize, weight: .light))
                    .foregroundStyle(copyColor)

                BrightText(option.title, size: .subheading, color: copyColor, weight: .regular)

                BrightText(option.detail, size: .body2, color: detailColor)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(.lineSpacingMedium)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.spacing3x)
            .modifier(GlassCardModifier(cornerRadius: .cornerRadius24))
            // Behind the glass rather than inside it, so the fill stays a
            // solid card colour instead of taking the glass's tint.
            .background(
                isSelected ? Color.defaultWhite : .clear,
                in: RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Length

    private var lengthPicker: some View {
        VStack(spacing: .spacing0x) {
            Spacer(minLength: .spacing0x)

            BrightText("\(weeks)", size: .enormous, color: .defaultSlateBlue)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.brightSnappy, value: weeks)

            BrightText(weeks == 1 ? "week" : "weeks", size: .standout1, color: .defaultSlateBlue)

            blurb("How long do you want your program to be?")
                .padding(.top, .spacing4x)

            Spacer(minLength: .spacing0x)

            BrightPicker(
                value: $weeks,
                range: Constants.weekRange,
                majorEvery: Constants.weekMajorEvery,
                showsLabels: true
            )
            .frame(height: Constants.rulerHeight)
            .padding(.bottom, .spacing3x)
        }
    }

    // MARK: Training periods

    // A periodised program is a list of periods, each holding the blocks whose
    // weeks add up to the period's total. A block's row leads to its own week.
    private var periodList: some View {
        ScrollViewReader { scroller in
            ScrollView(showsIndicators: false) {
                VStack(spacing: .spacing3x) {
                    TextField("", text: $name)
                        .font(.standard(size: .huge205, weight: .light))
                        .foregroundStyle(Color.textColor)
                        .submitLabel(.done)
                        .overlay(alignment: .leading) {
                            if name.isEmpty {
                                BrightText("Program Name", size: .huge205, color: .lightTextColor)
                                    .allowsHitTesting(false)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach($periods) { $period in
                        periodCard($period)
                            .id(period.id)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding(.horizontal, .spacing3x)
                .padding(.vertical, .spacing3x)
            }
            .safeAreaInset(edge: .bottom) {
                planActions(scroller)
            }
            .animation(.brightSnappy, value: periods)
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.containerSize.height
                    >= geometry.contentSize.height - Constants.bottomSlack
            } action: { _, atBottom in
                isAtBottom = atBottom
            }
            .onChange(of: scrollTarget) { _, target in
                guard let target else { return }
                withAnimation(.brightSnappy) { scroller.scrollTo(target, anchor: .center) }
                scrollTarget = nil
            }
        }
        .alert(
            "Start this period?",
            isPresented: Binding(
                get: { pendingStart != nil },
                set: { if !$0 { pendingStart = nil } }
            ),
            presenting: pendingStart
        ) { handover in
            Button("Start") {
                if let period = periods.first(where: { $0.id == handover.id }) {
                    start(period)
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: { handover in
            Text(
                "\(handover.stopping.name) will stop at "
                    + "\(handover.stopping.completedWeeks) of \(handover.stopping.totalWeeks) weeks."
            )
        }
        .alert("Delete this program?", isPresented: $showingDeleteProgram) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                dismiss()
            }
            .tint(.defaultRed)
        } message: {
            Text("Are you sure you want to delete this program?")
        }
    }

    private func planActions(_ scroller: ScrollViewProxy) -> some View {
        HStack(spacing: .spacing0x) {
            if startsAtBlocks {
                BrightRoundButton(
                    systemImage: "trash",
                    size: .finalBossLarge,
                    imageColor: .defaultRed
                ) {
                    showingDeleteProgram = true
                }
            }

            Spacer(minLength: .spacing0x)

            addPeriodButton(scroller)
        }
        .padding(.spacing3x)
    }

    private func addPeriodButton(_ scroller: ScrollViewProxy) -> some View {
        BrightRoundButton(systemImage: "plus", size: .finalBossLarge) {
            var period = ExerciseTrainingPeriod.empty
            period.name = "Training Period \(periods.count + 1)"
            withAnimation(.brightSnappy) {
                periods.append(period)
            }
            // Already at the end of the list, the new card lands in view on its
            // own; anywhere else it has to be brought there.
            if !isAtBottom {
                scrollTarget = period.id
            }
        }
    }

    private func periodCard(_ period: Binding<ExerciseTrainingPeriod>) -> some View {
        VStack(spacing: .spacing4x) {
            periodHeader(period)

            progressRow(period.wrappedValue)

            BrightDivider()

            blockList(period)

            HStack(spacing: .spacing0x) {
                Spacer(minLength: .spacing0x)

                BrightRoundButton(systemImage: "plus") {
                    addBlock(to: period)
                }
            }
        }
        .padding(.spacing3x)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
        .brightHaptic(trigger: periodTick) { _, _ in .success }
    }

    // The weeks done against the weeks planned, with the same figure as a ring.
    private func progressRow(_ period: ExerciseTrainingPeriod) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
            BrightText("\(period.completedWeeks)", size: .giant)
                .monospacedDigit()
                .contentTransition(.numericText())

            BrightText("/\(period.totalWeeks) weeks", size: .standout4, color: .lightTextColor)
                .monospacedDigit()
                .contentTransition(.numericText())

            Spacer(minLength: .spacing2x)

            progressRing(period)
                // Sits the ring on the weeks label's centre rather than on the
                // baseline the two numbers share.
                .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + .spacing1x }
        }
        .animation(.brightSnappy, value: period.completedWeeks)
        .animation(.brightSnappy, value: period.totalWeeks)
        // The ring, not the tall number, sets the row's height, so the card's
        // own spacing lands as an even gap above and below it.
        .frame(height: Constants.ringDiameter)
        .padding(.bottom, .spacing105x)
    }

    // A `List` rather than a plain stack so the rows take `swipeActions`; it
    // can't scroll inside the screen's scroll view, so it states its own
    // height — same shape as the create-session sets list.
    private func blockList(_ period: Binding<ExerciseTrainingPeriod>) -> some View {
        let count = period.wrappedValue.blocks.count

        return List {
            ForEach(period.blocks) { $block in
                blockRow($block, in: period.wrappedValue, isRunning: state(of: period.wrappedValue) != .upcoming)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            removeBlock($block.wrappedValue, from: period)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(.defaultRed)
                    }
            }
        }
        .listStyle(.plain)
        .listRowSpacing(.spacing2x)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .contentMargins(.vertical, .spacing0x, for: .scrollContent)
        .environment(\.defaultMinListRowHeight, Constants.blockRowHeight)
        .frame(
            height: CGFloat(count) * Constants.blockRowHeight
                + CGFloat(max(0, count - 1)) * .spacing2x
        )
    }

    private func periodHeader(_ period: Binding<ExerciseTrainingPeriod>) -> some View {
        HStack(spacing: .spacing105x) {
            Image(systemName: state(of: period.wrappedValue) == .upcoming ? "circle.hexagonpath" : "circle.hexagonpath.fill")
                .contentTransition(.symbolEffect(.replace))
                .font(.system(size: Constants.promptIconSize, weight: .light))
                .foregroundStyle(Color.semiLightTextColor)

            TextField("Training period name", text: period.name)
                .font(.standard(size: .body1, weight: .light))
                .foregroundStyle(Color.textColor)
                .brightWiggle(trigger: nudgedPeriod == period.wrappedValue.id ? periodNudge : 0)

            Menu {
                switch state(of: period.wrappedValue) {
                case .upcoming:
                    Button("Start period", systemImage: "play.circle") {
                        askToStart(period.wrappedValue)
                    }
                case .running:
                    Button("Restart period", systemImage: "arrow.counterclockwise") {
                        period.wrappedValue.completedWeeks = 0
                    }
                    // Ending a period is finishing it, so the next one picks up.
                    Button("End period", systemImage: "stop.circle") {
                        period.wrappedValue.isStarted = true
                        period.wrappedValue.completedWeeks = period.wrappedValue.totalWeeks
                        periodTick += 1
                    }
                case .finished:
                    Button("Restart period", systemImage: "arrow.counterclockwise") {
                        period.wrappedValue.isStarted = true
                        period.wrappedValue.completedWeeks = 0
                    }
                }

                Button("Delete period", systemImage: "trash", role: .destructive) {
                    remove(period.wrappedValue)
                }
                .tint(.defaultRed)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.standard(size: .standout4, weight: .light))
                    .foregroundStyle(Color.semiLightTextColor)
            }
        }
    }

    // Only one period is ever the current one, so starting a later one stops the
    // one running now — stops, not completes: its weeks stay as they were done.
    private func askToStart(_ period: ExerciseTrainingPeriod) {
        guard let running = periods.first(where: { state(of: $0) == .running }),
              running.id != period.id,
              running.completedWeeks > 0 else {
            start(period)
            return
        }

        pendingStart = ExercisePeriodHandover(id: period.id, stopping: running)
    }

    private func start(_ period: ExerciseTrainingPeriod) {
        withAnimation(.brightSnappy) {
            for index in periods.indices {
                if periods[index].id == period.id {
                    periods[index].isStarted = true
                } else if !periods[index].isFinished {
                    periods[index].isStarted = false
                }
            }
        }
        periodTick += 1
    }

    // A program runs in order, so the period after a finished one picks up by
    // itself; starting one by hand only matters at the front of the program or
    // when the athlete jumps ahead.
    private func state(of period: ExerciseTrainingPeriod) -> ExercisePeriodState {
        if period.isFinished { return .finished }

        if period.isStarted { return .running }

        guard !period.blocks.isEmpty,
              let index = periods.firstIndex(where: { $0.id == period.id }),
              index > 0,
              periods[..<index].allSatisfy(\.isFinished) else { return .upcoming }

        return .running
    }

    private func sessionsTitle(_ id: UUID) -> String {
        for period in periods {
            guard let block = period.blocks.first(where: { $0.id == id }) else { continue }
            return period.name.isEmpty ? block.name : "\(period.name) - \(block.name)"
        }
        return ""
    }

    private func blockLength(_ id: UUID) -> Binding<Int> {
        Binding(
            get: {
                periods.lazy.compactMap { $0.blocks.first { $0.id == id } }.first?.weeks ?? 1
            },
            set: { weeks in
                for period in periods.indices {
                    guard let block = periods[period].blocks.firstIndex(where: { $0.id == id }) else { continue }
                    periods[period].blocks[block].weeks = weeks
                }
            }
        )
    }

    private func blockRow(
        _ block: Binding<ExerciseTrainingBlock>,
        in period: ExerciseTrainingPeriod,
        isRunning: Bool
    ) -> some View {
        Button {
            path.append(ExerciseProgramRoute.sessions(creates: false, block: block.wrappedValue.id))
        } label: {
            HStack(spacing: .spacing0x) {
                BrightText(block.wrappedValue.name, size: .body2, color: .semiLightTextColor)
                    .frame(width: Constants.blockNameWidth, alignment: .leading)
                    .padding(.leading, .spacing2x)

                Rectangle()
                    .fill(Color.textColor.opacity(.ultraLowOpacity))
                    .frame(width: Constants.hairline)

                BrightText(weeksLabel(block.wrappedValue.weeks), size: .body2, color: .semiLightTextColor)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.brightSnappy, value: block.wrappedValue.weeks)
                    .padding(.leading, .spacing2x)

                Spacer(minLength: .spacing2x)

                blockStatus(period.status(of: block.wrappedValue, isRunning: isRunning))
                    .animation(.brightSnappy, value: period.status(of: block.wrappedValue, isRunning: isRunning))

                Image(systemName: "chevron.right")
                    .font(.system(size: FontSizes.body1.rawValue, weight: .medium))
                    .foregroundStyle(Color.lightTextColor)
                    .padding(.horizontal, .spacing2x)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Constants.blockRowHeight)
            .background(
                Color.exerciseRowTint,
                in: RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func blockStatus(_ status: ExerciseBlockStatus) -> some View {
        switch status {
        case .done:
            BrightTick(isTicked: true)
                .allowsHitTesting(false)
                .transition(.opacity.combined(with: .scale))
        case .inProgress:
            BrightStatus(status: "In Progress")
                .transition(.opacity.combined(with: .scale))
        case .upcoming:
            EmptyView()
        }
    }

    private func removeBlock(_ block: ExerciseTrainingBlock, from period: Binding<ExerciseTrainingPeriod>) {
        withAnimation(.brightSnappy) {
            period.wrappedValue.blocks.removeAll { $0.id == block.id }
        }
    }

    // Starting, restarting or ending a period sweeps the ring rather than
    // snapping it.
    private func progressRing(_ period: ExerciseTrainingPeriod) -> some View {
        ZStack {
            BrightText("\(period.percentComplete)%", size: .subheading1)
                .monospacedDigit()
                .contentTransition(.numericText())

            Circle()
                .stroke(Color.defaultPurple.opacity(.minimalOpacity), lineWidth: Constants.ringWidth)

            Circle()
                .trim(from: 0, to: period.fractionComplete)
                .stroke(
                    Color.defaultPurple,
                    style: StrokeStyle(lineWidth: Constants.ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: Constants.ringDiameter, height: Constants.ringDiameter)
        .animation(.brightSnappy, value: period.fractionComplete)
    }

    // MARK: - Shared pieces

    private func heroTitle(_ text: String) -> some View {
        BrightText(text, size: .huge205, color: .defaultSlateBlue)
    }

    // The screen's subject in blue, what you do to it in ink — the pairing the
    // template screen leads with.
    private func twoToneTitle(blue: String, plain: String) -> some View {
        HStack(spacing: .spacing1x) {
            BrightText(blue, size: .huge205, color: .defaultSlateBlue)
            BrightText(plain, size: .huge205, color: .semiLightTextColor)
        }
    }

    private func blurb(_ text: String) -> some View {
        BrightText(text, size: .body1)
            .multilineTextAlignment(.center)
            .lineSpacing(.lineSpacingMedium)
            .frame(maxWidth: Constants.blurbWidth)
    }

    // MARK: - Navigation

    private func advance() {
        guard canAdvance else {
            if step == .name { nameNudge += 1 }
            return
        }

        switch step {
        case .intro:
            go(to: .style)
        case .style:
            go(to: chosenStyle == .guided ? .goals : .name)
        // The guided path skips the template fork: describing goals leads
        // straight to the blocks, arriving with the plan already decided.
        case .goals:
            seedGuidedPlan()
            go(to: .periods)
        case .name:
            go(to: .template)
        case .template:
            if template == .periodise {
                go(to: .weeks)
            } else {
                // A single block skips the periods list and plans its week
                // directly.
                isTyping = false
                path.append(ExerciseProgramRoute.sessions(creates: true))
            }
        case .weeks:
            go(to: .periods)
        case .periods:
            // A period with no name has nothing to show on the calendar, so the
            // flow stops on it rather than saving it blank.
            if let unnamed = periods.first(where: { $0.name.trimmingCharacters(in: .whitespaces).isEmpty }) {
                isTyping = false
                nudgedPeriod = unnamed.id
                periodNudge += 1
                scrollTarget = unnamed.id
                return
            }
            dismiss()
        }
    }

    private func goBack() {
        switch step {
        case .intro:
            dismiss()
        case .style:
            go(to: .intro, backwards: true)
        case .goals, .name:
            go(to: .style, backwards: true)
        case .template:
            go(to: .name, backwards: true)
        case .weeks:
            go(to: .template, backwards: true)
        case .periods:
            go(to: chosenStyle == .guided ? .goals : .weeks, backwards: true)
        }
    }

    // New blocks start at the length picked on the ruler, so the period's total
    // means something the moment one is added.
    private func addBlock(to period: Binding<ExerciseTrainingPeriod>) {
        // Numbering restarts in every period, so it only has to dodge the names
        // this card already holds.
        let taken = period.wrappedValue.blocks.compactMap { Int($0.name.dropFirst("Block ".count)) }
        let next = (taken.max() ?? 0) + 1
        withAnimation(.brightSnappy) {
            period.wrappedValue.blocks.append(ExerciseTrainingBlock(name: "Block \(next)", weeks: weeks))
        }
    }

    private func remove(_ period: ExerciseTrainingPeriod) {
        withAnimation(.brightSnappy) { periods.removeAll { $0.id == period.id } }
    }

    private func go(to next: Step, backwards: Bool = false) {
        isTyping = false
        insertionEdge = backwards ? .leading : .trailing
        withAnimation(.brightSnappy) { step = next }
    }

    // Stands in for what the AI would build from the goals. Only replaces an
    // untouched plan, so edits survive a trip back to the goals step.
    private func seedGuidedPlan() {
        if name.isEmpty { name = Constants.guidedName }

        let untouched = periods.count == 1
            && periods.first?.blocks.count == 1
            && periods.first?.totalWeeks == 0
        if untouched { periods = Constants.guidedPeriods }
    }

    // MARK: - Derived state

    private func weeksLabel(_ count: Int) -> String {
        "\(count) \(count == 1 ? "week" : "weeks")"
    }

    private var rootStep: Step {
        startsAtBlocks ? .periods : .intro
    }

    private var chosenStyle: ProgramStyle {
        ProgramStyle(rawValue: stylePage ?? 0) ?? .guided
    }

    // The blocks screen keeps its action in the toolbar, and the length step
    // offers its skip there; every other step advances from the full-width
    // button at the foot.
    private var trailingTitle: String? {
        switch step {
        case .weeks: "Skip"
        // Editing an existing plan only offers the action once the plan differs
        // from the one it opened with.
        case .periods: startsAtBlocks ? (hasPlanChanges ? "Update" : nil) : "Create"
        default: nil
        }
    }

    private var hasPlanChanges: Bool {
        name != initialName || periods != initialPeriods
    }

    private var ctaTitle: String? {
        switch step {
        case .intro: "Create program"
        case .style, .name, .template, .weeks: "Next"
        // The chat's confirm advances the guided step, so its input bar owns
        // the foot of that screen.
        case .goals, .periods: nil
        }
    }

    private var canAdvance: Bool {
        switch step {
        case .intro, .style, .weeks, .periods: true
        // The guided path can move on without goals typed; the custom path can't
        // save a program with no name.
        case .goals: true
        case .name: !name.trimmingCharacters(in: .whitespaces).isEmpty
        case .template: template != nil
        }
    }

    // MARK: - Model

    private enum Step {
        case intro
        case style
        case goals
        case name
        case template
        case weeks
        case periods

        // The blue wash carries the builder's hero screens. The periods screen is
        // a working list, so it sits on the plain sheet like the planner it leads to.
        var showsWash: Bool { self != .periods }
    }

    private enum ProgramStyle: Int, CaseIterable, Identifiable {
        case guided
        case custom

        var id: Int { rawValue }

        var symbol: String {
            switch self {
            case .guided: "hand.wave"
            case .custom: "hand.tap"
            }
        }

        var title: String {
            switch self {
            case .guided: "Guided"
            case .custom: "Custom"
            }
        }

        var blurb: String {
            switch self {
            case .guided:
                "Describe to us your goals and we'll create a program suited for you."
            case .custom:
                "Write the program yourself, choosing every block and session it runs."
            }
        }
    }

    private enum Template: CaseIterable, Identifiable {
        case periodise
        case singleBlock

        var id: Self { self }

        var symbol: String {
            switch self {
            case .periodise: "circles.hexagongrid"
            case .singleBlock: "1.square"
            }
        }

        var title: String {
            switch self {
            case .periodise: "Periodise"
            case .singleBlock: "Single Block"
            }
        }

        var detail: String {
            switch self {
            case .periodise:
                "This template allows you to shift your workout goals, weight, and rep numbers over time. "
                    + "Instead of doing the same routine every week, you split your training into distinct phases "
                    + "such as building muscle size, raw strength, or power. This stops your progress from stalling."
            case .singleBlock:
                "This template gives you a single block to plan your workouts in. Single blocks are ideal for "
                    + "short term goals or refreshing your fitness levels without long term planning and commitment."
            }
        }
    }

    private enum Constants {
        static let defaultWeeks = 6
        static let weekRange = 1 ... 52
        static let weekMajorEvery = 5
        static let sportIconSize: CGFloat = 64
        static let sportSymbols = [
            "figure.volleyball", "figure.basketball",
            "figure.outdoor.cycle", "figure.run", "figure.badminton",
            "figure.strengthtraining.traditional", "figure.boxing",
            "figure.tennis", "figure.pool.swim", "figure.hiking",
            "figure.yoga", "figure.jumprope", "figure.dance",
            "figure.rower", "figure.core.training", "figure.cooldown",
            "figure.golf", "figure.climbing",
        ]
        static let sportSwapEvery: TimeInterval = 1.5

        static let guidedName = "My Program"

        static var guidedPeriods: [ExerciseTrainingPeriod] {
            [
                ExerciseTrainingPeriod(
                    name: "Foundation",
                    blocks: [
                        ExerciseTrainingBlock(name: "Block 1", weeks: 4),
                        ExerciseTrainingBlock(name: "Block 2", weeks: 6),
                        ExerciseTrainingBlock(name: "Block 3", weeks: 3),
                    ],
                    isStarted: true,
                    completedWeeks: 7
                ),
                ExerciseTrainingPeriod(name: "Build", blocks: [
                    ExerciseTrainingBlock(name: "Block 1", weeks: 5),
                    ExerciseTrainingBlock(name: "Block 2", weeks: 2),
                    ExerciseTrainingBlock(name: "Block 3", weeks: 4),
                ]),
                ExerciseTrainingPeriod(name: "Peak", blocks: [
                    ExerciseTrainingBlock(name: "Block 1", weeks: 3),
                    ExerciseTrainingBlock(name: "Block 2", weeks: 1),
                ]),
                ExerciseTrainingPeriod(name: "Taper", blocks: [
                    ExerciseTrainingBlock(name: "Block 1", weeks: 2),
                    ExerciseTrainingBlock(name: "Block 2", weeks: 5),
                ]),
                ExerciseTrainingPeriod(name: "Recovery", blocks: [
                    ExerciseTrainingBlock(name: "Block 1", weeks: 1),
                ]),
            ]
        }
        static let heroIconSize: CGFloat = 34
        static let promptIconSize: CGFloat = 22
        // Tall enough for a major tick, the label gap and a full body1 label,
        // so the ruler's edge-fade mask never clips the numbers.
        static let rulerHeight: CGFloat = 60
        static let blockRowHeight = ExerciseSetRow.Constants.rowHeight
        static let blockNameWidth: CGFloat = 54
        static let ringDiameter: CGFloat = 58
        static let ringWidth: CGFloat = 10
        static let bottomSlack: CGFloat = 24
        static let hairline: CGFloat = 0.5
        static let styleIconSize: CGFloat = 50
        static let styleCardAspect: CGFloat = 1.25
        static let blurbWidth: CGFloat = 300
    }
}

// The pale blue wash every step of the builder sits on, fading out before the
// bottom so the ruler and the pills stay legible against the sheet. The AI
// chat sheet shares it, so it is not private.
struct ExerciseProgramBackground: View {
    var fades = true

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                .init(0, 0), .init(0.8, 0), .init(1, 0),
                .init(0, 0.8), .init(0.85, 0.65), .init(1, 0.5),
                .init(0, 1), .init(0.4, 1), .init(1, 1),
            ],
            colors: [
                .defaultSkyBlue.opacity(.mediumOpacity), .defaultLighthouseBlue,
                .defaultSkyBlue.opacity(.minimalOpacity),
                .defaultLighthouseBlue, .defaultSkyBlue.opacity(.semiLowOpacity), .defaultLighthouseBlue,
                .defaultSkyBlue.opacity(.minimalOpacity), .defaultLighthouseBlue,
                .defaultSkyBlue.opacity(.veryLowOpacity),
            ]
        )
        // The mesh is already smooth; the blur softens its corner stops, and the
        // scale keeps the blur's own transparent edge off screen.
        .blur(radius: Constants.blur)
        .scaleEffect(Constants.overscan)
        .mask { fadeMask }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var fadeMask: some View {
        if fades {
            fade
        } else {
            Color.black
        }
    }

    private var fade: some View {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: Constants.fadeStart),
                .init(color: .clear, location: Constants.fadeEnd),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private enum Constants {
        static let blur: CGFloat = 20
        static let overscan: CGFloat = 1.25
        static let fadeStart: CGFloat = 0.3
        static let fadeEnd: CGFloat = 0.8
    }
}

#Preview {
    ExerciseCreateProgramSheet()
}
