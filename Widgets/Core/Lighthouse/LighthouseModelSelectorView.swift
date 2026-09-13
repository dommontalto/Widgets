//
//  LighthouseModelSelectorView.swift
//  Widgets
//
//  Created by Dom Montalto on 3/9/2026.
//

import SwiftUI

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
