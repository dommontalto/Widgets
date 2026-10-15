//
//  BrightSleepSummaryV5.swift
//  Widgets
//
//  Created by Dom Montalto on 9/10/2026.
//

import SwiftUI

// The night at a glance along a sleep widget's top: time in bed, time asleep, and the
// night's score in a pill on the right. Small widgets have room for just the time in bed.
struct BrightSleepSummaryV5: View {
    let asleepMinutes: Int
    let inBedMinutes: Int
    let score: Int
    var isCompact = false
    var boxesIcons = false

    // The totals and score roll up from zero the first time it shows.
    @State private var isRevealed = false
    @Environment(\.brightWidgetIsEmpty) private var isEmpty

    var body: some View {
        HStack(spacing: .spacing0x) {
            HStack(spacing: .spacing1x) {
                total(systemImage: "bed.double", color: .defaultCyan, minutes: inBedMinutes)

                if !isCompact {
                    total(systemImage: "zzz", color: .defaultBrightViolet, minutes: asleepMinutes)
                }
            }

            Spacer(minLength: .spacing0x)

            HStack(alignment: .firstTextBaseline, spacing: .spacing0x) {
                BrightText(isEmpty || score == 0 ? .brightEmptyValue : revealed("\(score)"), size: .heading, color: .defaultGreen, weight: .regular)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                BrightText("%", size: .body5, color: .defaultGreen.opacity(.lowOpacity), weight: .regular)
            }
            .padding(.horizontal, .spacing1x)
            .padding(.vertical, .spacing05x)
            .background(Capsule().fill(Color.defaultGreen.opacity(.minimalOpacity)))
        }
        .lineLimit(1)
        .brightRevealV5($isRevealed)
    }

    // All zeros until revealed, so the number rolls up without changing width.
    private func revealed(_ text: String) -> String {
        isRevealed ? text : text.zeroedDigits
    }

    // A duration as "8 hr 24 m", the units dimmer than the numbers.
    private func total(systemImage: String, color: Color, minutes: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
            if boxesIcons {
                BrightWidgetIconV5(systemImage: systemImage, style: color)
            } else {
                Image(systemName: systemImage)
                    .font(.standard(size: .subheading, weight: .light))
                    .foregroundStyle(color)
            }

            if isEmpty {
                BrightText(.brightEmptyValue, size: .heading)
            } else {
                BrightText(revealed("\(minutes / 60)"), size: .heading)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                BrightText("hr", size: .body4, color: .lightTextColor)
                BrightText(revealed("\(minutes % 60)"), size: .heading)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                BrightText("m", size: .body4, color: .lightTextColor)
            }
        }
    }
}

#Preview {
    BrightSleepSummaryV5(asleepMinutes: 504, inBedMinutes: 525, score: 82)
        .padding(.spacing205x)
        .background(Color.defaultHomeCards)
}
