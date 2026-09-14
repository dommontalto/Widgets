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

    @Environment(\.dismiss) private var dismiss

    @State private var activeIndex: Int?
    @State private var selectedTiers: [String: BrightCarouselTier]

    init(
        currentModel: LighthouseModel = .chatGPT,
        onModelSelected: @escaping (LighthouseModel) -> Void = { _ in }
    ) {
        self.currentModel = currentModel
        self.onModelSelected = onModelSelected
        _activeIndex = State(initialValue: LighthouseModel.allCases.firstIndex(of: currentModel) ?? 0)
        _selectedTiers = State(initialValue: LighthouseModelPicker.storedTiers())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: .spacing0x) {
                LighthouseModelPicker(activeIndex: $activeIndex, selectedTiers: $selectedTiers)

                BrightPillButton(Constants.chooseTitle, buttonSize: .large) {
                    onModelSelected(LighthouseModelPicker.model(at: activeIndex))
                    dismiss()
                }
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
        .onDisappear { LighthouseModelPicker.save(selectedTiers) }
    }

    private enum Constants {
        static let chooseTitle = "Choose"
    }
}

#Preview {
    LighthouseModelSelectorView()
}
