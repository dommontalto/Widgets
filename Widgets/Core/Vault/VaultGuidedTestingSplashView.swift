//
//  VaultGuidedTestingSplashView.swift
//  Widgets
//
//  Created by Dom Montalto on 18/9/2026.
//

import SwiftUI

struct VaultGuidedTestingSplashView: View {
    let onFinish: () -> Void

    @State private var page = 0
    @State private var rowWidth: CGFloat = .spacing0x
    @State private var isScrolling = false

    var body: some View {
        VStack(spacing: .spacing0x) {
            hero

            TabView(selection: $page) {
                ForEach(Array(Constants.pages.enumerated()), id: \.offset) { index, copy in
                    pageText(copy)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.defaultBackground.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
    }

    private var hero: some View {
        Color.clear
            .frame(height: Constants.heroHeight)
            .background {
                Image(ImageNames.vaultGuidedTestingBannerV5)
                    .resizable()
                    .scaledToFill()
            }
            .overlay {
                glyphMarquee
            }
            .clipped()
    }

    private var glyphMarquee: some View {
        HStack(spacing: Constants.glyphSpacing) {
            glyphRow
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { width in
                    rowWidth = width
                    isScrolling = width > .spacing0x
                }

            glyphRow
        }
        .fixedSize()
        .foregroundStyle(Color.vaultTestingSplashGlyph)
        .blendMode(.overlay)
        .offset(x: isScrolling ? -(rowWidth + Constants.glyphSpacing) : .spacing0x)
        .animation(
            .linear(duration: Constants.scrollDuration).repeatForever(autoreverses: false),
            value: isScrolling
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var glyphRow: some View {
        HStack(spacing: Constants.glyphSpacing) {
            ForEach(Constants.heroSymbols, id: \.self) { symbol in
                Image(systemName: symbol)
                    .font(.system(size: Constants.heroGlyphSize, weight: .light))
            }
        }
    }

    private func pageText(_ copy: Copy) -> some View {
        VStack(spacing: .spacing2x) {
            BrightText(copy.title, size: .standout1, color: .semiLightTextColor, weight: .regular)

            BrightText(copy.subtitle, size: .body1, color: .lightTextColor)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, .spacing8x)
        .padding(.top, .spacing7x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var footer: some View {
        VStack(spacing: .spacing5x) {
            BrightPageIndicator(total: Constants.pages.count, activeIndex: pageIndicatorIndex)

            BrightPillButton(Constants.getStartedTitle, buttonSize: .large, onTapCallback: onFinish)
        }
        .padding(.bottom, .spacing2x)
    }

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

    private struct Copy {
        let title: String
        let subtitle: String
    }

    private enum Constants {
        static let heroHeight: CGFloat = 427
        static let heroGlyphSize: CGFloat = 60
        static let glyphSpacing: CGFloat = .spacing6x
        static let scrollDuration: TimeInterval = 24
        static let heroSymbols = [
            "blood.pressure.cuff.badge.gauge.with.needle",
            "allergens",
            "heart.text.square",
            "drop.degreesign",
            "bolt.heart",
            "stethoscope",
            "testtube.2",
            "cross.vial",
            "waveform.path.ecg",
            "lungs",
            "microbe",
            "pills",
        ]
        static let getStartedTitle = "Get Started"
        static let pages = [
            Copy(
                title: "Guided Testing",
                subtitle: "Find clinical testing services to complete the full picture of your health."
            ),
            Copy(
                title: "Clinics Near You",
                subtitle: "Browse by category and compare the tests each clinic offers, at home or in person."
            ),
            Copy(
                title: "Results in Your Vault",
                subtitle: "Order a test and your results land in Bright as soon as they're ready."
            ),
        ]
    }
}

#Preview {
    VaultGuidedTestingSplashView {}
}
