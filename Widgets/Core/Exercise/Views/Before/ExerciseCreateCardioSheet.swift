//
//  ExerciseCreateCardioSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 11/8/2026.
//

import SwiftUI

// What the run is chasing. Picked from the menu on the primary row's badge, the
// way a set's kind is picked in ExerciseCreateWorkoutSheet.
enum ExerciseCardioGoal: String, CaseIterable, Identifiable {
    case distance
    case duration
    case zone
    case calorie
    case freerun

    var id: String { rawValue }

    // Named for the menu; the primary row heading uses the same text.
    var title: String {
        switch self {
        case .distance: "Distance"
        case .duration: "Duration"
        case .zone: "Zone"
        case .calorie: "Calorie"
        case .freerun: "Freerun"
        }
    }

    var symbol: String {
        switch self {
        case .distance: "lines.measurement.horizontal.aligned.bottom"
        case .duration: "stopwatch"
        case .zone: "bolt.heart.fill"
        case .calorie: "flame.fill"
        case .freerun: "figure.run"
        }
    }

    var tint: Color {
        switch self {
        case .distance: .defaultBlue
        case .duration: .defaultBrightViolet
        case .zone: .defaultRed
        case .calorie: .defaultOrange
        case .freerun: .defaultGreen
        }
    }

    var unit: String? {
        switch self {
        case .distance: "KM"
        case .duration: "MIN"
        case .calorie: "CAL"
        case .zone, .freerun: nil
        }
    }

    // Freerun is the whole plan — nothing to target and nothing to add to it.
    var hasSecondarySection: Bool {
        self != .freerun
    }
}

// The follow-up target, picked from the menu on the optional row's badge. Which
// ones are offered depends on the primary goal.
enum ExerciseCardioSecondary: String, Identifiable {
    case pace
    case distance
    case duration
    case zone

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pace: "Pace"
        case .distance: "Distance"
        case .duration: "Duration"
        case .zone: "Zone"
        }
    }

    var symbol: String {
        switch self {
        case .pace: "clock"
        case .distance: ExerciseCardioGoal.distance.symbol
        case .duration: ExerciseCardioGoal.duration.symbol
        case .zone: ExerciseCardioGoal.zone.symbol
        }
    }

    var tint: Color {
        switch self {
        case .pace: .defaultGreen
        case .distance: ExerciseCardioGoal.distance.tint
        case .duration: ExerciseCardioGoal.duration.tint
        case .zone: ExerciseCardioGoal.zone.tint
        }
    }

    var unit: String? {
        switch self {
        case .distance: "KM"
        case .duration: "MIN"
        case .pace, .zone: nil
        }
    }
}

enum ExerciseHeartZone: Int, CaseIterable, Identifiable {
    case one = 1
    case two
    case three
    case four
    case five

    var id: Int { rawValue }

    var title: String { "ZONE \(rawValue)" }

    var range: String {
        switch self {
        case .one: "<139 BPM"
        case .two: "140-152 BPM"
        case .three: "152-166 BPM"
        case .four: "166-196 BPM"
        case .five: "+196 BPM"
        }
    }

    // BrightStatus owns the zone ramp, so the tick matches its tag.
    var color: Color {
        BrightStatus(status: title).color
    }
}

enum ExerciseIntervalPhase: String, CaseIterable, Identifiable {
    case warmup
    case run
    case walk
    case cooldown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .warmup: "Warmup"
        case .run: "Run"
        case .walk: "Walk"
        case .cooldown: "Cooldown"
        }
    }

    var symbol: String {
        switch self {
        case .warmup: "figure.cooldown"
        case .run: "figure.run"
        case .walk: "figure.walk"
        case .cooldown: "snowflake"
        }
    }

    var color: Color {
        switch self {
        case .warmup: .defaultOrange
        case .run: .defaultGreen
        case .walk: .defaultBlue
        case .cooldown: .defaultCyan
        }
    }

}

struct ExerciseCardioInterval: Identifiable {
    let id = UUID()
    var phase: ExerciseIntervalPhase
    var value: String

    // Every leg is measured in metres.
    static let defaults: [ExerciseCardioInterval] = [
        ExerciseCardioInterval(phase: .warmup, value: "500"),
        ExerciseCardioInterval(phase: .run, value: "3000"),
        ExerciseCardioInterval(phase: .walk, value: "500"),
        ExerciseCardioInterval(phase: .run, value: "1000"),
        ExerciseCardioInterval(phase: .cooldown, value: "500"),
    ]
}

struct ExerciseCreateCardioSheet: View {
    // The saved workout being edited, or nil when building a new one.
    let editing: ExerciseQuickWorkout?

    let onSave: () -> Void

    @Environment(ExerciseBuilder.self) private var builder

    @FocusState private var isTyping: Bool

    @State private var name: String

    @State private var symbol: ExerciseWorkoutIcon

    @State private var goal: ExerciseCardioGoal = .distance

    @State private var secondary: ExerciseCardioSecondary = .pace

    @State private var distance = ""

    @State private var duration = ""

    @State private var calories = ""

    @State private var pace = ""

    @State private var zone: ExerciseHeartZone = .two

    @State private var isUTurnOn = false

    @State private var isIntervalsOn = false

    @State private var intervals = ExerciseCardioInterval.defaults

    @State private var nameNudge = 0

    // The plan as it looked on arrival, so Save can tell edits from a no-op.
    @State private var baselinePlan: String?

    // Mirrors the interval row's own scaling so the list's height matches the rows
    // it holds.
    @ScaledMetric(relativeTo: .body) private var intervalRowHeight = ExerciseIntervalRow.Constants.rowHeight

    // The targets aren't stored on a saved workout, so an edit restores the name
    // and icon and starts the plan fresh.
    init(editing: ExerciseQuickWorkout? = nil, onSave: @escaping () -> Void) {
        self.editing = editing
        self.onSave = onSave
        _name = State(initialValue: editing?.name ?? "")
        if let editing, let icon = ExerciseWorkoutIcon.matching(editing) {
            _symbol = State(initialValue: icon)
        } else {
            _symbol = State(initialValue: ExerciseWorkoutIcon.cardio[0])
        }
    }

    var body: some View {
        BrightPageView(
            scrollableTitle: false,
            horizontalPadding: .spacing0x,
            backgroundColor: .defaultSheetBackground,
            toolbar: {
                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(title: title, file: #file)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(saveTitle, action: save)
                        .buttonStyle(.borderedProminent)
                        .tint(canSave ? .defaultSkyBlue : .defaultMainGrey)
                        .id(canSave)
                }
            },
            content: {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: .spacing3x) {
                        header

                        goalSections
                    }
                    .padding(.spacing3x)
                    .animation(.brightSnappy, value: goal)
                }
            }
        )
        .onAppear {
            if baselinePlan == nil { baselinePlan = subtitle }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            nameField
                .padding(.top, .spacing2x)

            ExerciseIconPicker(icons: ExerciseWorkoutIcon.cardio, selection: $symbol)
        }
    }

    private var nameField: some View {
        TextField("Cardio name", text: $name)
            .focused($isTyping)
            .font(.standard(size: .standout28, weight: .regular))
            .foregroundStyle(Color.textColor)
            .brightWiggle(trigger: nameNudge)
    }

    // MARK: - Goals

    private var goalSections: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            section("Primary goal") {
                if goal == .zone {
                    zoneCard
                } else {
                    primaryRow
                }
            }

            // Each goal carries its own follow-ups: a distance or timed run can be
            // paced and split into intervals, while a zone or calorie run only
            // needs the distance or pace it's run at.
            if goal.hasSecondarySection {
                section("Optional") {
                    secondaryRow

                    if goal == .distance || goal == .duration {
                        intervalsCard
                    } else {
                        uTurnCard
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onChange(of: goal) { _, _ in
            if !secondaryOptions.contains(secondary) {
                secondary = secondaryOptions[0]
            }
        }
    }

    private func section(
        _ title: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(title, size: .body1)
                .padding(.leading, .spacing2x)

            content()
        }
    }

    // The badge picks what the run is chasing, so the row it heads swaps with it.
    // Freerun has nothing to chase, so the row carries the badge and title alone.
    private var primaryRow: some View {
        row(badge: goalBadge, title: goal.title) {
            switch goal {
            case .duration:
                valueField(text: $duration, placeholder: "0", unit: goal.unit, keyboard: .numberPad)
            case .calorie:
                valueField(text: $calories, placeholder: "0", unit: goal.unit, keyboard: .numberPad)
            case .freerun:
                EmptyView()
            default:
                valueField(text: $distance, placeholder: "0", unit: goal.unit, keyboard: .decimalPad)
            }
        }
    }

    private var goalBadge: some View {
        Menu {
            ForEach(ExerciseCardioGoal.allCases) { option in
                Button(option.title, systemImage: option.symbol) {
                    goal = option
                }
            }
        } label: {
            // The Menu owns the tap, so the badge is label only.
            badge(symbol: goal.symbol, tint: goal.tint)
                .allowsHitTesting(false)
        }
        .brightHaptic(.light, trigger: goal)
    }

    // The optional row picks its own target the same way the primary one does,
    // from whatever the primary goal leaves worth adding.
    private var secondaryRow: some View {
        row(badge: secondaryBadge, title: secondaryTitle) {
            switch secondary {
            case .pace:
                valueField(text: $pace, placeholder: "0’00", unit: nil, keyboard: .numbersAndPunctuation)
            case .distance:
                valueField(text: $distance, placeholder: "0", unit: secondary.unit, keyboard: .decimalPad)
            case .duration:
                valueField(text: $duration, placeholder: "0", unit: secondary.unit, keyboard: .numberPad)
            case .zone:
                zoneMenu
            }
        }
    }

    // With nothing to choose between, the badge loses its circle so it doesn't
    // read as a menu that does nothing.
    @ViewBuilder
    private var secondaryBadge: some View {
        if secondaryOptions.count > 1 {
            Menu {
                ForEach(secondaryOptions) { option in
                    Button(option.title, systemImage: option.symbol) {
                        secondary = option
                    }
                }
            } label: {
                // The Menu owns the tap, so the badge is label only.
                badge(symbol: secondary.symbol, tint: secondary.tint)
                    .allowsHitTesting(false)
            }
            .brightHaptic(.light, trigger: secondary)
        } else {
            badge(symbol: secondary.symbol, tint: secondary.tint, isCircled: false)
        }
    }

    // A stop condition pairs with an intensity and vice versa, so a distance or
    // timed run only takes a pace, while a zone run takes the distance or time it
    // runs for.
    private var secondaryOptions: [ExerciseCardioSecondary] {
        switch goal {
        case .zone: [.distance, .duration]
        case .calorie: [.pace, .zone]
        default: [.pace]
        }
    }

    private var secondaryTitle: String {
        secondary == .pace && secondaryOptions.count == 1 ? "Target Pace" : secondary.title
    }

    private var zoneMenu: some View {
        Menu {
            Picker("Zone", selection: $zone) {
                ForEach(ExerciseHeartZone.allCases) { option in
                    Text(option.title.capitalized).tag(option)
                }
            }
        } label: {
            BrightText("Z\(zone.rawValue)", size: .standout2, color: zone.color, weight: .light)
                .contentTransition(.numericText())
        }
        .brightHaptic(.light, trigger: zone)
    }

    // MARK: - Zone

    private var zoneCard: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            rowContent(badge: goalBadge, title: goal.title) {
                EmptyView()
            }
            .padding(.bottom, .spacing2x)

            ForEach(ExerciseHeartZone.allCases) { option in
                if option != .one {
                    BrightDivider()
                }

                zoneRow(option)
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
        // BrightTick plays its own haptic, so the card doesn't add one.
        .animation(.brightSnappy, value: zone)
    }

    private func zoneRow(_ option: ExerciseHeartZone) -> some View {
        Button {
            zone = option
        } label: {
            HStack(spacing: .spacing2x) {
                BrightStatus(status: option.title)

                BrightText(option.range, size: .body2, color: .lightTextColor, weight: .regular)

                Spacer(minLength: .spacing2x)

                BrightTick(isTicked: option == zone, tickTint: option.color)
            }
            .frame(height: Constants.zoneRowHeight)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    // MARK: - U-Turn

    private var uTurnCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            rowContent(
                badge: badge(symbol: "arrow.uturn.backward", tint: .defaultCyan, isCircled: false),
                title: "U-Turn"
            ) {
                Toggle("", isOn: $isUTurnOn)
                    .labelsHidden()
                    .tint(Color.defaultGreen)
                    .brightHaptic(.light, trigger: isUTurnOn)
            }

            BrightText(
                "Notify to turn around at half way point",
                size: .body3,
                color: .lightTextColor
            )
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    // MARK: - Intervals

    private var intervalsCard: some View {
        VStack(spacing: .spacing3x) {
            rowContent(
                badge: badge(symbol: "increase.quotelevel", tint: .defaultPurple, isCircled: false),
                title: "Intervals"
            ) {
                Toggle("", isOn: $isIntervalsOn)
                    .labelsHidden()
                    .tint(Color.defaultGreen)
                    .brightHaptic(.light, trigger: isIntervalsOn)
            }
            .padding(.horizontal, .spacing3x)

            if isIntervalsOn {
                intervalsEditor
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.vertical, .spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
        .animation(.brightSnappy, value: isIntervalsOn)
    }

    // The rows run edge to edge inside the card, the way set rows do in a workout
    // card, with the plus in the corner adding another leg.
    private var intervalsEditor: some View {
        VStack(spacing: .spacing3x) {
            intervalsList

            addIntervalButton
                .padding(.horizontal, .spacing3x)
        }
    }

    // A List so each leg swipes away, the same way a set does in a workout card.
    private var intervalsList: some View {
        List {
            ForEach(Array(intervals.enumerated()), id: \.element.id) { index, interval in
                intervalRow(at: index)
                    .listRowInsets(EdgeInsets(top: 0, leading: .spacing3x, bottom: 0, trailing: .spacing3x))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            remove(interval)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(.defaultRed)
                    }
            }
        }
        .listStyle(.plain)
        .listRowSpacing(.spacing0x)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .contentMargins(.vertical, .spacing0x, for: .scrollContent)
        .environment(\.defaultMinListRowHeight, intervalRowHeight)
        .frame(height: intervalRowHeight * CGFloat(intervals.count))
        .animation(.brightSnappy, value: intervals.count)
    }

    private func intervalRow(at index: Int) -> some View {
        ExerciseIntervalRow(
            phase: intervals[index].phase,
            isTinted: index.isMultiple(of: 2),
            value: $intervals[index].value,
            isTyping: $isTyping,
            onPickPhase: { phase in
                withAnimation(.brightSnappy) { intervals[index].phase = phase }
            }
        )
    }

    private func remove(_ interval: ExerciseCardioInterval) {
        withAnimation(.brightSnappy) { intervals.removeAll { $0.id == interval.id } }
    }

    private var addIntervalButton: some View {
        BrightRoundButton(systemImage: "plus") {
            withAnimation(.brightSnappy) {
                intervals.append(ExerciseCardioInterval(phase: .run, value: "1000"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Rows

    private func row(
        badge: some View,
        title: String,
        @ViewBuilder trailing: () -> some View
    ) -> some View {
        rowContent(badge: badge, title: title, trailing: trailing)
            .padding(.horizontal, .spacing3x)
            .frame(height: Constants.rowHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    private func rowContent(
        badge: some View,
        title: String,
        @ViewBuilder trailing: () -> some View
    ) -> some View {
        HStack(spacing: .spacing2x) {
            badge

            BrightText(title, size: .body2, color: .semiLightTextColor, weight: .regular)

            Spacer(minLength: .spacing2x)

            trailing()
        }
    }

    private func badge(symbol: String, tint: Color, isCircled: Bool = true) -> some View {
        Image(systemName: symbol)
            .font(.standard(size: .subheading2, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: Constants.badgeSize, height: Constants.badgeSize)
            .background {
                if isCircled {
                    Circle()
                        .fill(Color.defaultCapsule)
                }
            }
    }

    private func valueField(
        text: Binding<String>,
        placeholder: String,
        unit: String?,
        keyboard: UIKeyboardType
    ) -> some View {
        HStack(spacing: .spacing1x) {
            TextField(placeholder, text: text)
                .focused($isTyping)
                .font(.standard(size: .standout2, weight: .light))
                .foregroundStyle(Color.textColor)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)

            if let unit {
                BrightText(unit, size: .standout2, weight: .light)
            }
        }
        .opacity(text.wrappedValue.isEmpty ? .semiLowOpacity : .opaque)
    }

    // MARK: - Actions

    private func save() {
        guard !isNameEmpty else {
            nameNudge += 1
            return
        }
        if let editing {
            builder.update(editing, named: name, icon: symbol, subtitle: subtitle)
        } else {
            builder.save(named: name, icon: symbol, subtitle: subtitle)
        }
        onSave()
    }

    // MARK: - Derived state

    private var isNameEmpty: Bool {
        name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // Editing only offers Save once something actually differs; a new cardio
    // workout just needs a name.
    private var canSave: Bool {
        guard !isNameEmpty else { return false }
        guard let editing else { return true }
        guard let baselinePlan else { return false }
        return name != editing.name
            || symbol.symbol != editing.symbol
            || subtitle != baselinePlan
    }

    private var saveTitle: String {
        editing == nil ? "Create" : "Save"
    }

    private var title: String {
        editing == nil ? "Create Cardio" : "Edit Cardio"
    }

    // Reads back as the plan on the workout's card, e.g. "5 km • 4 intervals".
    private var subtitle: String {
        var parts: [String] = []

        switch goal {
        case .distance:
            if !distance.isEmpty { parts.append("\(distance) km") }
        case .duration:
            if !duration.isEmpty { parts.append("\(duration) min") }
        case .zone:
            parts.append("Zone \(zone.rawValue)")
        case .calorie:
            if !calories.isEmpty { parts.append("\(calories) cal") }
        case .freerun:
            parts.append("Freerun")
        }

        if goal.hasSecondarySection {
            switch secondary {
            case .pace:
                if !pace.isEmpty { parts.append(pace) }
            case .distance:
                if !distance.isEmpty, goal != .distance { parts.append("\(distance) km") }
            case .duration:
                if !duration.isEmpty, goal != .duration { parts.append("\(duration) min") }
            case .zone:
                if goal != .zone { parts.append("Zone \(zone.rawValue)") }
            }
        }

        if isIntervalsOn, goal == .distance || goal == .duration {
            parts.append("\(intervals.count) intervals")
        }

        return parts.isEmpty ? "Cardio" : parts.joined(separator: " \u{2022} ")
    }

    private enum Constants {
        static let rowHeight: CGFloat = 62
        static let badgeSize: CGFloat = 30
        static let zoneRowHeight: CGFloat = 48
    }
}

// Deliberately its own row rather than a shared one: the live cardio screen shows
// intervals its own way, so the two can drift without fighting each other.
private struct ExerciseIntervalRow: View {
    let phase: ExerciseIntervalPhase
    let isTinted: Bool
    @Binding var value: String
    var isTyping: FocusState<Bool>.Binding
    let onPickPhase: (ExerciseIntervalPhase) -> Void

    @Environment(\.colorScheme) private var colorScheme

    @ScaledMetric(relativeTo: .body) private var rowHeight = Constants.rowHeight
    @ScaledMetric(relativeTo: .body) private var badgeSize = Constants.badgeSize
    @ScaledMetric(relativeTo: .body) private var pillWidth = Constants.pillWidth

    var body: some View {
        HStack(spacing: .spacing2x) {
            Menu {
                ForEach(ExerciseIntervalPhase.allCases) { option in
                    Button(option.title, systemImage: option.symbol) {
                        onPickPhase(option)
                    }
                }
            } label: {
                // The Menu owns the tap, so the badge is label only.
                badge
                    .allowsHitTesting(false)
            }

            BrightText(phase.title, size: .body2, color: .semiLightTextColor, weight: .regular)

            Spacer(minLength: .spacing2x)

            field
        }
        .padding(.horizontal, .spacing2x)
        .frame(height: rowHeight)
        .background {
            if isTinted {
                RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous)
                    .fill(tint)
            }
        }
    }

    private var tint: Color {
        colorScheme == .dark
            ? .defaultSheetBackground.opacity(.veryLowOpacity)
            : .defaultMainGrey.opacity(.ultraLowOpacity)
    }

    private var badge: some View {
        Image(systemName: phase.symbol)
            .font(.standard(size: .body1, weight: .light))
            .foregroundStyle(phase.color)
            .frame(width: badgeSize, height: badgeSize)
            .background {
                Circle()
                    .fill(Color.defaultCapsule)
            }
    }

    // The unit sits in the same capsule as the number, so the pair reads as one
    // value the way "500 M" does. The capsule is a fixed width so every row's
    // pill is the same size whatever it holds.
    private var field: some View {
        HStack(spacing: .spacing1x) {
            TextField("0", text: $value)
                .focused(isTyping)
                .font(.standard(size: .body2, weight: .regular))
                .foregroundStyle(Color.textColor)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity)

            BrightText(Constants.unit, size: .body2, weight: .regular)
        }
        .padding(.horizontal, .spacing2x)
        .frame(width: pillWidth, height: badgeSize)
        .background(Color.defaultCapsule, in: Capsule())
    }

    enum Constants {
        static let unit = "M"
        static let rowHeight: CGFloat = 49
        static let badgeSize: CGFloat = 30
        static let pillWidth: CGFloat = 84
    }
}

#Preview {
    NavigationStack {
        ExerciseCreateCardioSheet {}
            .environment(ExerciseBuilder())
    }
}
