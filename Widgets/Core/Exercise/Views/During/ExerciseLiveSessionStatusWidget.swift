//
//  ExerciseLiveSessionStatusWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 4/8/2026.
//

import SwiftUI

struct ExerciseLiveSessionStatusWidget: View {
    enum Status {
        /// Mid-set: the four set controls.
        case working(label: String, upNext: String)
        /// Between sets, counting down to `until`.
        case resting(upNext: String, until: Date)
        case allSetsComplete
    }

    let status: Status
    var onTag: () -> Void = {}
    var onRestart: () -> Void = {}
    var onSkip: () -> Void = {}
    var onComplete: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            switch status {
            case let .working(label, upNext):
                workingHeader(label: label, upNext: upNext)

                Spacer(minLength: .spacing4x)

                workingControls

            case let .resting(upNext, until):
                restingHeader(upNext: upNext, until: until)

                Spacer(minLength: .spacing4x)

                restingControls

            case .allSetsComplete:
                completeContent
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Constants.cardHeight)
        .modifier(CardModifier(cornerRadius: .cornerRadius24))
    }

    // MARK: - Working

    private func workingHeader(label: String, upNext: String) -> some View {
        HStack(alignment: .top, spacing: .spacing2x) {
            HStack(spacing: .spacing1x) {
                Image(systemName: "play.fill")
                    .font(.standardSFPro(size: .subheading, weight: .medium))
                    .foregroundStyle(Color.defaultBrightPink)

                BrightText(label, size: .standout4)
            }

            Spacer(minLength: .spacing2x)

            VStack(alignment: .trailing, spacing: .spacing0x) {
                BrightText("Up next:", size: .body1, color: .lightTextColor)

                BrightText(upNext, size: .heading)
            }
        }
    }

    private var workingControls: some View {
        HStack(spacing: .spacing105x) {
            BrightRoundButton(
                systemImage: "tag",
                size: .extraLarge,
                imageColor: .defaultOrange,
                onTapCallback: onTag
            )

            BrightRoundButton(
                systemImage: "arrow.counterclockwise",
                size: .extraLarge,
                imageColor: .defaultCyan,
                onTapCallback: onRestart
            )

            Spacer(minLength: .spacing2x)

            BrightRoundButton(
                systemImage: "forward.end.alt",
                size: .extraLarge,
                imageColor: .defaultYellow,
                onTapCallback: onSkip
            )

            BrightRoundButton(
                systemImage: "checkmark",
                size: .extraLarge,
                imageColor: .defaultGreen,
                haptic: .success,
                onTapCallback: onComplete
            )
        }
    }

    // MARK: - Resting

    private func restingHeader(upNext: String, until: Date) -> some View {
        HStack(alignment: .top, spacing: .spacing2x) {
            VStack(alignment: .leading, spacing: .spacing0x) {
                BrightText("Rest", size: .heading)

                BrightText("Up next: \(upNext)", size: .body2, color: .lightTextColor)
            }

            Spacer(minLength: .spacing2x)

            TimelineView(.animation(minimumInterval: Constants.tick, paused: false)) { context in
                let remaining = max(0, until.timeIntervalSince(context.date))

                BrightText(
                    countdown(remaining),
                    size: .standout1,
                    color: remaining <= Constants.urgentRemaining ? .defaultRed : .textColor
                )
                .monospacedDigit()
                .lineLimit(1)
            }
        }
    }

    private var restingControls: some View {
        HStack(spacing: .spacing2x) {
            BrightRoundButton(
                systemImage: "arrow.counterclockwise",
                size: .extraLarge,
                imageColor: .defaultCyan,
                onTapCallback: onRestart
            )

            Spacer(minLength: .spacing2x)

            BrightRoundButton(
                systemImage: "forward.end.alt",
                size: .extraLarge,
                imageColor: .defaultYellow,
                onTapCallback: onSkip
            )
        }
    }

    private func countdown(_ remaining: TimeInterval) -> String {
        let centiseconds = Int(remaining * 100)
        return String(
            format: "%d:%02d:%02d",
            centiseconds / 6000,
            centiseconds / 100 % 60,
            centiseconds % 100
        )
    }

    // MARK: - Complete

    private var completeContent: some View {
        VStack(spacing: .spacing2x) {
            Spacer(minLength: .spacing0x)

            Image(systemName: "checkmark")
                .font(.standardSFPro(size: .standout2, weight: .medium))
                .foregroundStyle(Color.defaultGreen)

            BrightText("ALL SETS COMPLETE", size: .heading)

            Spacer(minLength: .spacing0x)
        }
        .frame(maxWidth: .infinity)
    }

    private enum Constants {
        static let cardHeight: CGFloat = 172
        static let tick: TimeInterval = 0.03
        /// Below this the countdown turns red.
        static let urgentRemaining: TimeInterval = 10
    }
}

#Preview {
    VStack(spacing: .spacing3x) {
        ExerciseLiveSessionStatusWidget(status: .working(label: "Set 2", upNext: "REST"))

        ExerciseLiveSessionStatusWidget(
            status: .resting(upNext: "Set 2", until: Date().addingTimeInterval(269))
        )

        ExerciseLiveSessionStatusWidget(
            status: .resting(upNext: "Set 2", until: Date().addingTimeInterval(5))
        )

        ExerciseLiveSessionStatusWidget(status: .allSetsComplete)
    }
    .padding(.spacing3x)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.defaultSheetBackground.ignoresSafeArea())
}
