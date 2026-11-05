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
    // The logo it was opened from, in screen space: a copy flies from there to the dial's middle row.
    var sourceFrame: CGRect?
    let onModelSelected: (LighthouseModel) -> Void
    let onApiKeySaved: (String) -> Void
    // Called as the logo lands back where it came from, just before the selector goes.
    var onReturned: () -> Void = {}

    @AppStorage(Constants.speedKey) private var speed = LighthouseSpeed.adaptive

    @Environment(\.dismiss) private var dismiss

    @State private var selection: LighthouseModelChoice
    @State private var selectedTiers: [String: BrightCarouselTier]
    @State private var isEnteringKey = false
    @State private var isShowing = false
    @State private var hasLanded = false
    @State private var showsContent = false
    @State private var showsCopy = true
    @State private var glow: Double = .zero
    @State private var isClosing = false

    init(
        currentModel: LighthouseModel = .chatGPT,
        sourceFrame: CGRect? = nil,
        onReturned: @escaping () -> Void = {},
        onApiKeySaved: @escaping (String) -> Void = { _ in },
        onModelSelected: @escaping (LighthouseModel) -> Void = { _ in }
    ) {
        self.currentModel = currentModel
        self.sourceFrame = sourceFrame
        self.onReturned = onReturned
        self.onApiKeySaved = onApiKeySaved
        self.onModelSelected = onModelSelected
        _selection = State(initialValue: .model(currentModel))
        _selectedTiers = State(initialValue: LighthouseModelPicker.storedTiers())
    }

    var body: some View {
        ZStack {
            veil
            selector
                .opacity(showsContent ? .opaque : .zero)
            if showsCopy, let sourceFrame {
                flyingLogo(from: sourceFrame)
            }
        }
        .ignoresSafeArea(.keyboard)
        .presentationBackground(.clear)
        .lighthouseApiKeyAlert(isPresented: $isEnteringKey) { key in
            onApiKeySaved(key)
            close()
        }
        .onAppear(perform: enter)
        .onDisappear { LighthouseModelPicker.save(selectedTiers) }
    }

    // The plus menu's frosted, dimmed layer.
    private var veil: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay { Color.defaultOverlayDim }
            .ignoresSafeArea()
            .opacity(isShowing ? .opaque : .zero)
    }

    private func flyingLogo(from source: CGRect) -> some View {
        GeometryReader { proxy in
            let landing = CGPoint(
                x: proxy.size.width - LighthouseModelWheel.selectedLogoTrailing,
                y: proxy.size.height / 2
            )
            let size = hasLanded ? LighthouseModelWheel.selectedLogoSize : source.width
            Image(currentModel.tierImageName)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .modifier(LighthouseModelGlow(color: currentModel.tint, amount: isClosing ? glow : .zero))
                .position(hasLanded ? landing : CGPoint(x: source.midX, y: source.midY))
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var selector: some View {
        NavigationStack {
            // The dial runs the full height behind the controls, so its
            // rows fade out at the screen's edges rather than being cut off.
            ZStack {
                LighthouseModelWheel(selection: $selection, slidesIn: sourceFrame == nil, glow: glow)
                    .overlay(alignment: .leading) {
                        tierMenu
                            .padding(.leading, .spacing5x)
                            .opacity(selection.model == nil ? .zero : .opaque)
                            .allowsHitTesting(selection.model != nil)
                            .animation(.brightSnappy, value: selection)
                    }
                    .ignoresSafeArea()

                controls
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // The API key alert's keyboard would otherwise push the whole screen up.
            .ignoresSafeArea(.keyboard)
            .containerBackground(.clear, for: .navigation)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    DebugInlineTitle(file: #file)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        choose()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.textColor)
                    }
                }
            }
        }
    }

    // The veil fades up as the copy of the logo flies to the dial's middle row; the dial and controls then fade in under it, and the copy goes once they're there.
    private func enter() {
        withAnimation(.easeIn(duration: Constants.fadeDuration)) { isShowing = true }
        guard sourceFrame != nil else {
            showsCopy = false
            withAnimation(.easeIn(duration: Constants.fadeDuration)) { showsContent = true }
            return
        }
        withAnimation(.brightSpring) {
            hasLanded = true
        } completion: {
            withAnimation(.brightEaseInOut) {
                showsContent = true
                glow = .opaque
            } completion: {
                showsCopy = false
                withAnimation(.easeOut(duration: Constants.glowFadeDuration).delay(Constants.glowHold)) { glow = .zero }
            }
        }
    }

    // The entrance run backwards: the logo lights up on the dial, the dial fades away, then the logo flies home
    // still lit as the veil lifts, and the real logo takes the glow over. `currentModel` is the chosen model by now, so that's the logo that lands.
    private func close() {
        guard !isClosing else { return }
        isClosing = true
        guard sourceFrame != nil else {
            withAnimation(.easeOut(duration: Constants.fadeDuration)) {
                isShowing = false
                showsContent = false
            } completion: {
                dismissInstantly()
            }
            return
        }
        hasLanded = true
        showsCopy = true
        withAnimation(.brightEaseInOut) {
            glow = .opaque
            showsContent = false
        } completion: {
            withAnimation(.easeOut(duration: Constants.fadeDuration)) {
                isShowing = false
            }
            // Waits for the spring to come fully to rest on the logo, not just to look done, so the hand-over doesn't jump.
            withAnimation(.brightSpring, completionCriteria: .removed) {
                hasLanded = false
            } completion: {
                onReturned()
                dismissInstantly()
            }
        }
    }

    private func dismissInstantly() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { dismiss() }
    }

    // Only the controls take touches; the space above them is the dial's.
    private var controls: some View {
        VStack(spacing: .spacing0x) {
            Spacer(minLength: .spacing0x)
                .allowsHitTesting(false)

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
                BrightText(selected?.name ?? " ", size: .subheading2)
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
                BrightText(speed.title, size: .subheading2)
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
        close()
    }

    private enum Constants {
        static let chooseTitle = "Choose"
        static let speedTitle = "Speed"
        static let speedKey = "lighthouseSpeed"
        static let fadeDuration: TimeInterval = 0.25
        static let glowHold: TimeInterval = 2
        static let glowFadeDuration: TimeInterval = 1
    }
}

#Preview {
    LighthouseModelSelectorView()
}
