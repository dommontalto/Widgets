//
//  LighthouseModelSelectorView.swift
//  Widgets
//
//  Created by Dom Montalto on 3/9/2026.
//

import SwiftUI

// Presented as a cover: the model carousel with its tier menus, and a Choose
// button that hands the pick back. Closing without choosing still keeps any
// tier changes.
struct LighthouseModelSelectorView: View {
    let currentModel: LighthouseModel
    let onModelSelected: (LighthouseModel) -> Void
    let onApiKeySaved: (String) -> Void

    @AppStorage(Constants.speedKey) private var speed = LighthouseSpeed.adaptive

    @Environment(\.dismiss) private var dismiss

    @State private var activeIndex: Int?
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
        _activeIndex = State(initialValue: LighthouseModelPicker.index(of: currentModel))
        _selectedTiers = State(initialValue: LighthouseModelPicker.storedTiers())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: .spacing0x) {
                LighthouseModelPicker(activeIndex: $activeIndex, selectedTiers: $selectedTiers)

                speedMenu
                    .padding(.bottom, .spacing4x)

                BrightPillButton(Constants.chooseTitle, buttonSize: .large, onTapCallback: choose)
                    .padding(.bottom, .spacing8x)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .presentationBackground(.clear)
        .lighthouseApiKeyAlert(isPresented: $isEnteringKey) { key in
            onApiKeySaved(key)
            dismiss()
        }
        .onDisappear { LighthouseModelPicker.save(selectedTiers) }
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
        guard let model = LighthouseModelPicker.choice(at: activeIndex).model else {
            isEnteringKey = true
            return
        }
        onModelSelected(model)
        dismiss()
    }

    private enum Constants {
        static let chooseTitle = "Choose"
        static let speedTitle = "Speed"
        static let speedKey = "lighthouseSpeed"
    }
}

#Preview {
    LighthouseModelSelectorView()
}
