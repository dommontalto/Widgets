//
//  BrightWhatsNewSheetV5.swift
//  Widgets
//

import AVFoundation
import SwiftUI

struct BrightWhatsNewSheetV5: View {
    @State private var page: Int? = 0

    var body: some View {
        BrightPageSheetViewV5(horizontalPadding: .spacing0x) {
            ScrollView {
                VStack(spacing: .spacing0x) {
                    ForEach(Array(WhatsNewFeature.all.enumerated()), id: \.element.id) { index, feature in
                        WhatsNewFeaturePage(feature: feature, isActive: page == index)
                            .whatsNewPage(index)
                    }

                    WhatsNewMoreSceneV5(isActive: page == WhatsNewFeature.all.count)
                        .whatsNewPage(WhatsNewFeature.all.count)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollPosition(id: $page, anchor: .top)
            .scrollIndicators(.hidden)
            .brightHapticV5(.light, trigger: page)
        }
    }

    enum Constants {
        static let revealDuration: Double = 1.2
        static let revealStagger: Double = 0.2
        static let revealBlur: CGFloat = 8
        static let textRise: CGFloat = .spacing4x
        static let itemSlide: CGFloat = .spacing6x
        static let mediaRise: CGFloat = .spacing10x
        static let mediaShrink: CGFloat = 0.08
    }
}

private struct WhatsNewFeaturePage: View {
    let feature: WhatsNewFeature
    let isActive: Bool

    private typealias Constants = BrightWhatsNewSheetV5.Constants

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            VStack(alignment: .leading, spacing: .spacing2x) {
                BrightText(feature.title, size: .standout1, color: .semiLightTextColor, weight: .regular)
                    .whatsNewReveal(isActive) { content, hidden in
                        content
                            .opacity(1 - hidden)
                            .offset(x: -hidden * Constants.itemSlide)
                            .blur(radius: hidden * Constants.revealBlur)
                    }

                BrightText(feature.detail, size: .body1, color: .lightTextColor, weight: .regular)
                    .lineSpacing(.lineSpacingMedium)
                    .fixedSize(horizontal: false, vertical: true)
                    .whatsNewReveal(isActive, delay: Constants.revealStagger) { content, hidden in
                        content
                            .opacity(1 - hidden)
                            .offset(y: hidden * Constants.textRise)
                            .blur(radius: hidden * Constants.revealBlur)
                    }
            }
            .padding(.horizontal, .spacing5x)
            .padding(.top, .spacing4x)

            WhatsNewDeviceV5(clip: feature.clip, isActive: isActive)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, .spacing4x)
                .whatsNewReveal(isActive, delay: Constants.revealStagger * 2) { content, hidden in
                    content
                        .opacity(1 - hidden)
                        .scaleEffect(1 - hidden * Constants.mediaShrink, anchor: .bottom)
                        .offset(y: hidden * Constants.mediaRise)
                }
        }
    }
}

private struct WhatsNewFeature: Identifiable {
    let clip: String
    let title: String
    let detail: String

    var id: String { clip }

    static let all: [Self] = [
        .init(
            clip: "whats_new_home_v5",
            title: "Welcome to V5.",
            detail: "A rebuilt Bright: faster, smoother, and shaped around the widgets you choose."
        ),
        .init(
            clip: "whats_new_lighthouse_v5",
            title: "Lighthouse",
            detail: "An AI layer that can read every part of Bright. Pick from the leading frontier models, or bring your own API key."
        ),
        .init(
            clip: "whats_new_waypoint_v5",
            title: "Waypoint",
            detail: "Set short and long term health goals, and Bright retunes every widget to keep you on course."
        ),
        .init(
            clip: "whats_new_vault_v5",
            title: "Vault",
            detail: "Your genetic, lifestyle, wearable and clinical data in one place, ready to review or share with anyone."
        ),
        .init(
            clip: "whats_new_guided_testing_v5",
            title: "Guided Testing",
            detail: "Order lab tests and medical scans from labs around the world, no subscription needed."
        ),
        .init(
            clip: "whats_new_exercise_v5",
            title: "Exercise Planner",
            detail: "Import or generate workouts and runs, learn form from 3D guides, and plan routes before you head out."
        ),
        .init(
            clip: "whats_new_atlas_v5",
            title: "Atlas",
            detail: "A global health monitor built on real-time Bright data, so you can see how you compare with people like you."
        ),
    ]
}

// MARK: - Paging

private extension View {
    func whatsNewPage(_ index: Int) -> some View {
        containerRelativeFrame(.vertical)
            .id(index)
    }
}

// MARK: - Reveal

// Plays `effect` from hidden (1) to shown (0) each time the page becomes active,
// and snaps back to hidden off screen so it replays on return.
private struct WhatsNewReveal<Effect: VisualEffect>: ViewModifier {
    let isActive: Bool
    let delay: Double
    let effect: @Sendable (EmptyVisualEffect, Double) -> Effect

    @State private var hidden: Double = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let effect = self.effect
        let hidden = reduceMotion ? 0 : self.hidden
        content
            .visualEffect { view, _ in effect(view, hidden) }
            .onChange(of: isActive, initial: true) { _, active in
                if active {
                    withAnimation(.smooth(duration: BrightWhatsNewSheetV5.Constants.revealDuration).delay(delay)) {
                        self.hidden = 0
                    }
                } else {
                    self.hidden = 1
                }
            }
    }
}

extension View {
    func whatsNewReveal<Effect: VisualEffect>(
        _ isActive: Bool,
        delay: Double = 0,
        effect: @escaping @Sendable (EmptyVisualEffect, Double) -> Effect
    ) -> some View {
        modifier(WhatsNewReveal(isActive: isActive, delay: delay, effect: effect))
    }
}

// MARK: - Device

// A phone rising from the bottom of the page, cut off by it, playing a screen
// recording of the feature.
private struct WhatsNewDeviceV5: View {
    let clip: String
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        WhatsNewClipV5(name: clip, isPlaying: isActive && !reduceMotion)
            .aspectRatio(Constants.clipAspect, contentMode: .fit)
            .frame(width: Constants.width)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color.defaultBlack)
            .clipShape(shape)
            .overlay {
                shape.stroke(Color.white.opacity(.minimalOpacity), lineWidth: Constants.bezel)
            }
            .padding([.horizontal, .top], Constants.bezel)
            .background(Color.defaultBlack, in: shape)
            .frame(maxWidth: .infinity)
    }

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: .screenCornerRadius, topTrailingRadius: .screenCornerRadius, style: .continuous)
    }

    private enum Constants {
        static let width: CGFloat = 300
        static let bezel: CGFloat = 4
        // The recordings are 900 × 1956, an iPhone screen at 3x.
        static let clipAspect: CGFloat = 900 / 1956
    }
}

// Loops a bundled, silent .mp4 (or one stretch of it, in seconds) from the start
// each time it begins playing.
struct WhatsNewClipV5: UIViewRepresentable {
    let name: String
    var range: ClosedRange<Double>? = nil
    let isPlaying: Bool

    func makeUIView(context: Context) -> WhatsNewPlayerView {
        let view = WhatsNewPlayerView()
        if let url = Bundle.main.url(forResource: name, withExtension: "mp4") {
            let player = AVQueuePlayer()
            player.isMuted = true
            player.preventsDisplaySleepDuringVideoPlayback = false
            let item = AVPlayerItem(url: url)
            if let timeRange {
                view.looper = AVPlayerLooper(player: player, templateItem: item, timeRange: timeRange)
            } else {
                view.looper = AVPlayerLooper(player: player, templateItem: item)
            }
            view.player = player
        }
        return view
    }

    func updateUIView(_ view: WhatsNewPlayerView, context: Context) {
        guard let player = view.player, view.isPlaying != isPlaying else { return }
        view.isPlaying = isPlaying
        if isPlaying {
            player.seek(to: timeRange?.start ?? .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            player.play()
        } else {
            player.pause()
        }
    }

    static func dismantleUIView(_ view: WhatsNewPlayerView, coordinator: ()) {
        view.player?.pause()
    }

    private var timeRange: CMTimeRange? {
        range.map {
            CMTimeRange(
                start: CMTime(seconds: $0.lowerBound, preferredTimescale: 600),
                end: CMTime(seconds: $0.upperBound, preferredTimescale: 600)
            )
        }
    }
}

final class WhatsNewPlayerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    var looper: AVPlayerLooper?
    var isPlaying = false

    var player: AVQueuePlayer? {
        get { (layer as? AVPlayerLayer)?.player as? AVQueuePlayer }
        set {
            (layer as? AVPlayerLayer)?.player = newValue
            (layer as? AVPlayerLayer)?.videoGravity = .resizeAspect
        }
    }
}
