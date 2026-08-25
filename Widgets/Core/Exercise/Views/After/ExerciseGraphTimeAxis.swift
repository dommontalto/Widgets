//
//  ExerciseGraphTimeAxis.swift
//  Widgets
//
//  Created by Dom Montalto on 24/8/2026.
//

import SwiftUI

// The clock times either end of a session graph. While a point is held the two
// ends give way to the held time, which rides the scrub line.
struct ExerciseGraphTimeAxis: View {
    struct Scrub {
        // Where along the plot the held point sits, 0...1.
        let fraction: Double
        let label: String
    }

    let startLabel: String
    let endLabel: String
    var scrub: Scrub?

    var body: some View {
        HStack(spacing: .spacing0x) {
            BrightText(startLabel, size: .body1, color: .lightTextColor)

            Spacer(minLength: .spacing2x)

            BrightText(endLabel, size: .body1, color: .lightTextColor)
        }
        .opacity(scrub == nil ? .opaque : 0)
        .overlay(alignment: .leading) {
            if let scrub {
                held(scrub)
                    .transition(.opacity)
            }
        }
        .animation(.brightEaseInOut, value: scrub == nil)
    }

    private func held(_ scrub: Scrub) -> some View {
        GeometryReader { proxy in
            BrightText(scrub.label, size: .body1, color: .lightTextColor)
                .monospacedDigit()
                .frame(width: Constants.heldWidth)
                .multilineTextAlignment(.center)
                .offset(x: offset(for: scrub.fraction, in: proxy.size.width))
        }
    }

    // Centred on the line, but never past either end of the plot.
    private func offset(for fraction: Double, in width: CGFloat) -> CGFloat {
        let clamped = CGFloat(min(max(fraction, 0), 1))
        let centred = width * clamped - Constants.heldWidth / 2
        return min(max(centred, 0), max(width - Constants.heldWidth, 0))
    }

    private enum Constants {
        static let heldWidth: CGFloat = 80
    }
}

#Preview {
    VStack(spacing: .spacing6x) {
        ExerciseGraphTimeAxis(startLabel: "8:05 PM", endLabel: "8:47 PM")

        ExerciseGraphTimeAxis(
            startLabel: "8:05 PM",
            endLabel: "8:47 PM",
            scrub: .init(fraction: 0.4, label: "8:22 PM")
        )
    }
    .padding(.spacing3x)
    .background(Color.defaultSheetBackground.ignoresSafeArea())
}
