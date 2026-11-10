//
//  ActivityView.swift
//  Widgets
//
//  Created by Dom Montalto on 10/11/2026.
//

import SwiftUI

enum ActivityViewTab: Int, CaseIterable {
    case summary
    case data
    case insights

    var title: String {
        switch self {
        case .summary: "Summary"
        case .data: "Data"
        case .insights: "Insights"
        }
    }

    var systemImage: String {
        switch self {
        case .summary: "text.line.2.summary"
        case .data: "graph.2d"
        case .insights: "sparkles"
        }
    }
}

struct ActivityView: View {
    @State private var selectedTabIndex = ActivityViewTab.data.rawValue
    @State private var openedMetric: ActivityMetric?
    @State private var widgetHeight: CGFloat = 0

    var body: some View {
        BrightSwipePageViewV5(
            pages: ActivityViewTab.allCases.map { SwipePage(title: $0.title, systemImage: $0.systemImage) },
            fakeLargeTitle: "Activity",
            backgroundColor: .defaultBackground,
            selectedIndex: $selectedTabIndex
        ) { index in
            switch ActivityViewTab(rawValue: index) ?? .summary {
            case .summary:
                Color.clear
                    .frame(maxWidth: .infinity)
            case .data:
                dataTab
            case .insights:
                insightsTab
            }
        }
        .sheet(item: $openedMetric) { metric in
            ActivityChartSheet(metric: metric)
        }
    }

    private var dataTab: some View {
        VStack(spacing: HealthWidgetGridMetricsV5.spacing) {
            ForEach(ActivityMetric.allCases) { metric in
                BrightVerticalBarChartWidgetV5(
                    appearance: metric.bars.appearance,
                    subtitle: metric.bars.subtitle(for: .today),
                    range: .today,
                    bars: metric.bars.bars(for: .today),
                    fill: metric.bars.fill(for: .today),
                    target: metric.bars.target(for: .today),
                    comparison: "Yesterday: \(metric.bars.appearance.format(metric.bars.yesterday))",
                    size: .medium
                )
                .frame(height: widgetHeight)
                .contentShape(.rect)
                .onTapGesture {
                    openedMetric = metric
                }
            }
        }
        .padding(HealthWidgetGridMetricsV5.spacing)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
            widgetHeight = HealthWidgetGridMetricsV5.cellSize(containerWidth: width)
        }
    }

    private var insightsTab: some View {
        VStack(alignment: .leading, spacing: .spacing5x) {
            BrightWidgetTitleV5(icon: .symbol("light.beacon.max.fill"), title: "Lighthouse") {
                BrightImpactWidgetV5(type: .summary, title: "This week", data: ActivityViewDemo.lighthouse)
            }

            BrightWidgetTitleV5(icon: .symbol("globe.americas.fill"), title: "Atlas") {
                BrightImpactWidgetV5(type: .how, title: "Compared to others", data: ActivityViewDemo.atlas)
            }

            BrightWidgetTitleV5(icon: .symbol("flask.fill"), title: "Experiments") {
                BrightImpactWidgetV5(type: .what, title: "What's working", data: ActivityViewDemo.experiments)
            }
        }
        .padding(.spacing3x)
    }
}

private struct ActivityChartSheet: View {
    let metric: ActivityMetric

    @State private var type = BrightChartV5v2Type.bar
    @State private var range = BrightChartV5v2Range.day

    var body: some View {
        BrightPageSheetViewV5(title: metric.title, horizontalPadding: .spacing0x) {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Type", selection: $type) {
                        ForEach(BrightChartV5v2Type.allCases) { type in
                            Label(type.title, systemImage: type.systemImage).tag(type)
                        }
                    }
                } label: {
                    Label(type.title, systemImage: type.systemImage)
                        .labelStyle(.iconOnly)
                }
            }
        } content: {
            ScrollView {
                BrightChartV5v2(type: type, range: $range, tint: metric.tint, unit: metric.unit) { period in
                    BrightChartV5v2Demo.points(for: period, type: type)
                }
                .padding(.bottom, .viewPaddingBottom)
            }
        }
        .sensoryFeedback(.selection, trigger: type)
    }
}

#Preview {
    NavigationStack {
        ActivityView()
    }
}
