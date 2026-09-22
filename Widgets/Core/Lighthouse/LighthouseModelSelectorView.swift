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

                BrightPillButton(Constants.chooseTitle, buttonSize: .large, onTapCallback: choose)
                    .padding(.bottom, .spacing8x)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { LighthouseChatBackground() }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
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
    }
}

#Preview {
    LighthouseModelSelectorView()
}
