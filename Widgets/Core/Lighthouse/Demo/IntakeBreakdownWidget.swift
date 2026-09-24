//
//  IntakeBreakdownWidget.swift
//  Widgets
//
//  Created by Gangajaliya Sandeep on 31/1/2024.
//

import SwiftUI

@Observable
class IntakeBreakdownWidgetViewState {
    init(
        title: String,
        breakdown: IntakeBreakdownResponseData,
        showIntakeBar: Bool
    ) {
        self.title = title
        self.breakdown = breakdown
        self.showIntakeBar = showIntakeBar
    }

    static func empty() -> IntakeBreakdownWidgetViewState {
        .init(
            title: "",
            breakdown: IntakeBreakdownResponseData(),
            showIntakeBar: false
        )
    }

    var title: String
    var breakdown: IntakeBreakdownResponseData
    var showIntakeBar: Bool
}

struct IntakeBreakdownWidget: View {
    @Bindable var viewState: IntakeBreakdownWidgetViewState

    private class Constants {
        static let circleSize: CGFloat = 8
        static let barHeight: CGFloat = 25
    }

    var body: some View {
        VStack(spacing: .spacing0x) {
            Header(
                title: viewState.title
            )

            if viewState.showIntakeBar {
                IntakeBreakdownBarWidget(
                    breakfast: Double(viewState.breakdown.breakfast ?? 0),
                    lunch: Double(viewState.breakdown.lunch ?? 0),
                    dinner: Double(viewState.breakdown.dinner ?? 0),
                    snack: Double(viewState.breakdown.snack ?? 0),
                    drink: Double(viewState.breakdown.drink ?? 0)
                )
                .frame(height: Constants.barHeight)
                .padding(.top, .spacing6x)
            }

            BreakdownList(
                breakdown: viewState.breakdown
            )
            .padding(.top, .spacing6x)
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
    }

    struct Header: View {
        let title: String

        var body: some View {
            VStack(spacing: .spacing05x) {
                BrightText(
                    "Intake Breakdown",
                    size: .body1,
                    color: .textColor
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                BrightText(
                    title,
                    size: .body2,
                    color: .lightTextColor,
                    weight: .regular,
                    kerning: .smallKerning
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }
        }
    }

    struct BreakdownList: View {
        let breakdown: IntakeBreakdownResponseData

        var body: some View {
            VStack(spacing: .spacing2x) {
                BreakdownListCell(
                    title: "Breakfast",
                    value: breakdown.breakfast ?? 0,
                    unit: breakdown.displayUnit,
                    color: IntakeGraphData.BarValueType.breakfast.barColor
                )
                divider
                BreakdownListCell(
                    title: "Lunch",
                    value: breakdown.lunch ?? 0,
                    unit: breakdown.displayUnit,
                    color: IntakeGraphData.BarValueType.lunch.barColor
                )
                divider
                BreakdownListCell(
                    title: "Dinner",
                    value: breakdown.dinner ?? 0,
                    unit: breakdown.displayUnit,
                    color: IntakeGraphData.BarValueType.dinner.barColor
                )
                divider
                BreakdownListCell(
                    title: "Snack",
                    value: breakdown.snack ?? 0,
                    unit: breakdown.displayUnit,
                    color: IntakeGraphData.BarValueType.snack.barColor
                )
                divider
                BreakdownListCell(
                    title: "Drink",
                    value: breakdown.drink ?? 0,
                    unit: breakdown.displayUnit,
                    color: IntakeGraphData.BarValueType.drink.barColor
                )
            }
        }

        var divider: some View {
            BrightDivider()
                .frame(height: Constants.dividerHeight)
                .padding(.horizontal, Constants.dividerOffSet)
        }

        private class Constants {
            static let dividerHeight: CGFloat = 0.5
            static let dividerOffSet: CGFloat = -18
        }
    }

    struct BreakdownListCell: View {
        let title: String
        let value: Int
        let unit: String
        let color: Color

        var body: some View {
            HStack(spacing: .spacing1x) {
                RowCircleIcon(color: color)
                BrightText(
                    title,
                    size: .body2,
                    kerning: .mediumKerning
                )
                Spacer()
                HStack(
                    alignment: .lastTextBaseline,
                    spacing: .spacing05x
                ) {
                    BrightText(
                        String(value),
                        size: .subheading,
                        kerning: .mediumKerning
                    )
                    BrightText(
                        unit,
                        size: .body3,
                        kerning: .mediumKerning
                    )
                }
            }
        }
    }
}

#Preview {
    IntakeBreakdownWidget(
        viewState: .empty()
    )
}
