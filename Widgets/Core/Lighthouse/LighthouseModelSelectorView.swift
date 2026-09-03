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

struct LighthouseModelSelectorView: View {
    var currentModel: LighthouseModel = .chatGPT
    var onModelSelected: (LighthouseModel) -> Void = { _ in }
    var onDismiss: () -> Void = {}
    @State private var isShowing = false
    @State private var isClosing = false
    @State private var activeIndex: Int?
    @State private var selectedTiers: [LighthouseModel: LighthouseModelTier]

    init(
        currentModel: LighthouseModel = .chatGPT,
        onModelSelected: @escaping (LighthouseModel) -> Void = { _ in },
        onDismiss: @escaping () -> Void = {}
    ) {
        self.currentModel = currentModel
        self.onModelSelected = onModelSelected
        self.onDismiss = onDismiss
        _activeIndex = State(initialValue: LighthouseModel.allCases.firstIndex(of: currentModel) ?? 0)

        var tiers: [LighthouseModel: LighthouseModelTier] = [:]
        for model in LighthouseModel.allCases {
            tiers[model] = model.selectedTier()
        }
        _selectedTiers = State(initialValue: tiers)
    }

    private var visibleModel: LighthouseModel {
        guard let index = activeIndex,
              index >= 0, index < LighthouseModel.allCases.count
        else {
            return currentModel
        }
        return LighthouseModel.allCases[index]
    }

    var body: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()
                .contentShape(.rect)
                .onTapGesture {
                    close()
                }

            VStack(spacing: .spacing0x) {
                BrightText("Which LLM would you like to use?", size: .subheading)
                    .opacity(isShowing ? 1 : 0)
                    .offset(y: isShowing ? 0 : Constants.titleRise)
                    .padding(.top, Constants.titleTopPadding)

                Spacer()

                modelCarousel

                BrightPageIndicator(
                    total: LighthouseModel.allCases.count,
                    activeIndex: $activeIndex
                )
                .opacity(isShowing ? 1 : 0)
                .padding(.top, .spacing10x)

                Spacer()
            }

            VStack {
                HStack {
                    BrightRoundButton(systemImage: "xmark", size: .large) {
                        close()
                    }

                    Spacer()

                    BrightRoundButton(systemImage: "checkmark", size: .large, color: .defaultSkyBlue) {
                        onModelSelected(visibleModel)
                        close()
                    }
                }
                .padding(.horizontal, .spacing3x)
                .padding(.top, .spacing1x)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.brightBouncy) {
                isShowing = true
            }
        }
    }

    private var modelCarousel: some View {
        BrightCarousel(
            items: LighthouseModel.allCases,
            activeIndex: $activeIndex,
            tiers: { model in
                model.tiers.map { BrightCarouselTier(id: $0.id, name: $0.name, label: $0.label) }
            },
            selectedTiers: carouselTiers
        ) { model, width in
            Image(model.wallpaperImageName)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: width * Constants.cardAspect)
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius40))
        }
    }

    // Bridges the carousel's presentational tiers to the persisted
    // LighthouseModelTier keyed by model.
    private var carouselTiers: Binding<[String: BrightCarouselTier]> {
        Binding(
            get: {
                selectedTiers.reduce(into: [:]) { dict, entry in
                    dict[entry.key.rawValue] = BrightCarouselTier(
                        id: entry.value.id,
                        name: entry.value.name,
                        label: entry.value.label
                    )
                }
            },
            set: { newValue in
                for (key, tier) in newValue {
                    if let model = LighthouseModel(rawValue: key),
                       let selected = model.tiers.first(where: { $0.id == tier.id }) {
                        selectedTiers[model] = selected
                    }
                }
            }
        )
    }

    private func close() {
        guard !isClosing else { return }
        isClosing = true
        for (model, tier) in selectedTiers {
            model.saveTier(tier)
        }
        onDismiss()
    }

    private enum Constants {
        static let titleTopPadding: CGFloat = 100
        static let titleRise: CGFloat = 20
        static let cardAspect: CGFloat = 1.25
    }
}

#Preview {
    ZStack {
        LighthouseModelSelectorBackground()
        LighthouseModelSelectorView()
    }
}
