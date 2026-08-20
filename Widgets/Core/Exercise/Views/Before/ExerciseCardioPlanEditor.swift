//
//  ExerciseCardioPlanEditor.swift
//  Widgets
//
//  Created by Dom Montalto on 18/8/2026.
//

import SwiftUI

// The cardio half of ExerciseCreateSessionSheet: what the run is chasing, and
// whatever the goal leaves worth adding to it.
struct ExerciseCardioPlanEditor: View {
    @Binding var plan: ExerciseCardioPlan

    var isTyping: FocusState<Bool>.Binding

    // Mirrors the interval row's own scaling so the list's height matches the rows
    // it holds.
    @ScaledMetric(relativeTo: .body) private var intervalRowHeight = ExerciseIntervalRow.Constants.rowHeight

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            section("Primary goal") {
                if plan.goal == .zone {
                    zoneCard
                } else {
                    primaryRow
                }
            }

            // Each goal carries its own follow-ups: a distance or timed run can be
            // paced and split into intervals, while a zone or calorie run only
            // needs the distance or pace it's run at.
            if plan.goal.hasSecondarySection {
                section("Optional") {
                    secondaryRow

                    if plan.hasIntervals {
                        intervalsCard
                    } else {
                        uTurnCard
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.brightSnappy, value: plan.goal)
        .onChange(of: plan.goal) { _, _ in
            if !plan.secondaryOptions.contains(plan.secondary) {
                plan.secondary = plan.secondaryOptions[0]
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

    // MARK: - Goals

    // The badge picks what the run is chasing, so the row it heads swaps with it.
    // Freerun has nothing to chase, so the row carries the badge and title alone.
    private var primaryRow: some View {
        row(badge: goalBadge, title: plan.goal.title) {
            switch plan.goal {
            case .duration:
                valueField(text: $plan.duration, placeholder: "0", unit: plan.goal.unit, keyboard: .numberPad)
            case .calorie:
                valueField(text: $plan.calories, placeholder: "0", unit: plan.goal.unit, keyboard: .numberPad)
            case .freerun:
                EmptyView()
            default:
                valueField(text: $plan.distance, placeholder: "0", unit: plan.goal.unit, keyboard: .decimalPad)
            }
        }
    }

    private var goalBadge: some View {
        Menu {
            ForEach(ExerciseCardioGoal.allCases) { option in
                Button(option.title, systemImage: option.symbol) {
                    plan.goal = option
                }
            }
        } label: {
            // The Menu owns the tap, so the badge is label only.
            badge(symbol: plan.goal.symbol, tint: plan.goal.tint)
                .allowsHitTesting(false)
        }
        .brightHaptic(.light, trigger: plan.goal)
    }

    // The optional row picks its own target the same way the primary one does,
    // from whatever the primary goal leaves worth adding.
    private var secondaryRow: some View {
        row(badge: secondaryBadge, title: secondaryTitle) {
            switch plan.secondary {
            case .pace:
                valueField(text: $plan.pace, placeholder: "0’00", unit: nil, keyboard: .numbersAndPunctuation)
            case .distance:
                valueField(text: $plan.distance, placeholder: "0", unit: plan.secondary.unit, keyboard: .decimalPad)
            case .duration:
                valueField(text: $plan.duration, placeholder: "0", unit: plan.secondary.unit, keyboard: .numberPad)
            case .zone:
                zoneMenu
            }
        }
    }

    // With nothing to choose between, the badge loses its circle so it doesn't
    // read as a menu that does nothing.
    @ViewBuilder
    private var secondaryBadge: some View {
        if plan.secondaryOptions.count > 1 {
            Menu {
                ForEach(plan.secondaryOptions) { option in
                    Button(option.title, systemImage: option.symbol) {
                        plan.secondary = option
                    }
                }
            } label: {
                // The Menu owns the tap, so the badge is label only.
                badge(symbol: plan.secondary.symbol, tint: plan.secondary.tint)
                    .allowsHitTesting(false)
            }
            .brightHaptic(.light, trigger: plan.secondary)
        } else {
            badge(symbol: plan.secondary.symbol, tint: plan.secondary.tint, isCircled: false)
        }
    }

    private var secondaryTitle: String {
        plan.secondary == .pace && plan.secondaryOptions.count == 1 ? "Target Pace" : plan.secondary.title
    }

    private var zoneMenu: some View {
        Menu {
            Picker("Zone", selection: $plan.zone) {
                ForEach(ExerciseHeartZone.allCases) { option in
                    Text(option.title.capitalized).tag(option)
                }
            }
        } label: {
            BrightText("Z\(plan.zone.rawValue)", size: .standout2, color: plan.zone.color, weight: .light)
                .contentTransition(.numericText())
        }
        .brightHaptic(.light, trigger: plan.zone)
    }

    // MARK: - Zone

    private var zoneCard: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            rowContent(badge: goalBadge, title: plan.goal.title) {
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
        .animation(.brightSnappy, value: plan.zone)
    }

    private func zoneRow(_ option: ExerciseHeartZone) -> some View {
        Button {
            plan.zone = option
        } label: {
            HStack(spacing: .spacing2x) {
                BrightStatus(status: option.title)

                BrightText(option.range, size: .body1, color: .lightTextColor, weight: .regular)

                Spacer(minLength: .spacing2x)

                BrightTick(isTicked: option == plan.zone)
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
                Toggle("", isOn: $plan.isUTurnOn)
                    .labelsHidden()
                    .tint(Color.defaultGreen)
                    .brightHaptic(.light, trigger: plan.isUTurnOn)
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
                Toggle("", isOn: $plan.isIntervalsOn)
                    .labelsHidden()
                    .tint(Color.defaultGreen)
                    .brightHaptic(.light, trigger: plan.isIntervalsOn)
            }
            .padding(.horizontal, .spacing3x)

            if plan.isIntervalsOn {
                intervalsEditor
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.vertical, .spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
        .animation(.brightSnappy, value: plan.isIntervalsOn)
    }

    // The rows run edge to edge inside the card, the way set rows do in a strength
    // card, with the plus in the corner adding another leg.
    private var intervalsEditor: some View {
        VStack(spacing: .spacing3x) {
            intervalsList

            addIntervalButton
                .padding(.horizontal, .spacing3x)
        }
    }

    // A List so each leg swipes away, the same way a set does in a strength card.
    private var intervalsList: some View {
        List {
            ForEach(Array(plan.intervals.enumerated()), id: \.element.id) { index, interval in
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
        .frame(height: intervalRowHeight * CGFloat(plan.intervals.count))
        .animation(.brightSnappy, value: plan.intervals.count)
    }

    private func intervalRow(at index: Int) -> some View {
        ExerciseIntervalRow(
            phase: plan.intervals[index].phase,
            isTinted: index.isMultiple(of: 2),
            value: $plan.intervals[index].value,
            isTyping: isTyping,
            onPickPhase: { phase in
                withAnimation(.brightSnappy) { plan.intervals[index].phase = phase }
            }
        )
    }

    private func remove(_ interval: ExerciseCardioInterval) {
        withAnimation(.brightSnappy) { plan.intervals.removeAll { $0.id == interval.id } }
    }

    private var addIntervalButton: some View {
        BrightRoundButton(systemImage: "plus") {
            withAnimation(.brightSnappy) {
                plan.intervals.append(ExerciseCardioInterval(phase: .run, value: "1000"))
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

            BrightText(title, size: .body1, color: .semiLightTextColor, weight: .regular)

            Spacer(minLength: .spacing2x)

            trailing()
        }
    }

    @ViewBuilder
    private func badge(symbol: String, tint: Color, isCircled: Bool = true) -> some View {
        let glyph = Image(systemName: symbol)
            .font(.standard(size: .subheading2, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: Constants.badgeSize, height: Constants.badgeSize)

        if isCircled {
            glyph.modifier(GlassEffect(shape: .circle))
        } else {
            glyph
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
                .focused(isTyping)
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

    private enum Constants {
        static let rowHeight: CGFloat = 62
        static let badgeSize: CGFloat = 30
        static let zoneRowHeight: CGFloat = 48
    }
}

// Deliberately its own row rather than a shared one: the live cardio screen shows
// intervals its own way, so the two can drift without fighting each other.
struct ExerciseIntervalRow: View {
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

            BrightText(phase.title, size: .body1, color: .semiLightTextColor, weight: .regular)

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
            .foregroundStyle(Color.textColor)
            .frame(width: badgeSize, height: badgeSize)
            .modifier(GlassEffect(shape: .circle))
    }

    // The unit sits in the same capsule as the number, so the pair reads as one
    // value the way "500 M" does. The capsule is a fixed width so every row's
    // pill is the same size whatever it holds.
    private var field: some View {
        HStack(spacing: .spacing1x) {
            TextField("0", text: $value)
                .focused(isTyping)
                .font(.standard(size: .body1, weight: .regular))
                .foregroundStyle(Color.textColor)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity)

            BrightText(Constants.unit, size: .body1, weight: .regular)
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

private struct ExerciseCardioPlanEditorPreview: View {
    @State private var plan = ExerciseCardioPlan()

    @FocusState private var isTyping: Bool

    var body: some View {
        ScrollView {
            ExerciseCardioPlanEditor(plan: $plan, isTyping: $isTyping)
                .padding(.spacing3x)
        }
        .background(Color.defaultSheetBackground.ignoresSafeArea())
    }
}

#Preview {
    ExerciseCardioPlanEditorPreview()
}
