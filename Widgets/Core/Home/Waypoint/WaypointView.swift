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

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing4x) {
            header
                .frame(maxWidth: .infinity)

            adjustments
        }
        .padding(.horizontal, .spacing3x)
        .padding(.top, .spacing4x)
        .padding(.bottom, .spacing12x)
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

                BrightRoundButton(systemImage: "arrow.down.backward.and.arrow.up.forward") {}
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
                change: "Increased distance by 1.2 KM"
            ),
            WaypointAdjustment(
                id: "cycle",
                title: "Long Cycle",
                detail: .activities([.cycle]),
                change: "Increased distance by 1.2 KM"
            ),
        ]),
        WaypointAdjustmentGroup(id: "nutrition", title: "Nutrition", symbol: "fork.knife", adjustments: [
            WaypointAdjustment(
                id: "protein",
                title: "Protein goal Increased",
                detail: .value("103", unit: "G"),
                change: "Increased by 10g"
            ),
            WaypointAdjustment(
                id: "mealPlan",
                title: "Meal Plan updated",
                detail: .meals([
                    WaypointMeal(id: "breakfast", slot: "Breakfast", name: "Greek yoghurt & berries", systemImage: "sunrise", color: .defaultOrange, protein: 24),
                    WaypointMeal(id: "lunch", slot: "Lunch", name: "Chicken & quinoa bowl", systemImage: "sun.max", color: .defaultYellow, protein: 42),
                    WaypointMeal(id: "dinner", slot: "Dinner", name: "Salmon, greens & rice", systemImage: "moon", color: .defaultBlue, protein: 37),
                ]),
                change: "Swapped 2 meals for higher protein"
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
