//
//  ActivityWidgetContent.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

struct ActivityWidgetContent: View {
    var size: HealthWidgetSize = .twoByTwo
    var activity: Int
    var unit: String
    var expenditureGraphData: ActivityGraphData?
    var tdeeBreakdown: ActivityTdeeBreakdownResponseData?

    // When set (Lighthouse), the top-contributor numbers ramp up from zero
    // instead of showing static text.
    @Environment(\.lighthouseRampNumbersFromZero) private var rampNumbers

    var body: some View {
        switch size {
        case .oneByOne: singleActivityCard
        case .twoByOne: extendedActivityCard
        case .twoByTwo: largestActivityCard
        }
    }

    private var header: some View {
        HStack(spacing: .spacing1x) {
            Image(ImageNames.activityWidgetIconV5)
            BrightText("Activity", size: .body1)
            Spacer()
        }
    }

    private var trend: some View {
        HStack(spacing: .spacing1x) {
            Image(ImageNames.circleChevronBottomV5)
            BrightText("Less than 24HR ago", size: .body3, color: .semiLightTextColor)
        }
    }

    private func headline(spacing: CGFloat) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: spacing) {
            RollingNumberText(value: activity, size: .huge2, color: .defaultOrange)
            BrightText(unit, size: .body3, color: .semiLightTextColor)
        }
    }

    @ViewBuilder
    private func chart(size: WidgetBuilderBarChartView.BarChartSize) -> some View {
        if let expenditureGraphData {
            WidgetBuilderBarChartView(size: size, activityGraphData: expenditureGraphData)
        }
    }

    // MARK: 1 x 1

    private var singleActivityCard: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            header
            headline(spacing: .spacing05x)
            Spacer()
            trend
        }
    }

    // MARK: 2 x 1

    private var extendedActivityCard: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing1x) {
                header
                trend
            }
            headline(spacing: .spacing1x)
            chart(size: .extended)
                .frame(maxHeight: .infinity)
        }
    }

    // MARK: 2 x 2

    private var largestActivityCard: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing1x) {
                header
                trend
            }
            headline(spacing: .spacing05x)

            Spacer()

            chart(size: .split)

            Spacer()

            if let tdee = tdeeBreakdown {
                VStack(alignment: .leading, spacing: .spacing2x) {
                    BrightDivider()

                    BrightText("Top Contributors", size: .body1)

                    HStack(spacing: .spacing0x) {
                        tdeeRow(title: "BMR", value: tdee.bmr, unit: tdee.displayUnit, color: .textColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        tdeeRow(title: "NEAT", value: tdee.neat, unit: tdee.displayUnit, color: .defaultBrightViolet)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(spacing: .spacing0x) {
                        tdeeRow(title: "TEF", value: tdee.tef, unit: tdee.displayUnit, color: .defaultBrightPink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        tdeeRow(title: "EAT", value: tdee.eat, unit: tdee.displayUnit, color: .defaultRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private func tdeeRow(title: String, value: Int?, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing1x) {
                RowCircleIcon(color: color)
                BrightText(title, size: .body1)
            }
            if rampNumbers {
                HStack(spacing: .spacing05x) {
                    RollingNumberText(value: value ?? 0, size: .body1, color: .semiLightTextColor)
                    BrightText(unit, size: .body1, color: .semiLightTextColor)
                }
            } else {
                BrightText("\(value ?? 0) \(unit)", size: .body1, color: .semiLightTextColor)
                    .monospacedDigit()
            }
        }
    }
}

#Preview {
    ActivityWidgetContent(
        activity: LighthouseDemo.activityValue,
        unit: "Cal",
        expenditureGraphData: LighthouseDemo.activityGraphData,
        tdeeBreakdown: LighthouseDemo.activityTdee
    )
    .padding(.spacing205x)
    .frame(height: 360)
    .modifier(CardModifier())
    .padding(.spacing3x)
    .background(Color.defaultBackground)
}
