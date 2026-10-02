//
//  DashboardLinearWidget.swift
//  Widgets
//
//  Created by Amin Zabihi on 7/1/2026.
//

import SwiftUI

// MARK: - Data model

struct DashboardLinearWidgetModel: Equatable {
    let title: String
    let currentValue: Int
    let goalValue: Int
    let unit: String
}

// MARK: - ViewState (Small)

@Observable
class DashboardLinearWidgetSmallViewState {
    init(model: DashboardLinearWidgetModel) {
        self.model = model
    }

    var model: DashboardLinearWidgetModel

    var progress: Double {
        guard model.goalValue > 0 else { return 0 }
        return min(Double(model.currentValue) / Double(model.goalValue), 1)
    }

    var valueText: String {
        model.currentValue.withCommas
    }
    var unitText: String {
        model.unit
    }
    var remainingText: String {
        max(model.goalValue - model.currentValue, 0).withCommas + " remaining"
    }
    var minLabel: String {
        "0"
    }
    var maxLabel: String {
        model.goalValue.withCommas
    }
    var titleText: String {
        model.title
    }
}

// MARK: - ViewState (Large)

@Observable
class DashboardLinearWidgetLargeViewState: DashboardLinearWidgetSmallViewState {
    init(
        model: DashboardLinearWidgetModel,
        contributors: [String]
    ) {
        self.contributors = contributors
        super.init(model: model)
    }

    var contributors: [String]
}

// MARK: - Small

struct DashboardLinearWidgetSmall: View {
    let viewState: DashboardLinearWidgetSmallViewState

    var body: some View {
        DashboardLinearBaseCard(
            title: viewState.titleText,
            valueText: viewState.valueText,
            unitText: viewState.unitText,
            remainingText: viewState.remainingText,
            minLabel: viewState.minLabel,
            maxLabel: viewState.maxLabel,
            progress: viewState.progress,
            rightContent: nil
        )
        .frame(width: 168, height: 168)
    }
}

// MARK: - Large

struct DashboardLinearWidgetLarge: View {
    let viewState: DashboardLinearWidgetLargeViewState

    var body: some View {
        DashboardLinearBaseCard(
            title: viewState.titleText,
            valueText: viewState.valueText,
            unitText: viewState.unitText,
            remainingText: viewState.remainingText,
            minLabel: viewState.minLabel,
            maxLabel: viewState.maxLabel,
            progress: viewState.progress,
            rightContent: AnyView(rightColumn)
        )
        .frame(width: 354, height: 168)
    }

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            ForEach(viewState.contributors.indices, id: \.self) { idx in
                BrightText(
                    viewState.contributors[idx],
                    size: .body4,
                    color: .semiLightTextColor
                )
            }
            Spacer(minLength: .spacing0x)
        }
        .padding(.top, .spacing3x)
        .padding(.trailing, .spacing4x)
        .padding(.leading, .spacing0x)
    }
}

// MARK: - Shared base

private struct DashboardLinearBaseCard: View {
    let title: String
    let valueText: String
    let unitText: String
    let remainingText: String
    let minLabel: String
    let maxLabel: String
    let progress: Double

    let rightContent: AnyView?

    private enum Constants {
        static let rightColumnWidth: CGFloat = 140
        static let cornerRadius: CGFloat = .cardCornerRadius
    }

    var body: some View {
        HStack(spacing: .spacing2x) {
            leftColumn
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            if let rightContent {
                rightContent
                    .frame(width: Constants.rightColumnWidth, alignment: .leading)
                    .layoutPriority(0)
            }
        }
        .modifier(
            BrightCardModifierV5(
                color: Color.defaultCards,
                cornerRadius: Constants.cornerRadius
            )
        )
        .addBorder(Color.textColor.opacity(.veryLowOpacity), cornerRadius: Constants.cornerRadius)
    }

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            BrightText(
                title,
                size: .body3,
                color: .semiLightTextColor
            )
            .padding(.top, .spacing3x)

            valueRow

            BrightText(
                remainingText,
                size: .body4,
                color: .semiLightTextColor
            )
            .padding(.bottom, .spacing1x)

            Spacer(minLength: .spacing0x)

            HStack {
                BrightText(minLabel, size: .body5, color: .semiLightTextColor)
                Spacer()
                BrightText(maxLabel, size: .body5, color: .semiLightTextColor)
            }

            progressBar
                .padding(.bottom, .spacing3x)
        }
        .padding(.horizontal, .spacing3x)
    }

    private var valueRow: some View {
        valueRow(size: .huge3)
    }

    private func valueRow(size: FontSizes) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: .spacing1x) {
            BrightText(
                valueText,
                size: size,
                color: .lightTextColor,
                weight: .regular,
                scaleTextSize: 0.5
            )
            .monospacedDigit()
            .lineLimit(1)
            .layoutPriority(0)

            BrightText(
                unitText,
                size: .body3,
                color: .semiLightTextColor
            )
            .padding(.bottom, .spacing1x)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .allowsTightening(true)
            .layoutPriority(1)
        }
    }

    private var progressBar: some View {
        ZStack {
            background
                .opacity(.veryLowOpacity)

            ProgressView(
                value: max(0, min(progress, 1)),
                total: 1
            )
            .progressViewStyle(
                .gradientProgressBar(
                    backgroundColor: .clear,
                    gradientColors: [Color(hex: "71C3FF"), Color(hex: "59CC81")],
                    cornerRadius: CGFloat.cardCornerRadius
                )
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 8)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: .cardCornerRadius)
            .fill(
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color(hex: "58CB81"), location: 0.00),
                        Gradient.Stop(color: Color(hex: "96802A"), location: 0.68),
                        Gradient.Stop(color: Color(hex: "985536"), location: 0.85),
                        Gradient.Stop(color: Color(hex: "E25E41"), location: 1.00),
                    ],
                    startPoint: UnitPoint(x: 0, y: 1),
                    endPoint: UnitPoint(x: 1, y: 1)
                )
            )
    }
}
