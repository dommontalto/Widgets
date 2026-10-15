//
//  BrightWhatsNewSheetV5.swift
//  Widgets
//

import SwiftUI

struct BrightWhatsNewSheetV5: View {
    @State private var heroRisen = false
    @State private var heroSettled = false
    @State private var heroTitleShown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        BrightPageSheetViewV5(horizontalPadding: .spacing0x) {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing0x) {
                    hero

                    BrightText("What’s new.", size: .standout1, color: .semiLightTextColor, weight: .regular)
                        .whatsNewReveal { content, hidden in
                            content
                                .opacity(1 - hidden)
                                .scaleEffect(1 - hidden * Constants.titlePop, anchor: .leading)
                                .blur(radius: hidden * Constants.revealBlur)
                        }
                        .padding(.top, .spacing6x)
                        .padding(.horizontal, .spacing5x)

                    VStack(alignment: .leading, spacing: .spacing10x) {
                        ForEach(WhatsNewFeature.all) { feature in
                            WhatsNewFeatureSection(feature: feature)
                        }
                    }
                    .padding(.top, .spacing8x)

                    more
                        .padding(.top, .spacing10x)
                }
                .padding(.bottom, .spacing10x)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var hero: some View {
        ZStack(alignment: .top) {
            Image(ImageNames.whatsNewHeroV5)
                .resizable()
                .scaledToFit()
                .scaleEffect(heroSettled ? 1 : (heroRisen ? Constants.heroOvershootScale : Constants.heroStartScale), anchor: .bottom)
                .rotationEffect(.degrees(heroSettled ? 0 : (heroRisen ? Constants.heroOvershootAngle : Constants.heroStartAngle)), anchor: .bottomTrailing)
                .offset(y: heroSettled ? 0 : (heroRisen ? -Constants.heroOvershoot : Constants.heroStartOffset))
                .clipped()

            BrightText("Welcome to V5.", size: .huge, color: .white, weight: .regular)
                .opacity(heroTitleShown ? 1 : 0)
                .blur(radius: heroTitleShown ? 0 : Constants.revealBlur)
                .offset(y: heroTitleShown ? 0 : Constants.textRise)
                .padding(.top, Constants.heroTitleTop)
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .bottom) {
            Color.defaultBlack
                .padding(.top, -Constants.heroOverscroll)
        }
        .onAppear(perform: playHero)
    }

    private func playHero() {
        guard !heroRisen else { return }
        guard !reduceMotion else {
            heroRisen = true
            heroSettled = true
            heroTitleShown = true
            return
        }
        withAnimation(.smooth(duration: Constants.heroRiseDuration)) {
            heroRisen = true
        } completion: {
            withAnimation(.spring(duration: Constants.heroSettleDuration, bounce: Constants.heroSettleBounce)) {
                heroSettled = true
            }
        }
        withAnimation(.smooth(duration: Constants.revealDuration).delay(Constants.heroTitleDelay)) {
            heroTitleShown = true
        }
    }

    private var more: some View {
        VStack(alignment: .leading, spacing: .spacing5x) {
            BrightText("and more.", size: .standout1, color: .semiLightTextColor, weight: .regular)
                .whatsNewReveal { content, hidden in
                    content
                        .opacity(1 - hidden)
                        .scaleEffect(1 - hidden * Constants.titlePop, anchor: .leading)
                        .blur(radius: hidden * Constants.revealBlur)
                }

            Grid(alignment: .topLeading, horizontalSpacing: .spacing3x, verticalSpacing: .spacing5x) {
                ForEach(Array(stride(from: 0, to: WhatsNewMoreItem.all.count, by: 2)), id: \.self) { start in
                    GridRow {
                        ForEach(WhatsNewMoreItem.all[start ..< min(start + 2, WhatsNewMoreItem.all.count)]) { item in
                            WhatsNewMoreItemView(item: item, isLeading: item.id == WhatsNewMoreItem.all[start].id)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, .spacing5x)
    }

    fileprivate enum Constants {
        static let heroTitleTop: CGFloat = .spacing3x
        static let heroOverscroll: CGFloat = 2000
        static let heroStartOffset: CGFloat = .spacing12x * 6
        static let heroOvershoot: CGFloat = .spacing2x
        static let heroStartAngle: Double = 12
        static let heroOvershootAngle: Double = -2
        static let heroStartScale: CGFloat = 0.9
        static let heroOvershootScale: CGFloat = 1.02
        static let heroRiseDuration: Double = 1.8
        static let heroSettleDuration: Double = 1.2
        static let heroSettleBounce: Double = 0.35
        static let heroTitleDelay: Double = 0.9
        static let carouselCardWidth: CGFloat = 284
        static let imageCornerRadius: CGFloat = 40
        static let moreIconSize: CGFloat = 22
        static let revealDuration: Double = 1.4
        static let revealThreshold: Double = 0.4
        static let revealLock: Duration = .seconds(2.5)
        static let revealStagger: Double = 0.25
        static let revealBlur: CGFloat = 8
        static let textRise: CGFloat = .spacing4x
        static let imageRise: CGFloat = .spacing10x
        static let imageShrink: CGFloat = 0.12
        static let carouselSlide: CGFloat = .spacing12x
        static let itemSlide: CGFloat = .spacing6x
        static let titlePop: CGFloat = 0.15
        static let glowRadius: CGFloat = .spacing2x
        static let glowIn: Double = 1.0
        static let glowHold: Double = 1.6
        static let glowOut: Double = 2.4
    }
}

private struct WhatsNewFeatureSection: View {
    let feature: WhatsNewFeature

    private typealias Constants = BrightWhatsNewSheetV5.Constants

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            VStack(alignment: .leading, spacing: .spacing2x) {
                BrightText(feature.title, size: .heading, color: .semiLightTextColor, weight: .regular)
                    .whatsNewReveal { content, hidden in
                        content
                            .opacity(1 - hidden)
                            .offset(x: -hidden * Constants.itemSlide)
                            .blur(radius: hidden * Constants.revealBlur)
                    }
                BrightText(feature.detail, size: .body1, color: .lightTextColor, weight: .regular)
                    .fixedSize(horizontal: false, vertical: true)
                    .whatsNewReveal(delay: Constants.revealStagger) { content, hidden in
                        content
                            .opacity(1 - hidden)
                            .offset(y: hidden * Constants.textRise)
                            .blur(radius: hidden * Constants.revealBlur)
                    }
            }
            .padding(.horizontal, .spacing5x)

            media
                .padding(.top, .spacing5x)
        }
    }

    @ViewBuilder
    private var media: some View {
        switch feature.media {
        case .stack(let images):
            VStack(spacing: .spacing3x) {
                ForEach(images, id: \.self) { image in
                    WhatsNewImage(name: image)
                        .whatsNewReveal { content, hidden in
                            content
                                .opacity(1 - hidden)
                                .scaleEffect(1 - hidden * Constants.imageShrink)
                                .offset(y: hidden * Constants.imageRise)
                        }
                }
            }
            .padding(.horizontal, .spacing5x)
        case .carousel(let images):
            WhatsNewCarousel(images: images)
                .whatsNewReveal { content, hidden in
                    content
                        .opacity(1 - hidden)
                        .offset(x: hidden * Constants.carouselSlide)
                }
        }
    }
}

private struct WhatsNewImage: View {
    let name: String

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .clipShape(.rect(cornerRadius: BrightWhatsNewSheetV5.Constants.imageCornerRadius))
    }
}

private struct WhatsNewCarousel: View {
    let images: [String]

    @State private var page: Int? = 0

    var body: some View {
        VStack(spacing: .spacing3x) {
            ScrollView(.horizontal) {
                HStack(spacing: .spacing2x) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                        WhatsNewImage(name: image)
                            .frame(width: BrightWhatsNewSheetV5.Constants.carouselCardWidth)
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, .spacing5x, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $page)
            .scrollIndicators(.hidden)

            BrightPageIndicatorV5(total: images.count, activeIndex: $page)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct WhatsNewFeature: Identifiable {
    enum Media {
        case stack([String])
        case carousel([String])
    }

    let id = UUID()
    let title: String
    let detail: String
    let media: Media

    static let all: [Self] = [
        .init(
            title: "Lighthouse",
            detail: "We’ve created a LLM layer that can read any part of the app. Users can choose a LLM from leading frontier-models or choose to use their own LLM token.",
            media: .stack([ImageNames.whatsNewLighthouseChatV5, ImageNames.whatsNewLighthouseModelsV5])
        ),
        .init(
            title: "Waypoint",
            detail: "Create programs to reach short and long term health goals and Bright will systematically adjust each widget to help you along the way.",
            media: .carousel([ImageNames.whatsNewWaypointOnTrackV5, ImageNames.whatsNewWaypointOffCourseV5])
        ),
        .init(
            title: "Vault",
            detail: "This brings together all the foundations of your health for you to review and share with anyone via a URL.",
            media: .carousel([ImageNames.whatsNewVaultGenomeV5, ImageNames.whatsNewVaultDatapointsV5])
        ),
        .init(
            title: "Guided Testing",
            detail: "Directly order lab tests and medical scans from labs around the world without needing a subscription.",
            media: .stack([ImageNames.whatsNewGuidedTestingV5, ImageNames.whatsNewGuidedTestingStatsV5])
        ),
        .init(
            title: "Exercise Planner",
            detail: "Create and track both workouts and runs by either importing workout plans or generating your own.",
            media: .carousel([ImageNames.whatsNewExerciseWatchV5, ImageNames.whatsNewExercisePlannerV5, ImageNames.whatsNewExerciseRunV5])
        ),
        .init(
            title: "Atlas",
            detail: "A global health monitor built on real-time Bright data that allows you to understand your health relative to similar users.",
            media: .carousel([ImageNames.whatsNewAtlasGlobeV5, ImageNames.whatsNewAtlasStatsV5])
        )
    ]
}

private struct WhatsNewMoreItemView: View {
    let item: WhatsNewMoreItem
    let isLeading: Bool

    @State private var glow = 0

    private typealias Constants = BrightWhatsNewSheetV5.Constants

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            HStack(spacing: .spacing1x) {
                ForEach(item.icons, id: \.self) { icon in
                    switch icon {
                    case .symbol(let name):
                        Image(systemName: name)
                            .font(.system(size: Constants.moreIconSize))
                            .foregroundStyle(item.color)
                    case .image(let name):
                        Image(name)
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
            .frame(height: Constants.moreIconSize)
            .keyframeAnimator(initialValue: 0.0, trigger: glow) { content, value in
                content.shadow(color: item.color.opacity(value), radius: value * Constants.glowRadius)
            } keyframes: { _ in
                CubicKeyframe(1, duration: Constants.glowIn)
                LinearKeyframe(1, duration: Constants.glowHold)
                CubicKeyframe(0, duration: Constants.glowOut)
            }
            .padding(.bottom, .spacing05x)

            BrightText(item.title, size: .heading, color: .semiLightTextColor, weight: .regular)
            BrightText(item.detail, size: .body1, color: .lightTextColor, weight: .regular)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .whatsNewReveal(delay: isLeading ? 0 : Constants.revealStagger) { [isLeading] content, hidden in
            content
                .opacity(1 - hidden)
                .offset(x: hidden * (isLeading ? -1 : 1) * Constants.itemSlide)
                .blur(radius: hidden * Constants.revealBlur)
        }
        .onScrollVisibilityChange(threshold: Constants.revealThreshold) { isVisible in
            guard isVisible, glow == 0 else { return }
            Task {
                try? await Task.sleep(for: .seconds(Constants.revealDuration))
                glow += 1
            }
        }
    }
}

private struct WhatsNewMoreItem: Identifiable {
    enum Icon: Hashable {
        case symbol(String)
        case image(String)
    }

    let id = UUID()
    let icons: [Icon]
    let color: Color
    let title: String
    let detail: String

    static let all: [Self] = [
        .init(
            icons: [.symbol("hare.fill")],
            color: .defaultSkyBlue,
            title: "Rebuilt UX/UI",
            detail: "A faster, smoother and more stable Bright OS."
        ),
        .init(
            icons: [.image(ImageNames.whatsNewAndroidWebIconV5)],
            color: .defaultGreen,
            title: "Android and Web-App",
            detail: "A faster, smoother and more stable Bright OS."
        ),
        .init(
            icons: [.symbol("figure")],
            color: .defaultPink,
            title: "3D Avatar",
            detail: "Track muscle and cardio progress with a dedicated 3D avatar showing muscle progress."
        ),
        .init(
            icons: [
                .symbol("figure.rolling"),
                .symbol("figure.outdoor.cycle"),
                .symbol("figure.strengthtraining.traditional")
            ],
            color: .defaultOrange,
            title: "Workout Library",
            detail: "Explore a library of over 800 motion-captured workouts, stretches and yoga poses using our 3D human model."
        ),
        .init(
            icons: [.symbol("person.badge.clock.fill")],
            color: .defaultSkyBlue,
            title: "Check-Ins",
            detail: "Bright continuously orientates you towards your Waypoint by reviewing your data and providing adaptive suggestions."
        ),
        .init(
            icons: [.symbol("map")],
            color: .defaultGreen,
            title: "Explore",
            detail: "Filter the internet with your health-data so you only see health products and services that are suitable for you."
        ),
        .init(
            icons: [.image(ImageNames.whatsNewDnaIconV5)],
            color: .defaultPurple,
            title: "Genome",
            detail: "Upload or order a Whole-Genome Sequence so Bright can sync your lifestyle, wearable, clinical and genome data to create the full picture."
        ),
        .init(
            icons: [.symbol("testtube.2")],
            color: .defaultYellow,
            title: "Experiments",
            detail: "Users can create observational studies on users to test a hypothesis."
        ),
        .init(
            icons: [.symbol("sparkles.2")],
            color: .defaultCyan,
            title: "Ask",
            detail: "Powered by Bright’s aggregated user-dataset, users can find the answer to their health questions based on the raw data alone."
        ),
        .init(
            icons: [.symbol("globe")],
            color: .defaultSkyBlue,
            title: "Global Health Ranking",
            detail: "Using your data against Atlas data, Bright creates a ranking relative to users with a health similar health profile."
        ),
        .init(
            icons: [.symbol("applewatch")],
            color: .defaultGreen,
            title: "Watch App",
            detail: "A stand alone Apple Watch app to support the Workout and Running planner."
        ),
        .init(
            icons: [.symbol("repeat")],
            color: .defaultPink,
            title: "Automated Journaling",
            detail: "Bright will independently record events throughout the day to your Daily Log without requiring manual entry."
        ),
        .init(
            icons: [.symbol("square.and.arrow.up")],
            color: .defaultOrange,
            title: "Social Sharing",
            detail: "Each widget and section includes ways to share unique content from Bright to social media platforms."
        ),
        .init(
            icons: [.image(ImageNames.whatsNewWidgetsIconV5)],
            color: .defaultSkyBlue,
            title: "Customisation",
            detail: "Rearrange and reorder each widget to better fit your preferences."
        ),
        .init(
            icons: [.symbol("repeat")],
            color: .defaultPink,
            title: "API/MCP",
            detail: "All your Bright data is available with read and write privileges via API and MCP access at no extra cost."
        ),
        .init(
            icons: [.image(ImageNames.whatsNewIntegrationsIconV5)],
            color: .defaultGreen,
            title: "Integrations",
            detail: "We have expanded the list of direct integrations for wearables and other apps to over 50 including; Amazfit/Helio, Strava, Hevy and more."
        ),
        .init(
            icons: [.symbol("globe")],
            color: .defaultCyan,
            title: "Languages",
            detail: "The app is now available in over 50 languages."
        ),
        .init(
            icons: [.symbol("lock.shield")],
            color: .defaultRed,
            title: "Compliance & Security",
            detail: "Bright OS is now HIPAA, GDPR, ISO27001 and SOC2 compliant along with being SEC-256 encrypted."
        )
    ]
}

private struct WhatsNewReveal<Effect: VisualEffect>: ViewModifier {
    let delay: Double
    let effect: @Sendable (EmptyVisualEffect, Double) -> Effect

    @State private var isRevealed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private typealias Constants = BrightWhatsNewSheetV5.Constants

    func body(content: Content) -> some View {
        let isRevealed = self.isRevealed || reduceMotion
        let effect = self.effect
        content
            .scrollTransition(
                .animated(.smooth(duration: Constants.revealDuration).delay(delay))
                    .threshold(.visible(Constants.revealThreshold))
            ) { view, phase in
                effect(view, isRevealed ? 0 : max(phase.value, 0))
            }
            .onScrollVisibilityChange(threshold: Constants.revealThreshold) { isVisible in
                guard isVisible, !self.isRevealed else { return }
                Task {
                    try? await Task.sleep(for: Constants.revealLock)
                    self.isRevealed = true
                }
            }
    }
}

private extension View {
    func whatsNewReveal<Effect: VisualEffect>(
        delay: Double = 0,
        effect: @escaping @Sendable (EmptyVisualEffect, Double) -> Effect
    ) -> some View {
        modifier(WhatsNewReveal(delay: delay, effect: effect))
    }
}
