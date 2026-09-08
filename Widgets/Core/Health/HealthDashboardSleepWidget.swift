//
//  HealthDashboardSleepWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import Charts
import SwiftUI

struct HealthDashboardSleepWidget: View {
    let data: HealthDashboardSleepData

    var body: some View {
        VStack(spacing: .spacing0x) {
            HStack {
                BrightText(Date.brightTimeRange(from: data.sleepStart, to: data.sleepEnd), size: .body1)
                Spacer()
                HStack(spacing: .spacing1x) {
                    BrightText("Score", size: .body1, color: .semiLightTextColor)
                    RollingNumberText(value: data.score, size: .standout3, color: scoreColor)
                        .frame(width: Constants.scoreWidth, height: Constants.scoreHeight)
                        .background(scoreColor.opacity(.veryLowOpacity))
                        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous))
                }
            }
            Spacer()
            ChartView(sleepValues: data.values)
            Spacer()
            HStack(alignment: .lastTextBaseline) {
                BrightText(duration, size: .body1, color: .semiLightTextColor)
                Spacer()
                HStack(spacing: .spacing05x) {
                    BrightText(heartRateText, size: .body1, color: .defaultRed)
                        .monospacedDigit()
                    Image(ImageNames.hrvV4)
                    BrightText("AVG", size: .body1, color: .defaultRed)
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(CardModifier())
    }

    struct ChartView: View {
        let sleepValues: [SleepGraphResponseValues]

        // In the Lighthouse story the bars start fully dimmed (`sleepActive`);
        // `remFocus` then lights the REM bars on load.
        @Environment(\.lighthouseSleepREMFocus) private var remFocus
        @Environment(\.lighthouseSleepActive) private var sleepActive

        var body: some View {
            Chart {
                ForEach(sleepValues.indices, id: \.self) { index in
                    let value = sleepValues[index]
                    // Nudge each bar by a growing offset so neighbours never overlap.
                    let shift = TimeInterval(index * Constants.barShiftSeconds)

                    BarMark(
                        xStart: .value("Clocking In", value.start.addingTimeInterval(shift)),
                        xEnd: .value("Clocking Out", value.end.addingTimeInterval(shift)),
                        y: .value("Stage", "Sleep"),
                        height: MarkDimension(floatLiteral: Constants.graphHeight)
                    )
                    .foregroundStyle(value.sleepState.color.opacity(barOpacity(value.sleepState)))
                    .cornerRadius(.cornerRadius4)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: Constants.graphHeight)
            .animation(.easeInOut(duration: 0.6), value: remFocus)
        }

        // Normal dashboard: every bar full. Lighthouse story: all bars start
        // dimmed, then the load (`remFocus`) lights the REM bars back to full.
        private func barOpacity(_ state: SleepGraphResponseValues.SleepState) -> Double {
            guard sleepActive else { return .opaque }
            return (remFocus && state == .rem) ? .opaque : .veryMinimalOpacity
        }
    }

    private var heartRateText: String {
        guard let heartRate = data.heartRate, heartRate != 0 else { return "-BPM" }
        return "\(heartRate) BPM"
    }

    private var duration: String {
        var formattedText = ""
        if data.durationHours != 0 {
            formattedText = "\(data.durationHours)H "
        }
        if data.durationMinutes != 0 {
            formattedText += "\(data.durationMinutes)MIN"
        }
        return formattedText
    }

    private var scoreColor: Color {
        if data.score >= 85 {
            .defaultBrightGreen
        } else if data.score >= 70 {
            .defaultElectricBlue
        } else if data.score >= 50 {
            .defaultBrightPink
        } else if data.score >= 30 {
            .defaultOrange
        } else {
            .defaultRed
        }
    }

    private enum Constants {
        static let scoreWidth: CGFloat = 40
        static let scoreHeight: CGFloat = 26
        static let graphHeight: CGFloat = 38
        static let barShiftSeconds = 90
    }
}

#Preview {
    HealthDashboardSleepWidget(data: LighthouseDemo.sleepDashboardData)
        .frame(height: 180)
        .padding(.spacing3x)
        .background(Color.defaultBackground)
}
