//
//  LighthouseModelSelectorView.swift
//  Widgets
//
//  Created by Dom Montalto on 3/9/2026.
//

import SwiftUI

// Presented as a cover: the model dial with a tier menu under it, and a Choose
// button that hands the pick back. Closing without choosing still keeps any
// tier changes.
struct LighthouseModelSelectorView: View {
    let currentModel: LighthouseModel
    let onModelSelected: (LighthouseModel) -> Void
    let onApiKeySaved: (String) -> Void

    @AppStorage(Constants.speedKey) private var speed = LighthouseSpeed.adaptive

    @Environment(\.dismiss) private var dismiss

    @State private var selection: LighthouseModelChoice
    @State private var selectedTiers: [String: BrightCarouselTier]
    @State private var isEnteringKey = false

    init(
        currentModel: LighthouseModel = .chatGPT,
        onApiKeySaved: @escaping (String) -> Void = { _ in },
        onModelSelected: @escaping (LighthouseModel) -> Void = { _ in }
    ) {
        self.currentModel = currentModel
        self.onApiKeySaved = onApiKeySaved
        self.onModelSelected = onModelSelected
        _selection = State(initialValue: .model(currentModel))
        _selectedTiers = State(initialValue: LighthouseModelPicker.storedTiers())
    }

    var body: some View {
        NavigationStack {
            // The dial runs the full height behind the title and controls, so its
            // rows fade out at the screen's edges rather than being cut off.
            ZStack {
                LighthouseModelWheel(selection: $selection)
                    .ignoresSafeArea()

                controls
            }
            // Floated over the dial on its own, so nothing the controls or the dial do can shift it.
            .overlay(alignment: .top) {
                BrightText(Constants.title, size: .heading)
                    .multilineTextAlignment(.center)
                    .padding(.top, .spacing2x)
                    .padding(.horizontal, .spacing6x)
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // The API key alert's keyboard would otherwise push the whole screen up.
            .ignoresSafeArea(.keyboard)
            .background { LighthouseChatBackground() }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    DebugInlineTitle(file: #file)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.textColor)
                    }
                }
            }
        }
        // The tray's keyboard can still be going down as this opens; left in, the title rides it up and down.
        .ignoresSafeArea(.keyboard)
        .presentationBackground(.clear)
        .lighthouseApiKeyAlert(isPresented: $isEnteringKey) { key in
            onApiKeySaved(key)
            dismiss()
        }
        .onDisappear { LighthouseModelPicker.save(selectedTiers) }
    }

    // Only the controls take touches; the space above them is the dial's.
    private var controls: some View {
        VStack(spacing: .spacing0x) {
            Spacer(minLength: .spacing0x)
                .allowsHitTesting(false)

            tierMenu
                .padding(.bottom, .spacing2x)
                .opacity(selection.model == nil ? .zero : .opaque)
                .allowsHitTesting(selection.model != nil)
                .animation(.brightSnappy, value: selection)

            speedMenu
                .padding(.bottom, .spacing4x)

            BrightPillButton(Constants.chooseTitle, buttonSize: .large, onTapCallback: choose)
                .padding(.bottom, .spacing8x)
        }
    }

    // The tiers of the model on the dial, in the menu the carousel used to carry under each card.
    @ViewBuilder
    private var tierMenu: some View {
        let tiers = selection.model?.tiers ?? []
        let selected = selectedTiers[selection.id]
        Menu {
            ForEach(tiers) { tier in
                Button {
                    selectedTiers[selection.id] = BrightCarouselTier(id: tier.id, name: tier.name, label: tier.label)
                } label: {
                    Label {
                        Text("\(tier.name) — \(tier.label)")
                    } icon: {
                        if tier.id == selected?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: .spacing1x) {
                Text(selected?.name ?? " ")
                    .font(.standard(size: .subheading2, weight: .light))
                    .foregroundStyle(Color.textColor)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.semiLightTextColor)
            }
            .animation(.brightBouncy, value: selected?.id)
            .contentShape(Rectangle())
        }
    }

    private var speedMenu: some View {
        Menu {
            Picker(Constants.speedTitle, selection: $speed) {
                ForEach(LighthouseSpeed.allCases) { speed in
                    Label {
                        Text(speed.title)
                        Text(speed.subtitle)
                    } icon: {
                        Image(systemName: speed.symbol)
                    }
                    .tag(speed)
                }
            }
        } label: {
            HStack(spacing: .spacing1x) {
                Text(speed.title)
                    .font(.standard(size: .subheading2, weight: .light))
                    .foregroundStyle(Color.textColor)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.semiLightTextColor)
            }
            .animation(.brightBouncy, value: speed)
            .contentShape(Rectangle())
        }
        .brightHapticV5(.light, trigger: speed)
    }

    private func choose() {
        guard let model = selection.model else {
            isEnteringKey = true
            return
        }
        onModelSelected(model)
        dismiss()
    }

    private enum Constants {
        static let title = "Which LLM would you like to use?"
        static let chooseTitle = "Choose"
        static let speedTitle = "Speed"
        static let speedKey = "lighthouseSpeed"
    }
}

#Preview {
    LighthouseModelSelectorView()
}
