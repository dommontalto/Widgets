//
//  IntakeBreakdownBarWidget.swift
//  Widgets
//
//  Created by Gangajaliya Sandeep on 31/1/2024.
//

import SwiftUI

struct IntakeBreakdownBarWidget: View {
    let breakfast: Double
    let lunch: Double
    let dinner: Double
    let snack: Double
    let drink: Double

    private class Constants {
        static let spacing: CGFloat = 2
        static let spacingDiff: CGFloat = spacing / 4
        static let cornerRadius: CGFloat = 12
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: Constants.spacing) {
                if breakfast != 0 {
                    Rectangle()
                        .fill(IntakeGraphData.BarValueType.breakfast.barColor)
                        .frame(
                            width: breakfastWidth(geometry.size.width)
                        )
                }
                if lunch != 0 {
                    Rectangle()
                        .fill(IntakeGraphData.BarValueType.lunch.barColor)
                        .frame(
                            width: lunchWidth(geometry.size.width)
                        )
                }
                if dinner != 0 {
                    Rectangle()
                        .fill(IntakeGraphData.BarValueType.dinner.barColor)
                        .frame(
                            width: dinnerWidth(geometry.size.width)
                        )
                }
                if snack != 0 {
                    Rectangle()
                        .fill(IntakeGraphData.BarValueType.snack.barColor)
                        .frame(
                            width: snackWidth(geometry.size.width)
                        )
                }
                if drink != 0 {
                    Rectangle()
                        .fill(IntakeGraphData.BarValueType.drink.barColor)
                        .frame(
                            width: drinkWidth(geometry.size.width)
                        )
                }
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Constants.cornerRadius
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .stroke(Color.defaultBreakdownBarBackground, lineWidth: 2)
                    .padding(-1)
            )
        }
    }

    var total: Double {
        breakfast + lunch + dinner + snack + drink
    }

    func breakfastWidth(_ geometryWidth: CGFloat) -> CGFloat {
        let breakfastPercentage = breakfast / total
        return (geometryWidth - Constants.spacingDiff) * breakfastPercentage
    }

    func lunchWidth(_ geometryWidth: CGFloat) -> CGFloat {
        let lunchPercentage = lunch / total
        return (geometryWidth - Constants.spacingDiff) * lunchPercentage
    }

    func dinnerWidth(_ geometryWidth: CGFloat) -> CGFloat {
        let dinnerPercentage = dinner / total
        return (geometryWidth - Constants.spacingDiff) * dinnerPercentage
    }

    func snackWidth(_ geometryWidth: CGFloat) -> CGFloat {
        let snackPercentage = snack / total
        return max(0, (geometryWidth - Constants.spacingDiff) * snackPercentage)
    }

    func drinkWidth(_ geometryWidth: CGFloat) -> CGFloat {
        let drinkPercentage = drink / total
        return max(0, (geometryWidth - Constants.spacingDiff) * drinkPercentage)
    }
}

#Preview {
    IntakeBreakdownBarWidget(breakfast: 0, lunch: 0, dinner: 0, snack: 0, drink: 0)
}
