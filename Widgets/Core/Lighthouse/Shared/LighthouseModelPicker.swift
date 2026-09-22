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
            BrightText(Constants.title, size: .heading)
                .padding(.top, .spacing12x)
                .padding(.horizontal, .spacing6x)

            Spacer(minLength: .spacing0x)

            BrightCarousel(
                items: LighthouseModelChoice.allCases,
                activeIndex: $activeIndex,
                cardWidthRatio: Constants.cardWidthRatio,
                tiers: { choice in
                    choice.model?.tiers.map { BrightCarouselTier(id: $0.id, name: $0.name, label: $0.label) } ?? []
                },
                selectedTiers: $selectedTiers
            ) { choice, width in
                card(for: choice, width: width)
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.brightSnappy, value: isVisible)

            Spacer(minLength: .spacing0x)
            Spacer(minLength: .spacing0x)
        }
    }

    @ViewBuilder
    private func card(for choice: LighthouseModelChoice, width: CGFloat) -> some View {
        if let model = choice.model {
            Image(model.wallpaperImageName)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: width * Constants.cardAspect)
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius40))
        } else {
            LighthouseApiKeyCard(width: width, height: width * Constants.cardAspect)
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

    static func choice(at index: Int?) -> LighthouseModelChoice {
        let choices = LighthouseModelChoice.allCases
        return choices[min(max(index ?? 0, 0), choices.count - 1)]
    }

    static func model(at index: Int?) -> LighthouseModel {
        choice(at: index).model ?? .chatGPT
    }

    static func index(of model: LighthouseModel) -> Int {
        LighthouseModelChoice.allCases.firstIndex { $0.model == model } ?? 0
    }

    private enum Constants {
        static let title = "Which LLM would you like to use?"
        static let cardWidthRatio: CGFloat = 0.46
        static let cardAspect: CGFloat = 1.25
    }
}

// The card that takes a key instead of a model: the same shape as the model
// wallpapers, glass where they carry artwork.
struct LighthouseApiKeyCard: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        VStack(spacing: .spacing3x) {
            Image(systemName: LighthouseModelChoice.apiKeySymbol)
                .font(.system(size: Constants.glyphSize, weight: .light))
                .foregroundStyle(Color.textColor)

            BrightText(Constants.title, size: .body1, weight: .regular)
        }
        .frame(width: width, height: height)
        .modifier(GlassEffect(shape: .roundedRect, cornerRadius: .cornerRadius40))
    }

    private enum Constants {
        static let title = "Use your API key"
        static let glyphSize: CGFloat = 36
    }
}

struct LighthouseApiKeyGlyph: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: LighthouseModelChoice.apiKeySymbol)
            .font(.system(size: size * Constants.glyphRatio, weight: .light))
            .foregroundStyle(Color.textColor)
            .frame(width: size, height: size)
            .modifier(GlassEffect(shape: .roundedRect, cornerRadius: size * Constants.cornerRatio))
    }

    private enum Constants {
        static let glyphRatio: CGFloat = 0.5
        static let cornerRatio: CGFloat = 0.24
    }
}
