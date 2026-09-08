//
//  HRAvgWidgetContent.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

struct HRAvgWidgetContent: View {
    var size: HealthWidgetSize = .twoByTwo
    var hrAvg: String
    var hrHigh: String
    var hrLow: String
    var subtitle: String
    var heartData: HealthDashboardHeartData?
    var healthStatus: String?

    var body: some View {
        switch size {
        case .oneByOne: singleHRAvgCard
        case .twoByOne: extendedHRAvgCard
        case .twoByTwo: largestHRAvgCard
        }
    }

    private var header: some View {
        HStack(spacing: .spacing1x) {
            Image(ImageNames.hrvV4)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.iconSize, height: Constants.iconSize)

            BrightText("HR AVG", size: .body1)

            Spacer()
        }
    }

    private var averageReading: some View {
        HStack(alignment: .lastTextBaseline, spacing: .spacing1x) {
            RollingNumberText(value: Int(hrAvg) ?? 0, size: .huge2, color: .textColor)
            BrightText("BPM AVG", size: .body3, color: .semiLightTextColor)
        }
    }

    private var lowHighReadings: some View {
        HStack(spacing: .spacing1x) {
            Image(ImageNames.circleChevronBottomV5)
            BrightText(hrLow, size: .body3)
                .monospacedDigit()
            Image(ImageNames.circleChevronTopV5)
            BrightText(hrHigh, size: .body3)
                .monospacedDigit()
        }
    }

    // MARK: 1 x 1

    private var singleHRAvgCard: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            header
            BrightText(subtitle, size: .body3, color: .semiLightTextColor)
            Spacer(minLength: 0)
            WidgetBuilderChartView(size: .small, heartData: heartData)
                .padding(.vertical, -.spacing05x)

            HStack(spacing: .spacing0x) {
                averageReading
                    .layoutPriority(1)
                Spacer()
                VStack(alignment: .trailing, spacing: .spacing0x) {
                    HStack(spacing: .spacing05x) {
                        BrightText(hrHigh, size: .body3)
                            .monospacedDigit()
                        Image(ImageNames.circleChevronTopV5)
                    }
                    HStack(spacing: .spacing05x) {
                        BrightText(hrLow, size: .body3)
                            .monospacedDigit()
                        Image(ImageNames.circleChevronBottomV5)
                    }
                }
            }
        }
    }

    // MARK: 2 x 1

    private var extendedHRAvgCard: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing1x) {
                header
                lowHighReadings
                BrightStatus(status: healthStatus ?? "AVERAGE")
            }
            BrightText(subtitle, size: .body3, color: .semiLightTextColor)
            Spacer()
            HStack(alignment: .bottom, spacing: .spacing2x) {
                averageReading
                WidgetBuilderChartView(size: .extended, heartData: heartData)
            }
        }
    }

    // MARK: 2 x 2

    private var largestHRAvgCard: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(spacing: .spacing1x) {
                header
                BrightStatus(status: healthStatus ?? "AVERAGE")
            }
            BrightText(subtitle, size: .body3, color: .semiLightTextColor)

            Spacer()

            HStack(spacing: .spacing1x) {
                averageReading
                Spacer()
                lowHighReadings
            }

            Spacer()

            WidgetBuilderChartView(size: .largest, heartData: heartData)
        }
    }

    private enum Constants {
        static let iconSize: CGFloat = 24
    }
}

#Preview {
    HRAvgWidgetContent(
        hrAvg: "80",
        hrHigh: "96",
        hrLow: "64",
        subtitle: "Past 24 HR",
        heartData: LighthouseDemo.heartDashboardData
    )
    .padding(.spacing205x)
    .frame(height: 360)
    .modifier(CardModifier())
    .padding(.spacing3x)
    .background(Color.defaultBackground)
}
