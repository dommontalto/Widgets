//
//  WaypointView.swift
//  Widgets
//
//  Created by Dom Montalto on 23/9/2026.
//

import SwiftUI

struct WaypointView: View {
    var onCheckIn: () -> Void = {}

    @State private var bearing = WaypointBearing.northWest
    @State private var collapsedGroups: Set<String> = []
    @State private var bounce = WaypointBounce()
    @State private var stepsBack = false
    @State private var shownAdjustment: WaypointAdjustment?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing4x) {
            header
                .frame(maxWidth: .infinity)

            adjustments
        }
        .padding(.horizontal, .spacing3x)
        .padding(.top, .spacing4x)
        .padding(.bottom, .spacing12x)
        .sheet(item: $shownAdjustment) { adjustment in
            WaypointAdjustmentSheet(adjustment: adjustment)
                .presentationDetents([.large])
        }
    }

    private var header: some View {
        VStack(spacing: .spacing2x) {
            VStack(spacing: .spacing1x) {
                BrightText("Road to 20KM Program", size: .heading)

                BrightText(bearing.subtitle, size: .body1, color: bearing.color.opacity(.lowOpacity))
                    .contentTransition(.numericText(countsDown: stepsBack))
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
            .padding(.top, .spacing7x)
            .padding(.bottom, .spacing2x)

            BrightPillButton(
                "Check In",
                systemImage: "person.badge.clock",
                color: .defaultGreen.opacity(.minimalOpacity),
                textColor: .defaultGreen,
                buttonSize: .large,
                onTapCallback: onCheckIn
            )

            BrightText("TODAY, 9 AM", size: .body1, color: .lightTextColor)
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
        stepsBack = offset < 0
        bearing = cases[index]
    }

    private var adjustments: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                HStack(spacing: .spacing1x) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.standardSFPro(size: .subheading, weight: .regular))
                        .foregroundStyle(Color.textColor)

                    BrightText("Adjustments", size: .subheading, weight: .regular)
                }

                BrightText("This week", size: .body1, color: .lightTextColor)
            }

            ForEach(WaypointAdjustmentGroup.demo) { group in
                adjustmentGroup(group)
            }
        }
    }

    private func adjustmentGroup(_ group: WaypointAdjustmentGroup) -> some View {
        let isExpanded = !collapsedGroups.contains(group.id)
        return VStack(alignment: .leading, spacing: .spacing3x) {
            Button {
                withAnimation(.brightEaseInOut) {
                    if isExpanded {
                        collapsedGroups.insert(group.id)
                    } else {
                        collapsedGroups.remove(group.id)
                    }
                }
            } label: {
                HStack(spacing: .spacing1x) {
                    Image(systemName: group.symbol)
                        .font(.standardSFPro(size: .subheading2, weight: .regular))
                        .foregroundStyle(Color.textColor)
                        .frame(width: Constants.titleIconSize, height: Constants.titleIconSize)

                    BrightText(group.title, size: .body1, weight: .regular)

                    Spacer()

                    BrightText("\(group.adjustments.count)", size: .body1)
                        .frame(width: Constants.countSize, height: Constants.countSize)
                        .background(Color.defaultCards, in: Circle())

                    BrightText("changes", size: .body1, color: .semiLightTextColor)

                    Image(systemName: "chevron.down")
                        .font(.standardSFPro(size: .body1, weight: .regular))
                        .foregroundStyle(Color.semiLightTextColor)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(group.adjustments) { adjustment in
                    adjustmentCard(adjustment)
                }
            }
        }
    }

    private func adjustmentCard(_ adjustment: WaypointAdjustment) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing1x) {
                BrightText(adjustment.title, size: .body1, color: .semiLightTextColor)

                Spacer()

                BrightRoundButton(systemImage: "arrow.down.backward.and.arrow.up.forward") {
                    shownAdjustment = adjustment
                }
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
                    BrightText(value, size: .huge2)

                    BrightText(unit, size: .body1, color: .lightTextColor)
                }
            case .none:
                EmptyView()
            }

            Spacer(minLength: .spacing0x)

            if let change = adjustment.change {
                HStack(spacing: .spacing05x) {
                    Image(systemName: "arrow.up")
                        .font(.standardSFPro(size: .body1, weight: .regular))

                    BrightText(change, size: .body1, color: .defaultGreen)
                }
                .foregroundStyle(Color.defaultGreen)
                .opacity(.mediumOpacity)
            }
        }
        .padding(.spacing2x)
        .frame(maxWidth: .infinity, minHeight: Constants.cardHeight, alignment: .topLeading)
        .modifier(CardModifier())
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
            .background(Color.defaultCards, in: Circle())
            .overlay(Circle().strokeBorder(Color.defaultCards, lineWidth: Constants.activityBorder))
    }

    private enum Constants {
        static let countSize: CGFloat = 25
        static let titleIconSize: CGFloat = .spacing4x
        static let cardHeight: CGFloat = 136
        static let activitySize: CGFloat = 36
        static let activityBorder: CGFloat = 3
        static let mealIconSize: CGFloat = 32
    }
}

private struct WaypointActivity: Identifiable {
    let id: String
    let systemImage: String
    let color: Color

    static let strength = WaypointActivity(id: "strength", systemImage: "figure.strengthtraining.traditional", color: .defaultPink)
    static let run = WaypointActivity(id: "run", systemImage: "figure.run", color: .defaultBlue)
    static let cycle = WaypointActivity(id: "cycle", systemImage: "figure.outdoor.cycle", color: .defaultBlue)
}

private struct WaypointMeal: Identifiable {
    let id: String
    let slot: String
    let name: String
    let systemImage: String
    let color: Color
    let protein: Int
}

private struct WaypointAdjustment: Identifiable {
    enum Detail {
        case activities([WaypointActivity])
        case meals([WaypointMeal])
        case value(String, unit: String)
        case none
    }

    let id: String
    let title: String
    let detail: Detail
    let change: String?
    let before: String
    let after: String
    let reason: String
    let rows: [WaypointDetailRow]
}

private struct WaypointDetailRow: Identifiable {
    let label: String
    let value: String

    var id: String { label }
}

private struct WaypointAdjustmentGroup: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let adjustments: [WaypointAdjustment]

    static let demo: [WaypointAdjustmentGroup] = [
        WaypointAdjustmentGroup(id: "exercise", title: "Exercise", symbol: "figure.walk", adjustments: [
            WaypointAdjustment(
                id: "session",
                title: "S&C session 1",
                detail: .activities([.strength, .run]),
                change: "Increased distance by 1.2 KM",
                before: "3.8 KM",
                after: "5.0 KM",
                reason: "You finished last week's runs with your heart rate well inside zone 2 and recovery above 70 every morning, so there's room to build distance towards 20 KM without adding fatigue.",
                rows: [
                    WaypointDetailRow(label: "Day", value: "Tuesday"),
                    WaypointDetailRow(label: "Strength", value: "Lower body, 45 min"),
                    WaypointDetailRow(label: "Run", value: "5.0 KM easy"),
                    WaypointDetailRow(label: "Target pace", value: "6:10 /KM"),
                    WaypointDetailRow(label: "Heart rate", value: "Zone 2"),
                ]
            ),
            WaypointAdjustment(
                id: "cycle",
                title: "Long Cycle",
                detail: .activities([.cycle]),
                change: "Increased distance by 1.2 KM",
                before: "28.8 KM",
                after: "30.0 KM",
                reason: "Your long cycle is building the aerobic base the 20 KM run needs. A small bump keeps the weekly load rising by under 10%, which is the safe rate for your recent training.",
                rows: [
                    WaypointDetailRow(label: "Day", value: "Saturday"),
                    WaypointDetailRow(label: "Distance", value: "30.0 KM"),
                    WaypointDetailRow(label: "Duration", value: "About 1 h 25 min"),
                    WaypointDetailRow(label: "Heart rate", value: "Zone 2"),
                ]
            ),
        ]),
        WaypointAdjustmentGroup(id: "nutrition", title: "Nutrition", symbol: "fork.knife", adjustments: [
            WaypointAdjustment(
                id: "protein",
                title: "Protein goal Increased",
                detail: .value("103", unit: "G"),
                change: "Increased by 10g",
                before: "93 G",
                after: "103 G",
                reason: "Your running volume went up this week, so your muscles need a little more protein to recover. 103 g works out at 1.6 g per kilo of body weight.",
                rows: [
                    WaypointDetailRow(label: "Per meal", value: "About 30 G"),
                    WaypointDetailRow(label: "Body weight", value: "64 KG"),
                    WaypointDetailRow(label: "Ratio", value: "1.6 G / KG"),
                    WaypointDetailRow(label: "Last week average", value: "88 G"),
                ]
            ),
            WaypointAdjustment(
                id: "mealPlan",
                title: "Meal Plan updated",
                detail: .meals([
                    WaypointMeal(id: "breakfast", slot: "Breakfast", name: "Greek yoghurt & berries", systemImage: "sunrise", color: .defaultOrange, protein: 24),
                    WaypointMeal(id: "lunch", slot: "Lunch", name: "Chicken & quinoa bowl", systemImage: "sun.max", color: .defaultYellow, protein: 42),
                    WaypointMeal(id: "dinner", slot: "Dinner", name: "Salmon, greens & rice", systemImage: "moon", color: .defaultBlue, protein: 37),
                ]),
                change: "Swapped 2 meals for higher protein",
                before: "76 G",
                after: "103 G",
                reason: "Breakfast and lunch were light on protein, so they've been swapped for options that hit your new target without adding calories.",
                rows: [
                    WaypointDetailRow(label: "Breakfast", value: "Toast → Greek yoghurt & berries"),
                    WaypointDetailRow(label: "Lunch", value: "Pasta salad → Chicken & quinoa bowl"),
                    WaypointDetailRow(label: "Dinner", value: "No change"),
                    WaypointDetailRow(label: "Calories", value: "2,180 → 2,160"),
                ]
            ),
        ]),
    ]
}

private struct WaypointAdjustmentSheet: View {
    let adjustment: WaypointAdjustment

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        BrightPageSheetView(title: adjustment.title) {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing4x) {
                    comparison

                    BrightWidgetTitle(icon: .symbol("sparkles"), title: "Why it changed") {
                        BrightText(adjustment.reason, size: .body1, color: .semiLightTextColor)
                            .lineSpacing(.lineSpacingMedium)
                            .padding(.horizontal, .spacing2x)
                    }

                    BrightWidgetTitle(icon: .symbol("list.bullet"), title: "Details") {
                        details
                    }
                }
                .padding(.top, .spacing2x)
                .padding(.bottom, .spacing4x)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom, spacing: .spacing0x) {
                actions
            }
        }
    }

    private var comparison: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing2x) {
                value("Before", adjustment.before, color: .lightTextColor)

                Image(systemName: "arrow.right")
                    .font(.standardSFPro(size: .subheading, weight: .regular))
                    .foregroundStyle(Color.lightTextColor)

                value("After", adjustment.after, color: .defaultGreen)
            }

            if let change = adjustment.change {
                HStack(spacing: .spacing05x) {
                    Image(systemName: "arrow.up")
                        .font(.standardSFPro(size: .body1, weight: .regular))

                    BrightText(change, size: .body1, color: .defaultGreen)
                }
                .foregroundStyle(Color.defaultGreen)
                .opacity(.mediumOpacity)
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    private func value(_ label: String, _ value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            BrightText(label, size: .body1, color: .lightTextColor)

            BrightText(value, size: .standout1, color: color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var details: some View {
        VStack(spacing: .spacing0x) {
            ForEach(Array(adjustment.rows.enumerated()), id: \.element.id) { index, row in
                detailRow(row, isLast: index == adjustment.rows.count - 1)
            }
        }
        .padding(.horizontal, .spacing3x)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    private func detailRow(_ row: WaypointDetailRow, isLast: Bool) -> some View {
        VStack(spacing: .spacing0x) {
            HStack(alignment: .firstTextBaseline, spacing: .spacing2x) {
                BrightText(row.label, size: .body1, color: .lightTextColor)

                Spacer(minLength: .spacing2x)

                BrightText(row.value, size: .body1)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, .spacing2x)

            if !isLast {
                BrightDivider()
            }
        }
    }

    private var actions: some View {
        HStack(spacing: .spacing2x) {
            BrightPillButton(
                "Revert",
                systemImage: "arrow.uturn.backward",
                color: .defaultRed.opacity(.minimalOpacity),
                textColor: .defaultRed,
                buttonSize: .large
            ) {
                dismiss()
            }

            BrightPillButton(
                "Keep change",
                systemImage: "checkmark",
                color: .defaultGreen.opacity(.minimalOpacity),
                textColor: .defaultGreen,
                buttonSize: .large
            ) {
                dismiss()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacing2x)
    }
}

#Preview {
    ScrollView {
        WaypointView()
    }
    .background(Color.defaultBackground)
}
