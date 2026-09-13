//
//  LighthouseModelPicker.swift
//  Widgets
//
//  Created by Dom Montalto on 10/9/2026.
//

import SwiftUI

// The model question and the carousel that answers it, shared by the
// onboarding and the selector so a switch later looks like the first choice.
struct LighthouseModelPicker: View {
    @Binding var activeIndex: Int?
    @Binding var selectedTiers: [String: BrightCarouselTier]
    // False while the page is off screen, so the cards and their tiers fade in
    // together as it arrives and out again as it goes.
    var isVisible = true

    var body: some View {
        VStack(spacing: .spacing0x) {
            VStack(spacing: .spacing1x) {
                BrightText(Constants.title, size: .heading)

                BrightText(Constants.subtitle, size: .body1, color: .lightTextColor)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, .spacing12x)
            .padding(.horizontal, .spacing6x)

            Spacer(minLength: .spacing0x)

            BrightCarousel(
                items: LighthouseModel.allCases,
                activeIndex: $activeIndex,
                cardWidthRatio: Constants.cardWidthRatio,
                tiers: { model in
                    model.tiers.map { BrightCarouselTier(id: $0.id, name: $0.name, label: $0.label) }
                },
                selectedTiers: $selectedTiers
            ) { model, width in
                Image(model.wallpaperImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: width * Constants.cardAspect)
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius40))
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.brightSnappy, value: isVisible)

            Spacer(minLength: .spacing0x)
            Spacer(minLength: .spacing0x)
        }
    }

    // The tiers the carousel shows, keyed by model id, seeded from what each
    // model last had chosen.
    static func storedTiers() -> [String: BrightCarouselTier] {
        var tiers: [String: BrightCarouselTier] = [:]
        for model in LighthouseModel.allCases {
            let tier = model.selectedTier()
            tiers[model.id] = BrightCarouselTier(id: tier.id, name: tier.name, label: tier.label)
        }
        return tiers
    }

    static func save(_ tiers: [String: BrightCarouselTier]) {
        for model in LighthouseModel.allCases {
            if let tier = tiers[model.id],
               let match = model.tiers.first(where: { $0.id == tier.id }) {
                model.saveTier(match)
            }
        }
    }

    static func model(at index: Int?) -> LighthouseModel {
        let models = LighthouseModel.allCases
        return models[min(max(index ?? 0, 0), models.count - 1)]
    }

    private enum Constants {
        static let title = "Which LLM would you like to use?"
        static let subtitle = "You can change your LLM later in lighthouse settings"
        static let cardWidthRatio: CGFloat = 0.46
        static let cardAspect: CGFloat = 1.25
    }
}
