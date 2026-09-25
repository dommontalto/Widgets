//
//  LighthouseChatResponse.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

nonisolated struct LighthouseStoryItem: Identifiable, Equatable {
    let id = UUID()
    let text: String
}

nonisolated struct LighthouseResponsePayload: Equatable {
    var items: [LighthouseStoryItem] = []
    var checkIn: LighthouseCheckInReview?
    // Marks the thought-process row that sits above an answer; its seconds
    // stay nil while the answer is still being worked out.
    var isThoughtProcess = false
    var thoughtSeconds: Int?
}

nonisolated struct LighthouseCheckInReview: Equatable {
    nonisolated struct Finding: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let detail: String
        let isOnTrack: Bool
    }

    nonisolated struct Section: Identifiable, Equatable {
        nonisolated enum Kind: Equatable {
            case workouts
            case nutrition
            case sleep

            var title: String {
                switch self {
                case .workouts: "Workouts"
                case .nutrition: "Nutrition"
                case .sleep: "Sleep"
                }
            }

            var symbol: String {
                switch self {
                case .workouts: "figure.climbing"
                case .nutrition: "fork.knife"
                case .sleep: "bed.double.fill"
                }
            }
        }

        let id = UUID()
        let kind: Kind
        let findings: [Finding]
    }

    let title: String
    let summary: String
    let sections: [Section]
    let followUps: [String]
}

// A Lighthouse answer inside the chat thread: the opening line, each insight
// as its own paragraph, then the choices it wants answered before going on.
struct LighthouseChatResponse: View {
    let text: String
    let items: [LighthouseStoryItem]
    var checkIn: LighthouseCheckInReview?
    var date: Date = .now
    // Sends the picked choice back into the thread as the next message.
    let onSubmit: (String) -> Void

    @State private var rating: Rating?
    @State private var tappedRating: Rating?
    @State private var isCopied = false
    @State private var shareTaps = 0

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing5x) {
            if let checkIn {
                LighthouseCheckInReviewView(review: checkIn)
            } else {
                BrightText(text, size: .body1)
                    .lineSpacing(.lineSpacingMedium)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(items) { item in
                    BrightText(item.text, size: .body1, color: .lightTextColor)
                        .lineSpacing(.lineSpacingMedium)
                        .multilineTextAlignment(.leading)
                }
            }

            actions

            VStack(alignment: .leading, spacing: .spacing2x) {
                if checkIn != nil {
                    BrightText(Constants.followUpTitle, size: .body1, color: .semiLightTextColor)
                }

                LighthouseChoiceBox(options: checkIn?.followUps ?? LighthouseDemo.followUpOptions, onSubmit: onSubmit)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var fullText: String {
        guard let checkIn else {
            return ([text] + items.map(\.text)).joined(separator: "\n\n")
        }
        let sections = checkIn.sections.map { section in
            ([section.kind.title] + section.findings.map(\.text)).joined(separator: "\n")
        }
        return ([checkIn.summary] + sections).joined(separator: "\n\n")
    }

    private var actions: some View {
        HStack(spacing: .spacing3x) {
            ratingButton(.up)
            ratingButton(.down)

            Button {
                UIPasteboard.general.string = fullText
                isCopied = true
            } label: {
                actionIcon(isCopied ? "checkmark.circle" : "doc.on.doc")
                    .contentTransition(.symbolEffect(.replace))
            }
            .brightHaptic(.success, trigger: isCopied) { _, copied in copied }
            .task(id: isCopied) {
                guard isCopied else { return }
                try? await Task.sleep(for: .seconds(Constants.copiedDuration))
                isCopied = false
            }

            ShareLink(item: fullText) {
                actionIcon("square.and.arrow.up")
            }
            .simultaneousGesture(TapGesture().onEnded { shareTaps += 1 })
            .brightHaptic(.light, trigger: shareTaps)

            Spacer(minLength: .spacing0x)

            BrightText(date.formatted(.brightTime), size: .body1, color: .lightTextColor)
        }
        .buttonStyle(.plain)
        .brightHaptic(.light, trigger: rating)
    }

    private func ratingButton(_ value: Rating) -> some View {
        Button {
            tappedRating = value
            rating = rating == value ? nil : value
        } label: {
            actionIcon(rating == value ? "\(value.symbol).fill" : value.symbol)
                .contentTransition(tappedRating == value ? .symbolEffect(.replace) : .identity)
        }
    }

    private func actionIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.standardSFPro(size: .body1, weight: .light))
            .foregroundStyle(Color.lightTextColor)
            .frame(width: Constants.iconSize, height: Constants.iconSize)
            .contentShape(Rectangle())
    }

    private enum Constants {
        static let followUpTitle = "Choose a follow up below"
        static let copiedDuration: Double = 2
        static let iconSize: CGFloat = .spacing4x
    }

    private enum Rating {
        case up
        case down

        var symbol: String {
            switch self {
            case .up: "hand.thumbsup"
            case .down: "hand.thumbsdown"
            }
        }
    }
}

// The follow-up Lighthouse asks under an answer: one option to pick, then a
// Submit that hands it back.
struct LighthouseChoiceBox: View {
    let options: [String]
    let onSubmit: (String) -> Void

    @State private var selected: String?
    @State private var isSubmitted = false

    var body: some View {
        VStack(spacing: .spacing0x) {
            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                row(option, isLast: index == options.count - 1)
            }

            // Faded until there's something to send.
            BrightPillButton(Constants.submitTitle, isSelected: selected != nil && !isSubmitted) {
                guard let selected else { return }
                isSubmitted = true
                onSubmit(selected)
            }
            .disabled(selected == nil || isSubmitted)
            .padding(.top, .spacing2x)
        }
        .opacity(isSubmitted ? .lowOpacity : 1)
        .disabled(isSubmitted)
        .animation(.brightSnappy, value: selected)
        .animation(.brightSnappy, value: isSubmitted)
    }

    private func row(_ option: String, isLast: Bool) -> some View {
        Button {
            // Tapping the picked one again clears it.
            selected = selected == option ? nil : option
        } label: {
            VStack(spacing: .spacing0x) {
                HStack(alignment: .center, spacing: .spacing2x) {
                    BrightText(option, size: .body1, color: .semiLightTextColor)
                        .lineSpacing(.lineSpacingMedium)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: .spacing2x)

                    BrightTick(isTicked: selected == option, tickTint: isSubmitted ? .lightTextColor : .defaultGreen)
                }
                .padding(.vertical, .spacing2x)

                if !isLast {
                    BrightDivider()
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private enum Constants {
        static let submitTitle = "Submit"
    }
}

#Preview {
    ScrollView {
        LighthouseChatResponse(
            text: LighthouseDemo.sleepPartOne,
            items: LighthouseDemo.sleepItems,
            onSubmit: { _ in }
        )
        .padding(.spacing3x)
    }
    .background(Color.defaultBackground)
}
