//
//  LighthouseModelSelectorView.swift
//  Widgets
//
//  Created by Dom Montalto on 3/9/2026.
//

import SwiftUI

struct LighthouseModelSelectorBackground: View {
    var useThinMaterial: Bool = false

    var body: some View {
        Group {
            if useThinMaterial {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(Color(light: .clear, dark: .black.opacity(.lowOpacity)))
            } else {
                Rectangle()
                    .fill(Color.defaultBackground)
            }
        }
        .ignoresSafeArea()
    }
}

// The model question and the carousel that answers it, shared by the
// onboarding and the selector so a switch later looks like the first choice.
struct LighthouseModelPicker: View {
    @Binding var activeIndex: Int?
    @Binding var selectedTiers: [String: BrightCarouselTier]

    var body: some View {
        VStack(spacing: .spacing0x) {
            VStack(spacing: .spacing1x) {
                BrightText(Constants.title, size: .heading)

                BrightText(Constants.subtitle, size: .body3, color: .lightTextColor)
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

struct LighthouseModelSelectorView: View {
    let currentModel: LighthouseModel
    let onModelSelected: (LighthouseModel) -> Void
    let onDismiss: () -> Void

    @State private var isShowing = false
    @State private var isClosing = false
    @State private var activeIndex: Int?
    @State private var selectedTiers: [String: BrightCarouselTier]

    init(
        currentModel: LighthouseModel = .chatGPT,
        onModelSelected: @escaping (LighthouseModel) -> Void = { _ in },
        onDismiss: @escaping () -> Void = {}
    ) {
        self.currentModel = currentModel
        self.onModelSelected = onModelSelected
        self.onDismiss = onDismiss
        _activeIndex = State(initialValue: LighthouseModel.allCases.firstIndex(of: currentModel) ?? 0)
        _selectedTiers = State(initialValue: LighthouseModelPicker.storedTiers())
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
                .ignoresSafeArea()
                .contentShape(.rect)
                .onTapGesture { close() }

            VStack(spacing: .spacing0x) {
                Color.clear
                    .frame(height: BrightButtonSizes.large.rawValue)

                LighthouseModelPicker(activeIndex: $activeIndex, selectedTiers: $selectedTiers)

                BrightPillButton(Constants.chooseTitle, buttonSize: .large) {
                    LighthouseModelPicker.save(selectedTiers)
                    onModelSelected(LighthouseModelPicker.model(at: activeIndex))
                    close()
                }
                .padding(.bottom, .spacing8x)
            }
            .opacity(isShowing ? 1 : 0)
            .offset(y: isShowing ? 0 : Constants.rise)

            HStack {
                BrightRoundButton(systemImage: "xmark", size: .large) { close() }

                Spacer()
            }
            .padding(.horizontal, .spacing205x)
            .opacity(isShowing ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.brightBouncy) { isShowing = true }
        }
    }

    // Plays the arrival in reverse, then hands over so the host can fade the
    // whole picker away rather than cut to the chat.
    private func close() {
        guard !isClosing else { return }
        isClosing = true
        LighthouseModelPicker.save(selectedTiers)
        withAnimation(.brightEaseInOut) { isShowing = false }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Constants.closeDelay))
            onDismiss()
        }
    }

    private enum Constants {
        static let chooseTitle = "Choose"
        static let rise: CGFloat = 20
        static let closeDelay = 200
    }
}

#Preview {
    ZStack {
        LighthouseModelSelectorBackground()
        LighthouseModelSelectorView()
    }
}
