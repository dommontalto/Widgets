//
//  WaypointView.swift
//  Widgets
//
//  Created by Dom Montalto on 23/9/2026.
//

import SwiftUI

struct WaypointView: View {
    var onCheckIn: () -> Void = {}

    @State private var state = WaypointState.hasAdjustments
    @State private var bearing = WaypointBearing.north
    @State private var bounce = WaypointBounce()
    @State private var shownGroup: WaypointAdjustmentGroup?

    var body: some View {
        ZStack(alignment: .top) {
            if state == .noCheckInYet {
                emptyState
                    .transition(.opacity)
            } else {
                content
                    .transition(.opacity)
            }
        }
        .animation(.brightEaseInOut, value: state)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, .spacing3x)
        .padding(.top, .spacing4x)
        .padding(.bottom, .spacing12x)
        .overlay(alignment: .topTrailing) { statePicker }
        .sheet(item: $shownGroup) { group in
            WaypointAdjustmentGroupSheet(group: group)
                .presentationDetents([.large])
        }
    }

    // MARK: - No check-in yet

    private var emptyState: some View {
        VStack(spacing: .spacing3x) {
            WaypointGauge(bearing: .north, bounce: bounce, isActive: false)

            BrightText("Create a goal to activate Waypoint", size: .body1)
                .multilineTextAlignment(.center)

            BrightPillButton(
                "Start",
                systemImage: "arrow.right",
                color: .defaultGreen.opacity(.minimalOpacity),
                textColor: .defaultGreen,
                buttonSize: .large,
                onTapCallback: checkIn
            )
        }
        .padding(.top, .spacing12x)
    }

    // MARK: - Checked in

    private var content: some View {
        VStack(alignment: .leading, spacing: .spacing5x) {
            header
                .frame(maxWidth: .infinity)

            summary

            BrightPillButton("View Check-in", systemImage: "doc.text.magnifyingglass", onTapCallback: checkIn)
                .frame(maxWidth: .infinity)

            adjustments
        }
    }

    private var header: some View {
        VStack(spacing: .spacing2x) {
            VStack(spacing: .spacing05x) {
                BrightText("Road to 20KM Program", size: .heading)

                BrightText("Last Check-in: 3 weeks ago", size: .body1, color: .lightTextColor)
            }
            .multilineTextAlignment(.center)

            HStack(spacing: .spacing0x) {
                BrightRoundButton(systemImage: "chevron.left") {
                    step(by: -1)
                }

                Spacer(minLength: .spacing0x)

                WaypointGauge(bearing: bearing, bounce: bounce)

                Spacer(minLength: .spacing0x)

                BrightRoundButton(systemImage: "chevron.right") {
                    step(by: 1)
                }
            }
            .padding(.top, .spacing5x)

            VStack(spacing: .spacing1x) {
                BrightText(bearing.status, size: .body1, color: bearing.color, weight: .regular)
                    .contentTransition(.opacity)

                HStack(spacing: .spacing05x) {
                    Image(systemName: "arrow.right")
                        .font(.standardSFPro(size: .body1, weight: .regular))

                    BrightText("Next check-in: Mon, 2 Oct", size: .body1, color: .lightTextColor)
                }
                .foregroundStyle(Color.lightTextColor)
            }

            BrightPillButton("Check In", systemImage: "person.badge.clock", buttonSize: .large, onTapCallback: checkIn)
                .padding(.top, .spacing1x)
        }
        .animation(.brightEaseInOut, value: bearing)
        .brightHaptic(.light, trigger: bearing)
        .brightHaptic(.impact, trigger: bounce.tick)
    }

    private func step(by offset: Int) {
        let cases = WaypointBearing.allCases
        let index = (cases.firstIndex(of: bearing) ?? 0) + offset
        guard cases.indices.contains(index) else {
            bounce = WaypointBounce(tick: bounce.tick + 1, direction: Double(offset.signum()))
            return
        }
        bearing = cases[index]
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                sectionTitle("sparkles", "Summary")

                Button(action: checkIn) {
                    BrightText("Your last check-in", size: .body1, color: .defaultCyan)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            BrightText(state.summary, size: .body1, color: .semiLightTextColor)
                .lineSpacing(.lineSpacingMedium)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var adjustments: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            sectionTitle("arrow.up.arrow.down", "Adjustments")

            if state == .hasAdjustments {
                VStack(spacing: .spacing2x) {
                    ForEach(WaypointAdjustmentGroup.demo) { group in
                        groupRow(group)
                    }
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
                    Image(systemName: "face.smiling")
                        .font(.standardSFPro(size: .body1, weight: .regular))
                        .foregroundStyle(Color.defaultGreen)

                    BrightText("No adjustments to be made this week. You are on track with your goals.", size: .body1, color: .semiLightTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func sectionTitle(_ symbol: String, _ title: String) -> some View {
        HStack(spacing: .spacing1x) {
            Image(systemName: symbol)
                .font(.standardSFPro(size: .subheading, weight: .regular))
                .foregroundStyle(Color.textColor)

            BrightText(title, size: .subheading, weight: .regular)
        }
    }

    private func groupRow(_ group: WaypointAdjustmentGroup) -> some View {
        Button {
            shownGroup = group
        } label: {
            HStack(spacing: .spacing105x) {
                Image(systemName: group.symbol)
                    .font(.standardSFPro(size: .subheading2, weight: .regular))
                    .foregroundStyle(group.color)
                    .frame(width: Constants.titleIconSize, height: Constants.titleIconSize)

                BrightText(group.title, size: .body1)

                Spacer(minLength: .spacing2x)

                BrightText("\(group.adjustments.count)", size: .body1)
                    .frame(width: Constants.countSize, height: Constants.countSize)
                    .background(Color.defaultBackground, in: Circle())

                BrightText("changes", size: .body1, color: .semiLightTextColor)

                Image(systemName: "chevron.right")
                    .font(.standardSFPro(size: .body1, weight: .regular))
                    .foregroundStyle(Color.semiLightTextColor)
            }
            .padding(.horizontal, .spacing2x)
            .frame(height: Constants.rowHeight)
            .modifier(CardModifier(cornerRadius: .cornerRadius24))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Debug

    private var statePicker: some View {
        Menu {
            Section("State") {
                ForEach(WaypointState.allCases) { option in
                    Button {
                        state = option
                    } label: {
                        Label {
                            Text(option.title)
                        } icon: {
                            if option == state {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: option.symbol)
                            }
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "ladybug.fill")
                .padding(.spacing2x)
        }
        .padding(.trailing, .spacing1x)
    }

    private func checkIn() {
        onCheckIn()
    }

    private enum Constants {
        static let countSize: CGFloat = 25
        static let titleIconSize: CGFloat = .spacing4x
        static let rowHeight: CGFloat = .spacing11x
    }
}

private enum WaypointState: CaseIterable, Identifiable {
    case noCheckInYet
    case noAdjustments
    case hasAdjustments

    var id: Self { self }

    var title: String {
        switch self {
        case .noCheckInYet: "No check-in yet"
        case .noAdjustments: "No adjustments"
        case .hasAdjustments: "Has adjustments"
        }
    }

    var symbol: String {
        switch self {
        case .noCheckInYet: "circle.dashed"
        case .noAdjustments: "checkmark.circle"
        case .hasAdjustments: "arrow.up.arrow.down.circle"
        }
    }

    var summary: String {
        switch self {
        case .noCheckInYet, .noAdjustments:
            "Your program is on track. You are ready to move up in weight in your strength sessions and increase your distance in your runs by 1KM."
        case .hasAdjustments:
            "Your program is off course based off your intake & nutrition, sleep and exercise data. Lighthouse has provided suggestions below on how to bring your goal back on course."
        }
    }
}

// MARK: - Models

private enum WaypointTrend {
    case up
    case down
    case steady

    var symbol: String? {
        switch self {
        case .up: "arrow.up"
        case .down: "arrow.down"
        case .steady: nil
        }
    }

    var color: Color {
        switch self {
        case .up: .defaultGreen
        case .down: .defaultYellow
        case .steady: .textColor
        }
    }
}

private struct WaypointActivity: Identifiable {
    let id: String
    let systemImage: String
    let color: Color

    static let strength = WaypointActivity(id: "strength", systemImage: "figure.strengthtraining.traditional", color: .defaultPink)
    static let run = WaypointActivity(id: "run", systemImage: "figure.run", color: .defaultSkyBlue)
    static let cycle = WaypointActivity(id: "cycle", systemImage: "figure.outdoor.cycle", color: .defaultSkyBlue)
    static let yoga = WaypointActivity(id: "yoga", systemImage: "figure.yoga", color: .defaultPink)
}

private struct WaypointMeal: Identifiable {
    let id: String
    let slot: String
    let name: String
    let systemImage: String
    let color: Color
    let protein: Int
}

// One piece of what Lighthouse looked at: a session's sets, a week of nights,
// a few days of meals, each row marked against where it should have landed.
private struct WaypointEvidence: Identifiable {
    enum Marker {
        case symbol(String, Color)
        case index(Int)
    }

    struct Row: Identifiable {
        let id = UUID()
        let marker: Marker
        let value: String
        let tag: String
        let tagColor: Color
        let passed: Bool?
    }

    let id = UUID()
    let title: String
    let date: String
    let source: String
    var sourceSymbol = "arrow.uturn.backward"
    let rows: [Row]
    let note: String
}

private struct WaypointAdjustment: Identifiable, Hashable {
    enum Detail {
        case activities([WaypointActivity])
        case meals([WaypointMeal])
        case value(String, unit: String)
    }

    let id: String
    let title: String
    let detail: Detail
    let label: String
    let trend: WaypointTrend
    let reason: String
    let evidence: [[WaypointEvidence]]

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

private struct WaypointAdjustmentGroup: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let color: Color
    let adjustments: [WaypointAdjustment]
}

// MARK: - Group sheet

private struct WaypointAdjustmentGroupSheet: View {
    let group: WaypointAdjustmentGroup

    @State private var shownAdjustment: WaypointAdjustment?

    var body: some View {
        BrightPageSheetView(horizontalPadding: .spacing0x) {
            BrightPageView(title: "\(group.title) Adjustments", backgroundColor: .defaultSheetBackground) {
                VStack(spacing: .spacing2x) {
                    ForEach(group.adjustments) { adjustment in
                        Button {
                            shownAdjustment = adjustment
                        } label: {
                            card(adjustment)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, .spacing4x)
            }
            .navigationDestination(item: $shownAdjustment) { adjustment in
                WaypointAdjustmentDetailView(adjustment: adjustment)
            }
        }
    }

    private func card(_ adjustment: WaypointAdjustment) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
                BrightText(adjustment.title, size: .body1, color: .semiLightTextColor)

                Spacer(minLength: .spacing2x)

                HStack(spacing: .spacing05x) {
                    BrightText(adjustment.label, size: .body1, color: adjustment.trend.color)

                    if let symbol = adjustment.trend.symbol {
                        Image(systemName: symbol)
                            .font(.standardSFPro(size: .body1, weight: .regular))
                    }
                }
                .foregroundStyle(adjustment.trend.color)
            }

            switch adjustment.detail {
            case let .activities(activities):
                HStack(spacing: -.spacing105x) {
                    ForEach(activities) { activity in
                        activityIcon(activity)
                    }
                }
            case let .meals(meals):
                VStack(alignment: .leading, spacing: .spacing105x) {
                    ForEach(meals) { meal in
                        mealRow(meal)
                    }
                }
            case let .value(value, unit):
                HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                    BrightText(value, size: .huge3)

                    BrightText(unit, size: .body1, color: .lightTextColor)
                }
            }
        }
        .padding(.horizontal, .spacing3x)
        .padding(.vertical, .spacing2x + .spacing05x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
        .contentShape(Rectangle())
    }

    private func mealRow(_ meal: WaypointMeal) -> some View {
        HStack(spacing: .spacing105x) {
            Image(systemName: meal.systemImage)
                .font(.standardSFPro(size: .body1, weight: .regular))
                .foregroundStyle(meal.color)
                .frame(width: Constants.mealIconSize, height: Constants.mealIconSize)
                .background(meal.color.opacity(.veryLowOpacity), in: Circle())

            VStack(alignment: .leading, spacing: .spacing0x) {
                BrightText(meal.slot, size: .body1, color: .lightTextColor)

                BrightText(meal.name, size: .body1)
                    .lineLimit(1)
            }

            Spacer(minLength: .spacing1x)

            BrightText("\(meal.protein)g", size: .body1, color: .semiLightTextColor)
        }
    }

    private func activityIcon(_ activity: WaypointActivity) -> some View {
        Image(systemName: activity.systemImage)
            .font(.standardSFPro(size: .subheading, weight: .light))
            .foregroundStyle(activity.color)
            .frame(width: Constants.activitySize, height: Constants.activitySize)
            .background(activity.color.opacity(.veryLowOpacity), in: Circle())
            .background(Color.defaultSheetModalCards, in: Circle())
            .overlay(Circle().strokeBorder(Color.defaultSheetModalCards, lineWidth: Constants.activityBorder))
    }

    private enum Constants {
        static let activitySize: CGFloat = 36
        static let activityBorder: CGFloat = 3
        static let mealIconSize: CGFloat = 32
    }
}

// MARK: - Detail

private struct WaypointAdjustmentDetailView: View {
    let adjustment: WaypointAdjustment

    var body: some View {
        BrightPageView(title: adjustment.title, horizontalPadding: .spacing0x, backgroundColor: .defaultSheetBackground) {
            VStack(alignment: .leading, spacing: .spacing4x) {
                VStack(alignment: .leading, spacing: .spacing105x) {
                    HStack(spacing: .spacing1x) {
                        Image(systemName: "sparkles")
                            .font(.standardSFPro(size: .subheading2, weight: .regular))
                            .foregroundStyle(Color.textColor)

                        BrightText("Why it changed", size: .body1, weight: .regular)
                    }

                    BrightText(adjustment.reason, size: .body1, color: .semiLightTextColor)
                        .lineSpacing(.lineSpacingMedium)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, .spacing3x)

                VStack(spacing: .spacing3x) {
                    ForEach(Array(adjustment.evidence.enumerated()), id: \.offset) { _, pair in
                        carousel(pair)
                    }
                }
            }
            .padding(.bottom, .spacing4x)
        }
    }

    private func carousel(_ pair: [WaypointEvidence]) -> some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: .spacing3x) {
                ForEach(pair) { evidence in
                    evidenceCard(evidence)
                        .containerRelativeFrame(.horizontal) { width, _ in
                            width - Constants.cardPeek
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, .spacing3x, for: .scrollContent)
    }

    private func evidenceCard(_ evidence: WaypointEvidence) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(evidence.title, size: .body1)

                    BrightText(evidence.date, size: .body1, color: .semiLightTextColor)
                }

                Spacer(minLength: .spacing1x)

                HStack(spacing: .spacing05x) {
                    Image(systemName: evidence.sourceSymbol)
                        .font(.standardSFPro(size: .body1, weight: .regular))

                    BrightText(evidence.source, size: .body1, color: .semiLightTextColor)
                }
                .foregroundStyle(Color.semiLightTextColor)
            }

            VStack(spacing: .spacing0x) {
                ForEach(Array(evidence.rows.enumerated()), id: \.element.id) { index, row in
                    evidenceRow(row, isLast: index == evidence.rows.count - 1)
                }
            }

            BrightText(evidence.note, size: .body1, color: .semiLightTextColor)
                .lineSpacing(.lineSpacingMedium)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.spacing3x)
        .frame(maxHeight: .infinity, alignment: .top)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    private func evidenceRow(_ row: WaypointEvidence.Row, isLast: Bool) -> some View {
        VStack(spacing: .spacing0x) {
            evidenceRowContent(row)

            if !isLast {
                BrightDivider()
            }
        }
    }

    private func evidenceRowContent(_ row: WaypointEvidence.Row) -> some View {
        HStack(spacing: .spacing105x) {
            marker(row.marker)

            BrightText(row.value, size: .body1)
                .lineLimit(1)

            Spacer(minLength: .spacing1x)

            BrightText(row.tag, size: .body1, color: row.tagColor)
                .padding(.horizontal, .spacing1x)
                .frame(height: Constants.tagHeight)
                .overlay(Capsule().strokeBorder(row.tagColor.opacity(.mediumOpacity), lineWidth: Constants.tagStroke))

            if let passed = row.passed {
                Image(systemName: passed ? "checkmark.circle" : "xmark.circle")
                    .font(.standardSFPro(size: .subheading, weight: .regular))
                    .foregroundStyle(passed ? Color.defaultGreen : Color.defaultRed)
            }
        }
        .padding(.vertical, .spacing105x)
    }

    @ViewBuilder
    private func marker(_ marker: WaypointEvidence.Marker) -> some View {
        switch marker {
        case let .symbol(symbol, color):
            Image(systemName: symbol)
                .font(.standardSFPro(size: .body1, weight: .regular))
                .foregroundStyle(color)
                .frame(width: Constants.markerSize, height: Constants.markerSize)
                .background(color.opacity(.veryLowOpacity), in: Circle())
        case let .index(number):
            BrightText("\(number)", size: .body1)
                .frame(width: Constants.markerSize, height: Constants.markerSize)
                .background(Color.defaultBackground, in: Circle())
        }
    }

    private enum Constants {
        static let cardPeek: CGFloat = .spacing8x
        static let markerSize: CGFloat = .spacing4x
        static let tagHeight: CGFloat = .spacing4x
        static let tagStroke: CGFloat = 1
    }
}

// MARK: - Demo

private extension WaypointEvidence.Row {
    static func rpe(_ marker: WaypointEvidence.Marker, _ value: String, _ rpe: Int, passed: Bool) -> Self {
        let color: Color = switch rpe {
        case ...4: .defaultCyan
        case 5 ... 6: .defaultPink
        case 7 ... 8: .defaultOrange
        default: .defaultRed
        }
        return Self(marker: marker, value: value, tag: "RPE \(rpe)", tagColor: color, passed: passed)
    }
}

private extension WaypointAdjustmentGroup {
    static let warmup = WaypointEvidence.Marker.symbol("figure.cooldown", .defaultGreen)

    static let demo: [WaypointAdjustmentGroup] = [
        WaypointAdjustmentGroup(id: "nutrition", title: "Nutrition", symbol: "chart.pie", color: .defaultGreen, adjustments: [
            WaypointAdjustment(
                id: "protein",
                title: "Protein goal",
                detail: .value("103", unit: "G"),
                label: "Increase protein",
                trend: .up,
                reason: "Your running volume went up this week, so your muscles need a little more protein to recover. 103 g works out at 1.6 g per kilo of body weight.",
                evidence: [
                    [
                        WaypointEvidence(title: "Daily protein", date: "Mon, 21 – Sun, 27 Sep", source: "Last week", rows: [
                            WaypointEvidence.Row(marker: .index(1), value: "Mon · 96 g", tag: "Goal 93", tagColor: .defaultGreen, passed: true),
                            WaypointEvidence.Row(marker: .index(2), value: "Wed · 82 g", tag: "Goal 93", tagColor: .defaultOrange, passed: false),
                            WaypointEvidence.Row(marker: .index(3), value: "Fri · 78 g", tag: "Goal 93", tagColor: .defaultRed, passed: false),
                            WaypointEvidence.Row(marker: .index(4), value: "Sun · 99 g", tag: "Goal 93", tagColor: .defaultGreen, passed: true),
                        ], note: "You missed your protein goal on both long-run days, right when your muscles needed it most."),
                        WaypointEvidence(title: "New daily goal", date: "From Mon, 5 Oct", source: "This week", sourceSymbol: "arrow.forward", rows: [
                            WaypointEvidence.Row(marker: .symbol("sunrise", .defaultOrange), value: "Breakfast · 30 g", tag: "+21 g", tagColor: .defaultGreen, passed: nil),
                            WaypointEvidence.Row(marker: .symbol("sun.max", .defaultYellow), value: "Lunch · 35 g", tag: "+14 g", tagColor: .defaultGreen, passed: nil),
                            WaypointEvidence.Row(marker: .symbol("moon", .defaultBlue), value: "Dinner · 38 g", tag: "Same", tagColor: .lightTextColor, passed: nil),
                        ], note: "Aim for about 30 g at each meal and top up with a snack after runs."),
                    ],
                    [
                        WaypointEvidence(title: "Recovery", date: "Mon, 21 – Sun, 27 Sep", source: "Last week", rows: [
                            WaypointEvidence.Row(marker: .symbol("figure.run", .defaultSkyBlue), value: "Run volume 18 KM", tag: "+22%", tagColor: .defaultCyan, passed: nil),
                            WaypointEvidence.Row(marker: .symbol("heart", .defaultPink), value: "Recovery avg 64", tag: "−8", tagColor: .defaultOrange, passed: nil),
                        ], note: "More distance with the same protein left recovery trailing. The new goal closes that gap."),
                    ],
                ]
            ),
            WaypointAdjustment(
                id: "mealPlan",
                title: "Meal plan",
                detail: .meals([
                    WaypointMeal(id: "breakfast", slot: "Breakfast", name: "Greek yoghurt & berries", systemImage: "sunrise", color: .defaultOrange, protein: 24),
                    WaypointMeal(id: "lunch", slot: "Lunch", name: "Chicken & quinoa bowl", systemImage: "sun.max", color: .defaultYellow, protein: 42),
                    WaypointMeal(id: "dinner", slot: "Dinner", name: "Salmon, greens & rice", systemImage: "moon", color: .defaultBlue, protein: 37),
                ]),
                label: "Higher protein",
                trend: .up,
                reason: "Breakfast and lunch were light on protein, so they've been swapped for options that hit your new target without adding calories.",
                evidence: [
                    [
                        WaypointEvidence(title: "Protein by meal", date: "Average this week", source: "Last week", rows: [
                            WaypointEvidence.Row(marker: .symbol("sunrise", .defaultOrange), value: "Breakfast · 9 g", tag: "Low", tagColor: .defaultRed, passed: false),
                            WaypointEvidence.Row(marker: .symbol("sun.max", .defaultYellow), value: "Lunch · 21 g", tag: "Low", tagColor: .defaultOrange, passed: false),
                            WaypointEvidence.Row(marker: .symbol("moon", .defaultBlue), value: "Dinner · 38 g", tag: "Good", tagColor: .defaultGreen, passed: true),
                        ], note: "Most of your protein landed at dinner. Spreading it across the day helps you recover between sessions."),
                        WaypointEvidence(title: "New meals", date: "From Mon, 5 Oct", source: "This week", sourceSymbol: "arrow.forward", rows: [
                            WaypointEvidence.Row(marker: .symbol("sunrise", .defaultOrange), value: "Breakfast · 24 g", tag: "+15 g", tagColor: .defaultGreen, passed: nil),
                            WaypointEvidence.Row(marker: .symbol("sun.max", .defaultYellow), value: "Lunch · 42 g", tag: "+21 g", tagColor: .defaultGreen, passed: nil),
                            WaypointEvidence.Row(marker: .symbol("moon", .defaultBlue), value: "Dinner · 37 g", tag: "Same", tagColor: .lightTextColor, passed: nil),
                        ], note: "Two swaps lift your daily protein to 103 g without changing your calories."),
                    ],
                ]
            ),
            WaypointAdjustment(
                id: "hydration",
                title: "Hydration target",
                detail: .value("2.8", unit: "L"),
                label: "Increase water",
                trend: .up,
                reason: "Longer runs and warmer mornings mean you're losing more through sweat, so your daily water target rises to match.",
                evidence: [
                    [
                        WaypointEvidence(title: "Water intake", date: "Mon, 21 – Sun, 27 Sep", source: "Last week", rows: [
                            WaypointEvidence.Row(marker: .index(1), value: "Tue · 2.5 L", tag: "Goal 2.4", tagColor: .defaultGreen, passed: true),
                            WaypointEvidence.Row(marker: .index(2), value: "Thu · 1.9 L", tag: "Goal 2.4", tagColor: .defaultOrange, passed: false),
                            WaypointEvidence.Row(marker: .index(3), value: "Sat · 2.0 L", tag: "Goal 2.4", tagColor: .defaultOrange, passed: false),
                        ], note: "You fell short on both run days. The extra 400 ml is timed around your sessions."),
                        WaypointEvidence(title: "New water target", date: "From Mon, 5 Oct", source: "This week", sourceSymbol: "arrow.forward", rows: [
                            WaypointEvidence.Row(marker: .symbol("sunrise", .defaultOrange), value: "Morning · 1.0 L", tag: "+0.2 L", tagColor: .defaultGreen, passed: nil),
                            WaypointEvidence.Row(marker: .symbol("figure.run", .defaultSkyBlue), value: "Around runs · 0.8 L", tag: "+0.2 L", tagColor: .defaultGreen, passed: nil),
                            WaypointEvidence.Row(marker: .symbol("moon", .defaultBlue), value: "Evening · 1.0 L", tag: "Same", tagColor: .lightTextColor, passed: nil),
                        ], note: "Most of the extra water lands around your runs, when you lose the most."),
                    ],
                ]
            ),
        ]),
        WaypointAdjustmentGroup(id: "sleep", title: "Sleep", symbol: "moon.fill", color: .defaultCyan, adjustments: [
            WaypointAdjustment(
                id: "bedtime",
                title: "Bedtime",
                detail: .value("10:15", unit: "PM"),
                label: "Earlier bedtime",
                trend: .down,
                reason: "Your deep sleep has been short on nights before early runs. Heading to bed half an hour earlier gives you a full 8 hours before your 6:15 alarm.",
                evidence: [
                    [
                        WaypointEvidence(title: "Nights before runs", date: "Mon, 21 – Sun, 27 Sep", source: "Last week", rows: [
                            WaypointEvidence.Row(marker: .index(1), value: "Mon · 6 h 40 min", tag: "Deep 52m", tagColor: .defaultOrange, passed: false),
                            WaypointEvidence.Row(marker: .index(2), value: "Thu · 7 h 55 min", tag: "Deep 1h 24m", tagColor: .defaultGreen, passed: true),
                            WaypointEvidence.Row(marker: .index(3), value: "Sat · 6 h 20 min", tag: "Deep 48m", tagColor: .defaultRed, passed: false),
                        ], note: "Two of three pre-run nights came up short. An earlier start protects your deep sleep."),
                        WaypointEvidence(title: "New schedule", date: "From tonight", source: "This week", sourceSymbol: "arrow.forward", rows: [
                            WaypointEvidence.Row(marker: .symbol("moon", .defaultBlue), value: "Wind-down · 9:45 PM", tag: "−30 min", tagColor: .defaultYellow, passed: nil),
                            WaypointEvidence.Row(marker: .symbol("bed.double", .defaultCyan), value: "Bedtime · 10:15 PM", tag: "−30 min", tagColor: .defaultYellow, passed: nil),
                            WaypointEvidence.Row(marker: .symbol("sunrise", .defaultOrange), value: "Wake up · 6:15 AM", tag: "Same", tagColor: .lightTextColor, passed: nil),
                        ], note: "Same alarm, earlier start. That's a full 8 hours before every run."),
                    ],
                ]
            ),
            WaypointAdjustment(
                id: "sleepTarget",
                title: "Sleep target",
                detail: .value("8", unit: "H"),
                label: "Increase target",
                trend: .up,
                reason: "Training load is climbing towards race week, and an extra half hour of sleep is the cheapest recovery you can add.",
                evidence: [
                    [
                        WaypointEvidence(title: "Sleep duration", date: "Mon, 21 – Sun, 27 Sep", source: "Last week", rows: [
                            WaypointEvidence.Row(marker: .symbol("bed.double", .defaultCyan), value: "Average 7 h 12 min", tag: "Goal 7.5 h", tagColor: .defaultOrange, passed: false),
                            WaypointEvidence.Row(marker: .symbol("heart", .defaultPink), value: "HRV avg 58 ms", tag: "−6", tagColor: .defaultOrange, passed: nil),
                        ], note: "Your HRV has dipped as training ramps up. More sleep is the quickest way to bring it back."),
                        WaypointEvidence(title: "New target", date: "From tonight", source: "This week", sourceSymbol: "arrow.forward", rows: [
                            WaypointEvidence.Row(marker: .symbol("bed.double", .defaultCyan), value: "Sleep · 8 h", tag: "+30 min", tagColor: .defaultGreen, passed: nil),
                            WaypointEvidence.Row(marker: .symbol("heart", .defaultPink), value: "HRV goal · 64 ms", tag: "+6", tagColor: .defaultGreen, passed: nil),
                        ], note: "An extra half hour a night should bring your HRV back up within a fortnight."),
                    ],
                ]
            ),
        ]),
        WaypointAdjustmentGroup(id: "exercise", title: "Exercise", symbol: "figure.walk", color: .defaultPink, adjustments: [
            WaypointAdjustment(
                id: "session1",
                title: "S&C session 1",
                detail: .activities([.strength, .run]),
                label: "Increase intensity",
                trend: .up,
                reason: "Your program is off course based off your intake & nutrition, sleep and exercise data. Lighthouse has provided suggestions below on how to bring your goal back on course.",
                evidence: [
                    [
                        WaypointEvidence(title: "Bench Press", date: "Mon, 28 Sep 2026", source: "Prev. session", rows: [
                            .rpe(warmup, "40 kg x 5", 4, passed: true),
                            .rpe(.index(1), "70 kg x 5", 6, passed: true),
                            .rpe(.index(2), "85 kg x 5", 7, passed: true),
                            .rpe(.index(3), "85 kg x 5", 9, passed: false),
                        ], note: "Set 3 failed at RPE 9. This indicates that we are progressively overloading too fast."),
                        WaypointEvidence(title: "Bench Press", date: "Mon, 5 Oct 2026", source: "Next session", sourceSymbol: "arrow.forward", rows: [
                            WaypointEvidence.Row(marker: warmup, value: "40 kg x 5", tag: "Same", tagColor: .lightTextColor, passed: nil),
                            WaypointEvidence.Row(marker: .index(1), value: "72.5 kg x 5", tag: "+2.5 kg", tagColor: .defaultGreen, passed: nil),
                            WaypointEvidence.Row(marker: .index(2), value: "85 kg x 5", tag: "Same", tagColor: .lightTextColor, passed: nil),
                            WaypointEvidence.Row(marker: .index(3), value: "85 kg x 4", tag: "−1 rep", tagColor: .defaultYellow, passed: nil),
                        ], note: "A little heavier up front and one less rep on the last set, so you finish strong."),
                    ],
                    [
                        WaypointEvidence(title: "Back Squat", date: "Mon, 28 Sep 2026", source: "Prev. session", rows: [
                            .rpe(warmup, "60 kg x 5", 3, passed: true),
                            .rpe(.index(1), "90 kg x 5", 5, passed: true),
                            .rpe(.index(2), "100 kg x 5", 6, passed: true),
                            .rpe(.index(3), "100 kg x 5", 7, passed: true),
                        ], note: "We've seen easy reps from your squats, so there's room to add weight next session."),
                        WaypointEvidence(title: "Back Squat", date: "Mon, 5 Oct 2026", source: "Next session", sourceSymbol: "arrow.forward", rows: [
                            WaypointEvidence.Row(marker: warmup, value: "60 kg x 5", tag: "Same", tagColor: .lightTextColor, passed: nil),
                            WaypointEvidence.Row(marker: .index(1), value: "92.5 kg x 5", tag: "+2.5 kg", tagColor: .defaultGreen, passed: nil),
                            WaypointEvidence.Row(marker: .index(2), value: "102.5 kg x 5", tag: "+2.5 kg", tagColor: .defaultGreen, passed: nil),
                            WaypointEvidence.Row(marker: .index(3), value: "102.5 kg x 5", tag: "+2.5 kg", tagColor: .defaultGreen, passed: nil),
                        ], note: "Easy reps last time, so every working set goes up 2.5 kg."),
                    ],
                    [
                        WaypointEvidence(title: "Bent-over Row", date: "Mon, 28 Sep 2026", source: "Prev. session", rows: [
                            .rpe(warmup, "30 kg x 8", 3, passed: true),
                            .rpe(.index(1), "50 kg x 8", 5, passed: true),
                            .rpe(.index(2), "55 kg x 8", 6, passed: true),
                            .rpe(.index(3), "55 kg x 8", 7, passed: true),
                        ], note: "Solid reps across the board with room left in the tank."),
                        WaypointEvidence(title: "Bent-over Row", date: "Mon, 5 Oct 2026", source: "Next session", sourceSymbol: "arrow.forward", rows: [
                            WaypointEvidence.Row(marker: warmup, value: "30 kg x 8", tag: "Same", tagColor: .lightTextColor, passed: nil),
                            WaypointEvidence.Row(marker: .index(1), value: "52.5 kg x 8", tag: "+2.5 kg", tagColor: .defaultGreen, passed: nil),
                            WaypointEvidence.Row(marker: .index(2), value: "57.5 kg x 8", tag: "+2.5 kg", tagColor: .defaultGreen, passed: nil),
                            WaypointEvidence.Row(marker: .index(3), value: "57.5 kg x 8", tag: "+2.5 kg", tagColor: .defaultGreen, passed: nil),
                        ], note: "A small bump on each working set keeps your pulling in step with your pressing."),
                    ],
                ]
            ),
            WaypointAdjustment(
                id: "cycle",
                title: "Endurance Cycle",
                detail: .activities([.cycle]),
                label: "Decrease intensity",
                trend: .down,
                reason: "Your recovery dipped below 60 on two mornings this week, so the long ride comes down a notch to keep your legs fresh for Sunday's run.",
                evidence: [
                    [
                        WaypointEvidence(title: "Long ride", date: "Sat, 26 Sep 2026", source: "Prev. session", rows: [
                            .rpe(.index(1), "0 – 10 KM", 5, passed: true),
                            .rpe(.index(2), "10 – 20 KM", 7, passed: true),
                            .rpe(.index(3), "20 – 30 KM", 9, passed: false),
                        ], note: "The last third of the ride pushed you to RPE 9, so the distance drops to 25 KM."),
                        WaypointEvidence(title: "Long ride", date: "Sat, 3 Oct 2026", source: "Next session", sourceSymbol: "arrow.forward", rows: [
                            WaypointEvidence.Row(marker: .index(1), value: "0 – 10 KM", tag: "Zone 2", tagColor: .defaultCyan, passed: nil),
                            WaypointEvidence.Row(marker: .index(2), value: "10 – 20 KM", tag: "Zone 2", tagColor: .defaultCyan, passed: nil),
                            WaypointEvidence.Row(marker: .index(3), value: "20 – 25 KM", tag: "−5 KM", tagColor: .defaultYellow, passed: nil),
                        ], note: "25 KM held in zone 2 the whole way keeps your legs fresh for Sunday."),
                    ],
                ]
            ),
            WaypointAdjustment(
                id: "session2",
                title: "S&C session 2",
                detail: .activities([.strength, .run]),
                label: "Increase intensity",
                trend: .up,
                reason: "Your squat reps stayed smooth at the top of your range last week, so an extra set builds the leg strength longer runs lean on.",
                evidence: [
                    [
                        WaypointEvidence(title: "Deadlift", date: "Thu, 24 Sep 2026", source: "Prev. session", rows: [
                            .rpe(warmup, "60 kg x 5", 3, passed: true),
                            .rpe(.index(1), "100 kg x 5", 5, passed: true),
                            .rpe(.index(2), "110 kg x 5", 6, passed: true),
                        ], note: "Every set finished with reps in reserve. A third working set adds volume safely."),
                        WaypointEvidence(title: "Deadlift", date: "Thu, 1 Oct 2026", source: "Next session", sourceSymbol: "arrow.forward", rows: [
                            WaypointEvidence.Row(marker: warmup, value: "60 kg x 5", tag: "Same", tagColor: .lightTextColor, passed: nil),
                            WaypointEvidence.Row(marker: .index(1), value: "100 kg x 5", tag: "Same", tagColor: .lightTextColor, passed: nil),
                            WaypointEvidence.Row(marker: .index(2), value: "110 kg x 5", tag: "Same", tagColor: .lightTextColor, passed: nil),
                            WaypointEvidence.Row(marker: .index(3), value: "110 kg x 5", tag: "New set", tagColor: .defaultGreen, passed: nil),
                        ], note: "One extra working set at the same weight builds volume without the risk."),
                    ],
                ]
            ),
            WaypointAdjustment(
                id: "yoga",
                title: "Yoga session",
                detail: .activities([.yoga]),
                label: "No change",
                trend: .steady,
                reason: "Your mobility work is doing its job. Keeping it steady gives your body one easy session between harder days.",
                evidence: [
                    [
                        WaypointEvidence(title: "Flow", date: "Wed, 23 Sep 2026", source: "Prev. session", rows: [
                            .rpe(.index(1), "30 min", 3, passed: true),
                        ], note: "An easy session that did what it should. Nothing to change."),
                        WaypointEvidence(title: "Flow", date: "Wed, 30 Sep 2026", source: "Next session", sourceSymbol: "arrow.forward", rows: [
                            WaypointEvidence.Row(marker: .index(1), value: "30 min", tag: "Same", tagColor: .lightTextColor, passed: nil),
                        ], note: "Same flow, same time. Keep it as your easy day."),
                    ],
                ]
            ),
        ]),
    ]
}

#Preview {
    ScrollView {
        WaypointView()
    }
    .background(Color.defaultBackground)
}
