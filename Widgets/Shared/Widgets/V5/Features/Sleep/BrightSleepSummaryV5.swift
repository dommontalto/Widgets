//
//  BrightSleepSummaryV5.swift
//  Widgets
//
//  Created by Dom Montalto on 9/10/2026.
//

import SwiftUI

// The night at a glance along a sleep widget's top: time asleep, time in bed, and the
// night's score in a pill on the right. Small widgets have no room for the totals, so a
// title takes their place, with the time asleep under it.
struct BrightSleepSummaryV5: View {
    let asleepMinutes: Int
    let inBedMinutes: Int
    let score: Int
    var isCompact = false

    var body: some View {
        HStack(spacing: .spacing3x) {
            if isCompact {
                VStack(alignment: .leading, spacing: .spacing05x) {
                    HStack(spacing: .spacing05x) {
                        Image(systemName: "moon.fill")
                            .font(.standard(size: .subheading, weight: .light))
                            .foregroundStyle(Color.defaultCyan)

                        BrightText("Sleep", size: .body1, weight: .regular)
                    }

                    BrightText("\(asleepMinutes / 60) h \(asleepMinutes % 60) m asleep", size: .body2, color: .lightTextColor)
                        .monospacedDigit()
                }
            } else {
                total(systemImage: "zzz", color: .defaultBrightViolet, minutes: asleepMinutes)

                total(systemImage: "bed.double", color: .defaultCyan, minutes: inBedMinutes)
            }

            Spacer(minLength: .spacing0x)

            HStack(alignment: .firstTextBaseline, spacing: .spacing0x) {
                BrightText("\(score)", size: .heading, color: .defaultGreen, weight: .regular)
                    .monospacedDigit()

                BrightText("%", size: .body5, color: .defaultGreen.opacity(.lowOpacity), weight: .regular)
            }
            .padding(.horizontal, .spacing1x)
            .padding(.vertical, .spacing05x)
            .background(Capsule().fill(Color.defaultGreen.opacity(.minimalOpacity)))
        }
        .lineLimit(1)
    }

    // A duration as "8 hr 24 m", the units dimmer than the numbers.
    private func total(systemImage: String, color: Color, minutes: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
            Image(systemName: systemImage)
                .font(.standard(size: .heading, weight: .light))
                .foregroundStyle(color)

            BrightText("\(minutes / 60)", size: .standout3)
                .monospacedDigit()
            BrightText("hr", size: .body3, color: .lightTextColor)
            BrightText("\(minutes % 60)", size: .standout3)
                .monospacedDigit()
            BrightText("m", size: .body3, color: .lightTextColor)
        }
    }
}

#Preview {
    BrightSleepSummaryV5(asleepMinutes: 504, inBedMinutes: 525, score: 82)
        .padding(.spacing205x)
        .background(Color.defaultHomeCards)
}
