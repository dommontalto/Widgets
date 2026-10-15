//
//  BrightWhatsNewSheetV5.swift
//  Widgets
//

import SwiftUI

struct BrightWhatsNewSheetV5: View {
    var body: some View {
        BrightPageSheetViewV5(horizontalPadding: .spacing0x) {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing0x) {
                    hero

                    BrightText("What’s new.", size: .standout1, color: .semiLightTextColor, weight: .regular)
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

            BrightText("Welcome to V5.", size: .huge, color: .white, weight: .regular)
                .padding(.top, Constants.heroTitleTop)
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .bottom) {
            Color.defaultBlack
                .padding(.top, -Constants.heroOverscroll)
        }
    }

    private var more: some View {
        BrightText("and more.", size: .standout1, color: .semiLightTextColor, weight: .regular)
            .padding(.horizontal, .spacing5x)
    }

    fileprivate enum Constants {
        static let heroTitleTop: CGFloat = .spacing3x
        static let heroOverscroll: CGFloat = 2000
        static let carouselCardWidth: CGFloat = 284
        static let imageCornerRadius: CGFloat = 40
    }
}

private struct WhatsNewFeatureSection: View {
    let feature: WhatsNewFeature

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            VStack(alignment: .leading, spacing: .spacing2x) {
                BrightText(feature.title, size: .heading, color: .semiLightTextColor, weight: .regular)
                BrightText(feature.detail, size: .body1, color: .lightTextColor, weight: .regular)
                    .fixedSize(horizontal: false, vertical: true)
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
                }
            }
            .padding(.horizontal, .spacing5x)
        case .carousel(let images):
            WhatsNewCarousel(images: images)
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
