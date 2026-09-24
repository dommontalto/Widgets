//
//  LighthouseCheckInReviewView.swift
//  Widgets
//
//  Created by Dom Montalto on 24/9/2026.
//

import SwiftUI

struct LighthouseCheckInReviewView: View {
    let review: LighthouseCheckInReview

    @State private var expanded = Set<UUID>()

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing5x) {
            summary

            label(Constants.assessmentTitle, symbol: Constants.assessmentSymbol)
                .frame(maxWidth: .infinity)

            ForEach(review.sections) { section in
                sectionView(section)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.brightSnappy, value: expanded)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            label(Constants.summaryTitle, symbol: Constants.summarySymbol)

            BrightText(review.summary, size: .body1, color: .lightTextColor)
                .lineSpacing(.lineSpacingMedium)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func label(_ title: String, symbol: String) -> some View {
        HStack(spacing: .spacing1x) {
            Image(systemName: symbol)
                .font(.standardSFPro(size: .body1, weight: .light))
                .foregroundStyle(Color.textColor)

            BrightText(title, size: .body1)
        }
    }

    private func sectionView(_ section: LighthouseCheckInReview.Section) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightWidgetTitle(icon: .symbol(section.kind.symbol), title: section.kind.title) {
                widget(for: section.kind)
                    .frame(maxWidth: .infinity)
            }

            VStack(spacing: .spacing0x) {
                ForEach(Array(section.findings.enumerated()), id: \.element.id) { index, finding in
                    findingRow(finding, isLast: index == section.findings.count - 1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func widget(for kind: LighthouseCheckInReview.Section.Kind) -> some View {
        switch kind {
        case .workouts:
            ExerciseTrainingLoadContent(load: LighthouseDemo.trainingLoad, title: "Split", subtitle: "Past 4 weeks")
                .padding(.spacing3x)
                .modifier(CardModifier())
        case .nutrition:
            IntakeBreakdownWidget(viewState: LighthouseDemo.intakeBreakdown)
        case .sleep:
            SleepSummaryWidget(
                title: "Sleep Duration",
                label: "Good",
                sevenDayAvg: Amount(unit: "hr", value: 7.1),
                sevenDayData: LighthouseDemo.sleepSevenDays,
                sevenDayDateRange: "18 – 24 Sep",
                twentyEightDayAvg: Amount(unit: "hr", value: 7.4),
                twentyEightDayData: LighthouseDemo.sleepTwentyEightDays,
                weeklyAverages: LighthouseDemo.sleepWeeklyAverages
            )
        }
    }

    private func findingRow(_ finding: LighthouseCheckInReview.Finding, isLast: Bool) -> some View {
        let isExpanded = expanded.contains(finding.id)
        return Button {
            if isExpanded {
                expanded.remove(finding.id)
            } else {
                expanded.insert(finding.id)
            }
        } label: {
            VStack(alignment: .leading, spacing: .spacing1x) {
                HStack(alignment: .firstTextBaseline, spacing: .spacing2x) {
                    Image(systemName: finding.isOnTrack ? "checkmark.circle" : "exclamationmark.circle")
                        .font(.standardSFPro(size: .subheading2, weight: .regular))
                        .foregroundStyle(finding.isOnTrack ? Color.defaultGreen : Color.defaultYellow)

                    BrightText(finding.text, size: .body1, color: .semiLightTextColor)
                        .lineSpacing(.lineSpacingMedium)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.down")
                        .font(.standardSFPro(size: .body1, weight: .light))
                        .foregroundStyle(Color.lightTextColor)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }

                if isExpanded {
                    BrightText(finding.detail, size: .body1, color: .lightTextColor)
                        .lineSpacing(.lineSpacingMedium)
                        .multilineTextAlignment(.leading)
                        .padding(.leading, Constants.detailIndent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                }
            }
            .padding(.top, .spacing1x)
            .padding(.bottom, isLast ? .spacing0x : .spacing1x)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .brightHaptic(.light, trigger: isExpanded)
    }

    private enum Constants {
        static let summaryTitle = "Check-in Summary"
        static let summarySymbol = "person.badge.clock"
        static let assessmentTitle = "Assessment of week"
        static let assessmentSymbol = "chart.dots.scatter"
        static let detailIndent: CGFloat = .spacing5x
    }
}

#Preview {
    ScrollView {
        LighthouseCheckInReviewView(review: LighthouseDemo.weeklyClimbingReview)
            .padding(.spacing3x)
    }
    .background(Color.defaultBackground)
}
