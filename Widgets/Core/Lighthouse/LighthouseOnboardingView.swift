//
//  LighthouseOnboardingView.swift
//  Widgets
//
//  Created by Dom Montalto on 10/9/2026.
//

import SwiftUI

// The first run of Lighthouse: the beacon and a welcome, what it can do, then
// the model to run it on. Pages turn by swipe or by the button underneath.
struct LighthouseOnboardingView: View {
    @Binding var selectedModel: LighthouseModel
    let onFinish: () -> Void

    @State private var page = 0
    @State private var carouselIndex: Int?
    @State private var selectedTiers: [String: BrightCarouselTier]
    @State private var revealedCapabilities = 0
    // Rows whose text has finished drifting into place; the icon bows only
    // once its row has settled.
    @State private var settledCapabilities = 0

    init(selectedModel: Binding<LighthouseModel>, onFinish: @escaping () -> Void) {
        _selectedModel = selectedModel
        self.onFinish = onFinish
        _carouselIndex = State(initialValue: LighthouseModel.allCases.firstIndex(of: selectedModel.wrappedValue) ?? 0)
        _selectedTiers = State(initialValue: LighthouseModelPicker.storedTiers())
    }

    private var isLastPage: Bool {
        page == Constants.pageCount - 1
    }

    var body: some View {
        VStack(spacing: .spacing0x) {
            TabView(selection: $page) {
                welcome
                    .tag(0)

                capabilities
                    .tag(1)

                modelPicker
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            // In the bar beside the close button, so the second page's title
            // reads as the screen's own.
            ToolbarItem(placement: .principal) {
                BrightText(Constants.capabilitiesTitle, size: .heading, color: .semiLightTextColor)
                    .opacity(page == 1 ? 1 : 0)
                    .animation(.brightEaseInOut, value: page)
            }
        }
    }

    // MARK: - Pages

    private var welcome: some View {
        VStack(spacing: .spacing2x) {
            Spacer(minLength: .spacing0x)

            LighthouseBeacon(size: Constants.beaconSize)
                .padding(.bottom, .spacing2x)

            BrightText(Constants.welcomeTitle, size: .standout1, color: .semiLightTextColor)

            BrightText(Constants.welcomeSubtitle, size: .body1, color: .semiLightTextColor)
                .multilineTextAlignment(.center)

            Spacer(minLength: .spacing0x)
            Spacer(minLength: .spacing0x)
        }
        .padding(.horizontal, .spacing6x)
    }

    private var capabilities: some View {
        VStack(alignment: .leading, spacing: .spacing8x) {
            ForEach(Array(Constants.capabilities.enumerated()), id: \.element.id) { index, capability in
                capabilityRow(
                    capability,
                    isRevealed: index < revealedCapabilities,
                    hasSettled: index < settledCapabilities
                )
            }

            Spacer(minLength: .spacing0x)
        }
        .padding(.top, .spacing8x)
        .padding(.horizontal, .spacing5x)
        .task(id: page) { await revealCapabilities() }
    }

    // Each row is always in the tree and condenses into place when its turn
    // comes: rising, sharpening from a blur and swelling to size, with the
    // icon taking a bow as it lands. Animating the rows themselves rather
    // than inserting them keeps it working inside the paged tab view.
    private func capabilityRow(_ capability: Capability, isRevealed: Bool, hasSettled: Bool) -> some View {
        HStack(alignment: .top, spacing: .spacing4x) {
            Image(systemName: capability.symbol)
                .font(.standard(size: .standout1, weight: .light))
                .foregroundStyle(capability.color)
                .frame(width: BrightButtonSizes.large.rawValue, height: BrightButtonSizes.large.rawValue)
                .symbolEffect(.bounce, value: hasSettled)

            VStack(alignment: .leading, spacing: .spacing1x) {
                BrightText(capability.title, size: .subheading, weight: .regular)

                BrightText(capability.detail, size: .body1, color: .lightTextColor)
                    .lineSpacing(.lineSpacingMedium)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .opacity(isRevealed ? 1 : 0)
        .blur(radius: isRevealed ? 0 : Constants.capabilityBlur)
        .scaleEffect(isRevealed ? 1 : Constants.capabilityStartScale, anchor: .leading)
        .offset(y: isRevealed ? 0 : Constants.capabilityRise)
        .animation(.brightChartReveal, value: isRevealed)
    }

    private var modelPicker: some View {
        LighthouseModelPicker(activeIndex: $carouselIndex, selectedTiers: $selectedTiers, isVisible: isLastPage)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: .spacing5x) {
            BrightPageIndicator(total: Constants.pageCount, activeIndex: pageIndicatorIndex)
                .opacity(isLastPage ? 0 : 1)
                .animation(.brightEaseInOut, value: isLastPage)

            BrightPillButton(buttonTitle, buttonSize: .large, onTapCallback: advance)
                .animation(.brightEaseInOut, value: page)
        }
        .padding(.bottom, .spacing2x)
    }

    private var buttonTitle: String {
        switch page {
        case 0: Constants.nextTitle
        case 1: Constants.getStartedTitle
        default: Constants.chooseTitle
        }
    }

    // The indicator wants an optional it can clear; the flow always has a page.
    private var pageIndicatorIndex: Binding<Int?> {
        Binding(
            get: { page },
            set: { newValue in
                if let newValue {
                    withAnimation(.brightEaseInOut) { page = newValue }
                }
            }
        )
    }

    // The rows land one after another as the page arrives, and clear
    // off-screen so they do it again next time.
    private func revealCapabilities() async {
        revealedCapabilities = 0
        settledCapabilities = 0
        guard page == 1 else { return }
        for _ in Constants.capabilities {
            do {
                try await Task.sleep(for: .seconds(Constants.capabilityRevealEvery))
            } catch {
                return
            }
            revealedCapabilities += 1
            Task {
                try? await Task.sleep(for: .seconds(Constants.capabilitySettleAfter))
                guard page == 1 else { return }
                settledCapabilities += 1
            }
        }
    }

    private func advance() {
        guard isLastPage else {
            withAnimation(.brightEaseInOut) { page += 1 }
            return
        }
        LighthouseModelPicker.save(selectedTiers)
        selectedModel = LighthouseModelPicker.model(at: carouselIndex)
        onFinish()
    }

    private struct Capability: Identifiable {
        let symbol: String
        let title: String
        let detail: String
        let color: Color

        var id: String { title }
    }

    private enum Constants {
        static let pageCount = 3
        static let beaconSize: CGFloat = 176
        static let welcomeTitle = "Lighthouse"
        static let welcomeSubtitle = "Welcome to your personal health coach."
        static let capabilitiesTitle = "What Lighthouse can do"
        static let nextTitle = "Next"
        static let getStartedTitle = "Get Started"
        static let chooseTitle = "Choose"
        static let capabilityRevealEvery: TimeInterval = 1
        // Matches the row's chart-reveal ease, so the bow lands as the text does.
        static let capabilitySettleAfter: TimeInterval = 1.1
        static let capabilityBlur: CGFloat = 12
        static let capabilityStartScale: CGFloat = 0.92
        static let capabilityRise: CGFloat = .spacing3x

        static let capabilityDetail = "Reminders daily, weekly or monthly to keep you on track with your goals"
        static let capabilities = [
            Capability(
                symbol: "person.fill.checkmark.and.xmark",
                title: "Create checkins",
                detail: capabilityDetail,
                color: .defaultCyan
            ),
            Capability(
                symbol: "graph.3d",
                title: "Trend Analysis",
                detail: capabilityDetail,
                color: .defaultYellow
            ),
            Capability(
                symbol: "figure.run.square.stack.fill",
                title: "Custom Programs",
                detail: capabilityDetail,
                color: .defaultPink
            ),
            Capability(
                symbol: "fork.knife",
                title: "Log Food",
                detail: capabilityDetail,
                color: .defaultOrange
            ),
        ]
    }
}

#Preview {
    @Previewable @State var model = LighthouseModel.chatGPT

    NavigationStack {
        LighthouseOnboardingView(selectedModel: $model) {}
            .background { LighthouseChatBackground() }
    }
}
