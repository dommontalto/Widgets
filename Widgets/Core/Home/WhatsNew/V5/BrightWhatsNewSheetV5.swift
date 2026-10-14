//
//  BrightWhatsNewSheetV5.swift
//  Widgets
//

import SwiftUI

struct BrightWhatsNewSheetV5: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var motion: CGFloat { reduceMotion ? 0 : 1 }

    var body: some View {
        BrightPageSheetViewV5(horizontalPadding: .spacing0x) {
            ScrollView {
                VStack(spacing: .spacing8x) {
                    banner
                    features
                    more
                }
                .padding(.bottom, .spacing8x)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var banner: some View {
        VStack(spacing: .spacing3x) {
            Image(ImageNames.brightLogoSearchingV4)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: Constants.markSize, height: Constants.markSize)

            BrightText("What’s New in V5", size: .huge2, color: .white)

            Image(ImageNames.whatsNewBannerV5)
                .resizable()
                .scaledToFit()
                .padding(.top, .spacing4x)
        }
        .padding(.top, .spacing4x)
        .frame(maxWidth: .infinity)
        .background(alignment: .bottom) {
            Color.defaultBlack
                .padding(.top, -Constants.bannerOverscroll)
        }
    }

    private var features: some View {
        let motion = self.motion
        return VStack(alignment: .leading, spacing: .spacing8x) {
            ForEach(WhatsNewFeature.all) { feature in
                VStack(alignment: .leading, spacing: .spacing3x) {
                    VStack(alignment: .leading, spacing: .spacing2x) {
                        BrightText(feature.title, size: .standout2, color: .semiLightTextColor)
                            .whatsNewReveal(.animated(.bouncy), threshold: Constants.textThreshold) { content, entry in
                                content
                                    .opacity(1 - entry)
                                    .offset(x: -entry * Constants.slideDistance * motion)
                                    .blur(radius: entry * Constants.entryBlur * motion)
                            }
                        BrightText(feature.detail, size: .body1, color: .lightTextColor)
                            .whatsNewReveal(.animated(.smooth.delay(Constants.stagger)), threshold: Constants.textThreshold) { content, entry in
                                content
                                    .opacity(1 - entry)
                                    .offset(y: entry * Constants.riseDistance * motion)
                                    .blur(radius: entry * Constants.entryBlur * motion)
                            }
                    }

                    VStack(spacing: .spacing2x) {
                        ForEach(Array(feature.images.enumerated()), id: \.element) { index, image in
                            WhatsNewFeatureImage(image: image, direction: index.isMultiple(of: 2) ? 1 : -1, motion: motion)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, .spacing3x)
    }

    private var more: some View {
        VStack(alignment: .leading, spacing: .spacing5x) {
            sectionTitle("and more.")
                .whatsNewReveal(.animated(.bouncy), threshold: Constants.headingThreshold) { content, entry in
                    content
                        .opacity(1 - entry)
                        .scaleEffect(1 - entry * Constants.titlePop * motion, anchor: .leading)
                        .blur(radius: entry * Constants.entryBlur * motion)
                }

            Grid(alignment: .topLeading, horizontalSpacing: .spacing3x, verticalSpacing: .spacing5x) {
                ForEach(Array(stride(from: 0, to: WhatsNewMoreItem.all.count, by: 2)), id: \.self) { start in
                    GridRow {
                        ForEach(WhatsNewMoreItem.all[start ..< min(start + 2, WhatsNewMoreItem.all.count)]) { item in
                            WhatsNewMoreItemView(item: item, isLeading: item.id == WhatsNewMoreItem.all[start].id, motion: motion)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, .spacing3x)
    }

    private func sectionTitle(_ title: String) -> some View {
        BrightText(title, size: .huge205, color: .semiLightTextColor)
    }

    fileprivate enum Constants {
        static let markSize: CGFloat = 44
        static let bannerOverscroll: CGFloat = 2000
        static let moreIconSize: CGFloat = 22
        static let perspective: CGFloat = 0.6
        static let slideDistance: CGFloat = .spacing5x
        static let riseDistance: CGFloat = .spacing4x
        static let entryBlur: CGFloat = 6
        static let stagger: Double = 0.08
        static let imageShrink: CGFloat = 0.2
        static let imageTilt: Double = 28
        static let imageRise: CGFloat = .spacing8x
        static let imageSpin: Double = 3
        static let glowRadius: CGFloat = .spacing2x
        static let glowIn: Double = 0.2
        static let glowHold: Double = 1.5
        static let glowOut: Double = 1.2
        static let imageTwist: CGFloat = 0.25
        static let imageFade: Double = 0.5
        static let imageDim: Double = 0.15
        static let titlePop: CGFloat = 0.2
        static let itemSlide: CGFloat = .spacing6x
        static let itemStagger: Double = 0.06
        static let iconBounce: Double = 0.2
        static let iconPop: CGFloat = 0.6
        static let iconSpin: Double = 30
        static let textThreshold: Double = 0.6
        static let headingThreshold: Double = 0.8
        static let imageThreshold: Double = 0.35
        static let itemThreshold: Double = 0.5
        static let revealLock: Duration = .seconds(1)
    }
}

private struct WhatsNewFeatureImage: View {
    let image: String
    let direction: Double
    let motion: CGFloat

    private typealias Constants = BrightWhatsNewSheetV5.Constants

    var body: some View {
        let direction = self.direction
        let motion = self.motion
        Image(image)
            .resizable()
            .scaledToFit()
            .clipShape(.rect(cornerRadius: .cardCornerRadius))
            .whatsNewReveal(.interactive, threshold: Constants.imageThreshold, lockDelay: .zero) { content, entry in
                content
                    .scaleEffect(1 - entry * Constants.imageShrink * motion)
                    .offset(y: entry * Constants.imageRise * motion)
                    .rotationEffect(.degrees(entry * direction * Constants.imageSpin * motion))
                    .rotation3DEffect(
                        .degrees(entry * Constants.imageTilt * motion),
                        axis: (x: 1, y: direction * Constants.imageTwist, z: 0),
                        perspective: Constants.perspective
                    )
                    .opacity(1 - entry * Constants.imageFade)
                    .brightness(-entry * Constants.imageDim * motion)
            }
    }
}

private struct WhatsNewMoreItemView: View {
    let item: WhatsNewMoreItem
    let isLeading: Bool
    let motion: CGFloat

    @State private var bounce = 0

    private typealias Constants = BrightWhatsNewSheetV5.Constants

    var body: some View {
        let side: CGFloat = isLeading ? -1 : 1
        let motion = self.motion
        VStack(alignment: .leading, spacing: .spacing1x) {
            HStack(spacing: .spacing1x) {
                ForEach(item.icons, id: \.self) { icon in
                    iconView(icon)
                }
            }
            .frame(height: Constants.moreIconSize)
            .padding(.bottom, .spacing05x)
            .symbolEffect(.bounce.up.byLayer, value: bounce)
            .keyframeAnimator(initialValue: 0.0, trigger: bounce) { content, glow in
                content.shadow(color: item.color.opacity(glow), radius: glow * Constants.glowRadius)
            } keyframes: { _ in
                LinearKeyframe(1, duration: Constants.glowIn)
                LinearKeyframe(1, duration: Constants.glowHold)
                CubicKeyframe(0, duration: Constants.glowOut)
            }
            .whatsNewReveal(.animated(.bouncy(extraBounce: Constants.iconBounce)), threshold: Constants.itemThreshold) { content, entry in
                content
                    .scaleEffect(1 - entry * Constants.iconPop * motion)
                    .rotationEffect(.degrees(entry * side * Constants.iconSpin * motion))
            }

            BrightText(item.title, size: .heading, color: .semiLightTextColor)
                .padding(.bottom, .spacing05x)
            BrightText(item.detail, size: .body1, color: .lightTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .whatsNewReveal(.animated(.smooth.delay(isLeading ? 0 : Constants.itemStagger)), threshold: Constants.itemThreshold) { content, entry in
            content
                .opacity(1 - entry)
                .offset(x: entry * side * Constants.itemSlide * motion)
                .blur(radius: entry * Constants.entryBlur * motion)
        }
        .onScrollVisibilityChange(threshold: 0.9) { isVisible in
            if isVisible && motion > 0 && bounce == 0 { bounce += 1 }
        }
    }

    @ViewBuilder
    private func iconView(_ icon: WhatsNewMoreItem.Icon) -> some View {
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

private struct WhatsNewFeature: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let images: [String]

    static let all: [Self] = [
        .init(
            title: "Lighthouse",
            detail: "We’ve created a LLM layer that can read any part of the app. Users can choose a LLM from leading frontier-models or choose to use their own LLM token.",
            images: [ImageNames.whatsNewLighthouseChatV5, ImageNames.whatsNewLighthouseModelsV5]
        ),
        .init(
            title: "Waypoint",
            detail: "Create programs to reach short and long term health goals and Bright will systematically adjust each widget to help you along the way.",
            images: [ImageNames.whatsNewWaypointV5]
        ),
        .init(
            title: "Vault",
            detail: "This brings together all the foundations of your health for you to review and share with anyone via a URL.",
            images: [ImageNames.whatsNewVaultGenomeV5, ImageNames.whatsNewVaultShareV5]
        ),
        .init(
            title: "Guided Testing",
            detail: "Directly order lab tests and scans from over 55,000 locations in 50 different countries.",
            images: [ImageNames.whatsNewGuidedTestingV5, ImageNames.whatsNewGuidedTestingStatsV5]
        ),
        .init(
            title: "Exercise Planner",
            detail: "Create and track both workouts and runs by either importing workout plans or generating your own.",
            images: [ImageNames.whatsNewExerciseWatchV5, ImageNames.whatsNewExercisePlannerV5]
        ),
        .init(
            title: "Atlas",
            detail: "A global health monitor built on real-time Bright data that allows you to understand your health relative to similar users.",
            images: [ImageNames.whatsNewAtlasV5]
        )
    ]
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
    let configuration: ScrollTransitionConfiguration
    let threshold: Double
    let lockDelay: Duration
    let effect: @Sendable (EmptyVisualEffect, Double) -> Effect

    @State private var isRevealed = false

    func body(content: Content) -> some View {
        let isRevealed = self.isRevealed
        let effect = self.effect
        content
            .scrollTransition(configuration.threshold(.visible(threshold))) { view, phase in
                effect(view, isRevealed ? 0 : max(phase.value, 0))
            }
            .onScrollVisibilityChange(threshold: threshold) { isVisible in
                guard isVisible, !self.isRevealed else { return }
                Task {
                    try? await Task.sleep(for: lockDelay)
                    self.isRevealed = true
                }
            }
    }
}

private extension View {
    func whatsNewReveal<Effect: VisualEffect>(
        _ configuration: ScrollTransitionConfiguration,
        threshold: Double,
        lockDelay: Duration = BrightWhatsNewSheetV5.Constants.revealLock,
        effect: @escaping @Sendable (EmptyVisualEffect, Double) -> Effect
    ) -> some View {
        modifier(WhatsNewReveal(configuration: configuration, threshold: threshold, lockDelay: lockDelay, effect: effect))
    }
}
