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

// A Lighthouse answer inside the chat thread: the opening line, each insight
// as its own paragraph, then the choices it wants answered before going on.
struct LighthouseChatResponse: View {
    let text: String
    let items: [LighthouseStoryItem]

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing5x) {
            BrightText(text, size: .body1)
                .lineSpacing(.lineSpacingMedium)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(items) { item in
                BrightText(item.text, size: .body1, color: .lightTextColor)
                    .lineSpacing(.lineSpacingMedium)
                    .multilineTextAlignment(.leading)
            }

            LighthouseChoiceBox(options: LighthouseChoiceBox.demoOptions) { _ in }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// The follow-up Lighthouse asks under an answer: one option to pick, then a
// Submit that hands it back.
struct LighthouseChoiceBox: View {
    let options: [String]
    let onSubmit: (String) -> Void

    @State private var selected: String?

    static let demoOptions = [
        "No consistent workout routine",
        "Following a set weekly schedule with specific days and muscle groups",
        "Flexible with with my routine",
    ]

    var body: some View {
        VStack(spacing: .spacing0x) {
            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                row(option, isLast: index == options.count - 1)
            }

            BrightPillButton(Constants.submitTitle, buttonSize: .small) {
                guard let selected else { return }
                onSubmit(selected)
            }
            .disabled(selected == nil)
            .padding(.bottom, .spacing2x)
        }
        // The rows carry their own vertical padding, so the card adds only a
        // little on top of it.
        .padding(.horizontal, .spacing3x)
        .padding(.vertical, .spacing1x)
        .modifier(CardModifier())
        .animation(.brightSnappy, value: selected)
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

                    BrightTick(isTicked: selected == option)
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
            items: LighthouseDemo.sleepItems
        )
        .padding(.spacing3x)
    }
    .background(Color.defaultBackground)
}
