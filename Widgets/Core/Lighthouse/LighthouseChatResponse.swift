//
//  LighthouseChatResponse.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

enum LighthouseDemoWidget: Equatable {
    case sleep
    case heart
    case activity

    var size: HealthWidgetSize {
        switch self {
        case .sleep: .twoByOne
        case .heart, .activity: .twoByTwo
        }
    }
}

nonisolated struct LighthouseStoryItem: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let widget: LighthouseDemoWidget?
}

// A Lighthouse answer inside the chat thread: the opening line, then each
// insight paired with the widget it talks about.
struct LighthouseChatResponse: View {
    let text: String
    let items: [LighthouseStoryItem]

    @State private var contentWidth: CGFloat = 0
    // Once the sleep widget has settled, fade the non-REM stages so the REM
    // bars stand out.
    @State private var remFocusActive = false

    private let spacing: CGFloat = .spacing205x

    private var cellSize: CGFloat {
        max((contentWidth - spacing) / 2, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing5x) {
            BrightText(text, size: .body1)
                .lineSpacing(.lineSpacingMedium)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(items) { item in
                VStack(alignment: .leading, spacing: .spacing3x) {
                    if let widget = item.widget, contentWidth > 0 {
                        widgetView(for: widget)
                    }

                    BrightText(item.text, size: .body1, color: .lightTextColor)
                        .lineSpacing(.lineSpacingMedium)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .environment(\.lighthouseRampNumbersFromZero, true)
        .environment(\.lighthouseAnimateChartReveal, true)
        .environment(\.lighthouseLoadIn, true)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            contentWidth = width
        }
        .task {
            try? await Task.sleep(for: .milliseconds(1500))
            remFocusActive = true
        }
    }

    // MARK: Widgets

    // Renders the widget at its normal dashboard grid footprint, left-aligned.
    @ViewBuilder
    private func widgetView(for widget: LighthouseDemoWidget) -> some View {
        let size = widget.size
        let width = size.columns == 2 ? contentWidth : cellSize
        let height = size.rows == 2 ? cellSize * 2 + spacing : cellSize

        Group {
            switch widget {
            case .sleep: sleepCard
            case .heart: heartCard
            case .activity: activityCard
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius))
    }

    private var sleepCard: some View {
        HealthDashboardSleepWidget(data: LighthouseDemo.sleepDashboardData)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Sleep gets no number ramp; its only load effect is the REM bars
            // lighting up: the bars start fully dimmed, then REM lights back up.
            .environment(\.lighthouseRampNumbersFromZero, false)
            .environment(\.lighthouseSleepActive, true)
            .environment(\.lighthouseSleepREMFocus, remFocusActive)
    }

    private var heartCard: some View {
        HRAvgWidgetContent(
            size: .twoByTwo,
            hrAvg: "\(LighthouseDemo.heartDashboardData.hrAvg ?? 0)",
            hrHigh: "\(LighthouseDemo.heartDashboardData.hrHigh ?? 0)",
            hrLow: "\(LighthouseDemo.heartDashboardData.hrLow ?? 0)",
            subtitle: "Past 24 HR",
            heartData: LighthouseDemo.heartDashboardData
        )
        .padding(.spacing205x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .modifier(CardModifier())
    }

    private var activityCard: some View {
        ActivityWidgetContent(
            size: .twoByTwo,
            activity: LighthouseDemo.activityValue,
            unit: "Cal",
            expenditureGraphData: LighthouseDemo.activityGraphData,
            tdeeBreakdown: LighthouseDemo.activityTdee
        )
        .padding(.spacing205x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(CardModifier())
    }
}

#Preview {
    ScrollView {
        LighthouseChatResponse(
            text: LighthouseDemo.sleepPartOne,
            items: LighthouseDemo.sleepItems
        )
        .padding(.spacing3x)
    }
    .background(Color.defaultBackground)
}
