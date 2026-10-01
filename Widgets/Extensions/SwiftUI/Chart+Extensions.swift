//
//  Chart+Extensions.swift
//  Widgets
//
//  Created by Zoe Friedman on 4/1/2024.
//

import Charts
import SwiftUI

extension View {
    public func styleChart(unit: String) -> some View {
        chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                if value.index == 0 {
                    AxisValueLabel {
                        BrightText("0 \(unit)", size: .body5, color: .semiLightTextColor)
                    }
                } else {
                    AxisValueLabel()
                        .font(
                            .standard(
                                size: .body5,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(Color.semiLightTextColor)
                }
            }
        }
        .chartPlotStyle { plotArea in
            plotArea.border(
                Color.textColor.opacity(.veryLowOpacity),
                width: 0.5
            )
        }
    }
}

extension BarMark {
    func cornerRadius(_ radius: CGFloat, corner: UIRectCorner) -> some ChartContent {
        clipShape(RoundedCorner(radius: radius, corners: corner))
    }

    func roundedTopCorners(_ radius: CGFloat = 5) -> some ChartContent {
        clipShape(RoundedCorner(radius: radius, corners: [.topLeft, .topRight]))
    }

    func roundedBottomCorners(_ radius: CGFloat = 5) -> some ChartContent {
        clipShape(RoundedCorner(radius: radius, corners: [.bottomLeft, .bottomRight]))
    }
}

extension ScrollTargetBehavior where Self == GraphChartScrollTargetBehavior {
    static func dateAligned(
        tab: GraphTab,
        dateSections: [[Date]],
        currentData: Binding<GraphDisplayData?>
    ) -> GraphChartScrollTargetBehavior {
        GraphChartScrollTargetBehavior(
            tab: tab,
            dateSections: dateSections,
            currentData: currentData
        )
    }
}

struct GraphChartScrollTargetBehavior: ChartScrollTargetBehavior {
    enum Direction {
        case left
        case right
    }

    let tab: GraphTab
    let dateSections: [[Date]]
    @Binding var currentData: GraphDisplayData?

    func updateTarget(
        _ target: inout ScrollTarget,
        context: ChartScrollTargetBehaviorContext
    ) {
        func scrollTo(currentDate: Date, direction: Direction) {
            if let idx = dateSections.firstIndex(where: { $0.contains(where: {
                GraphDateManager.areDatesEqual($0, currentDate, basedOn: tab)
            }) }) {
                let newIndex = idx + (direction == .left ? -1 : 1)

                let safeIndex = max(min(newIndex, dateSections.count - 1), 0)

                if let date = dateSections[safeIndex].first,
                   let pos = context.chartProxy.position(forX: date) {
                    target.rect.origin.x = pos
                }
            }
        }

        func snapTo(currentDate: Date) {
            if let idx = dateSections.firstIndex(where: { $0.contains(where: {
                GraphDateManager.areDatesEqual($0, currentDate, basedOn: tab)
            }) }) {
                if let date = dateSections[idx].first,
                   let pos = context.chartProxy.position(forX: date) {
                    target.rect.origin.x = pos
                }
            }
        }

        guard let currentData else { return }

        if context.velocity.dx == 0 {
            // Scrolling. Snap back to current.
            snapTo(currentDate: currentData.date)
        } else {
            // Swiping
            scrollTo(
                currentDate: currentData.date,
                direction: context.velocity.dx < 0 ? .left : .right
            )
        }
    }
}
