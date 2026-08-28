//
//  ExerciseCreateProgramSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 21/8/2026.
//

import SwiftUI

enum ExerciseProgramRoute: Hashable {
    case sessions(creates: Bool)
}

nonisolated struct ExerciseTrainingBlock: Identifiable, Equatable {
    let id: UUID
    var name: String
    // Unset until the block is given a length, which is what the periods screen
    // shows as a dashed total.
    var weeks: Int?

    init(id: UUID = UUID(), name: String, weeks: Int? = nil) {
        self.id = id
        self.name = name
        self.weeks = weeks
    }
}

nonisolated struct ExerciseTrainingPeriod: Identifiable, Equatable {
    let id: UUID
    var name: String
    var blocks: [ExerciseTrainingBlock]

    init(id: UUID = UUID(), name: String = "", blocks: [ExerciseTrainingBlock]) {
        self.id = id
        self.name = name
        self.blocks = blocks
    }

    static var empty: Self {
        ExerciseTrainingPeriod(blocks: [ExerciseTrainingBlock(name: "Block 1")])
    }

    var totalWeeks: Int {
        blocks.compactMap(\.weeks).reduce(0, +)
    }
}

// Builds a program in one sheet: an intro, a guided-or-custom fork, the template
// style and — when the template periodises — how many weeks it runs and the
// training periods it splits into, before pushing a block's week to the planner.
struct ExerciseCreateProgramSheet: View {
    @Environment(\.dismiss) private var dismiss

    @FocusState private var isTyping: Bool

    @State private var step = Step.intro

    @State private var stylePage: Int? = ProgramStyle.guided.rawValue

    @State private var sportIndex = 0

    @State private var name = ""

    @State private var template: Template?

    @State private var weeks = Constants.defaultWeeks

    @State private var nameNudge = 0

    @State private var periods = [ExerciseTrainingPeriod.empty]

    @State private var path = NavigationPath()

    @State private var insertionEdge = Edge.trailing

    var body: some View {
        BrightPageSheetView(
            horizontalPadding: .spacing0x,
            // The first step has nothing to go back to, so it closes instead.
            showBackButton: step != .intro,
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
        case let .sessions(creates):
            ExerciseAddSessionsSheet(
                isCreating: creates,
                startsEmpty: chosenStyle == .custom,
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
                .padding(.bottom, .spacing2x)

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
                    }
                }
                .padding(.horizontal, .spacing3x)
                .padding(.vertical, .spacing3x)
            }
            .safeAreaInset(edge: .bottom) {
                addPeriodButton(scroller)
            }
            .animation(.brightSnappy, value: periods)
        }
    }

    private func addPeriodButton(_ scroller: ScrollViewProxy) -> some View {
        BrightRoundButton(systemImage: "plus", size: .finalBossLarge) {
            let period = ExerciseTrainingPeriod.empty
            withAnimation(.brightSnappy) {
                periods.append(period)
                scroller.scrollTo(period.id, anchor: .bottom)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.spacing3x)
    }

    private func periodCard(_ period: Binding<ExerciseTrainingPeriod>) -> some View {
        VStack(spacing: .spacing2x) {
            periodHeader(period)

            blockList(period)

            totalRow(period)
        }
        .padding(.spacing3x)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    // A `List` rather than a plain stack so the rows take `swipeActions`; it
    // can't scroll inside the screen's scroll view, so it states its own
    // height — same shape as the create-session sets list.
    private func blockList(_ period: Binding<ExerciseTrainingPeriod>) -> some View {
        let count = period.wrappedValue.blocks.count

        return List {
            ForEach(period.blocks) { $block in
                blockRow($block)
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
            Image(systemName: Template.periodise.symbol)
                .font(.system(size: Constants.promptIconSize, weight: .light))
                .foregroundStyle(Color.defaultBrightGreen)

            TextField("Training period name", text: period.name)
                .font(.standard(size: .subheading, weight: .light))
                .foregroundStyle(Color.textColor)

            Menu {
                Button("Add block", systemImage: "plus") {
                    addBlock(to: period)
                }

                Divider()

                Button("Remove period", systemImage: "trash", role: .destructive) {
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

    private func blockRow(_ block: Binding<ExerciseTrainingBlock>) -> some View {
        Button {
            path.append(ExerciseProgramRoute.sessions(creates: false))
        } label: {
            HStack(spacing: .spacing2x) {
                BrightText(block.wrappedValue.name, size: .body1)
                    .monospacedDigit()

                Spacer(minLength: .spacing0x)

                if let weeks = block.wrappedValue.weeks {
                    BrightText(weeksLabel(weeks), size: .body1, color: .lightTextColor)
                        .monospacedDigit()
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: FontSizes.body1.rawValue, weight: .medium))
                    .foregroundStyle(Color.lightTextColor)
            }
            .padding(.horizontal, .spacing2x)
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

    private func removeBlock(_ block: ExerciseTrainingBlock, from period: Binding<ExerciseTrainingPeriod>) {
        withAnimation(.brightSnappy) {
            period.wrappedValue.blocks.removeAll { $0.id == block.id }
        }
    }

    private func totalRow(_ period: Binding<ExerciseTrainingPeriod>) -> some View {
        let total = period.wrappedValue.totalWeeks

        return HStack(spacing: .spacing105x) {
            Image(systemName: "sum")
                .font(.system(size: Constants.promptIconSize, weight: .light))
                .foregroundStyle(Color.defaultSkyBlue)

            BrightText("Total:", size: .body1)

            BrightText(total == 0 ? "– weeks" : weeksLabel(total), size: .body1, color: .lightTextColor)
                .monospacedDigit()

            Spacer(minLength: .spacing0x)

            BrightRoundButton(systemImage: "plus") {
                addBlock(to: period)
            }
        }
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
        let next = period.wrappedValue.blocks.count + 1
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

    private var chosenStyle: ProgramStyle {
        ProgramStyle(rawValue: stylePage ?? 0) ?? .guided
    }

    // The blocks screen keeps its action in the toolbar, and the length step
    // offers its skip there; every other step advances from the full-width
    // button at the foot.
    private var trailingTitle: String? {
        switch step {
        case .weeks: "Skip"
        case .periods: "Create"
        default: nil
        }
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
        static let sportSwapEvery: TimeInterval = 3

        static let guidedName = "My Program"

        static var guidedPeriods: [ExerciseTrainingPeriod] {
            [
                ExerciseTrainingPeriod(name: "Foundation", blocks: [
                    ExerciseTrainingBlock(name: "Block 1", weeks: 4),
                    ExerciseTrainingBlock(name: "Block 2", weeks: 4),
                ]),
                ExerciseTrainingPeriod(name: "Build", blocks: [
                    ExerciseTrainingBlock(name: "Block 3", weeks: 3),
                    ExerciseTrainingBlock(name: "Block 4", weeks: 3),
                ]),
                ExerciseTrainingPeriod(name: "Peak", blocks: [
                    ExerciseTrainingBlock(name: "Block 5", weeks: 2),
                ]),
            ]
        }
        static let heroIconSize: CGFloat = 34
        static let promptIconSize: CGFloat = 22
        // Tall enough for a major tick, the label gap and a full body1 label,
        // so the ruler's edge-fade mask never clips the numbers.
        static let rulerHeight: CGFloat = 60
        static let blockRowHeight = ExerciseSetRow.Constants.rowHeight
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
