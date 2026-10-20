//
//  BrightWhatsNewSheetV5.swift
//  Widgets
//

import AVFoundation
import SwiftUI

struct BrightWhatsNewSheetV5: View {
    @State private var heroVisible = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: .spacing0x) {
                    WhatsNewHero(isPlaying: heroVisible)
                        .whatsNewPage()
                        .onScrollVisibilityChange(threshold: Constants.visibleShare) { heroVisible = $0 }

                    ForEach(WhatsNewSection.all) { section in
                        WhatsNewSectionView(section: section)
                            .whatsNewPage()
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)

            BrightRoundButton(systemImage: "xmark", size: .large) { dismiss() }
                .padding(.spacing3x)
        }
        .background(Color.defaultBlackWhite)
        .presentationBackground(Color.defaultBlackWhite)
    }

    enum Constants {
        static let revealDuration: Double = 1.2
        static let revealStagger: Double = 0.2
        static let revealBlur: CGFloat = 8
        static let textRise: CGFloat = .spacing4x
        static let itemSlide: CGFloat = .spacing6x
        static let mediaRise: CGFloat = .spacing10x
        static let mediaShrink: CGFloat = 0.08
        static let visibleShare: Double = 0.4
        static let heroPhoneWidth: CGFloat = 240
        static let cardHeight: CGFloat = 356
        static let wideCardHeight: CGFloat = 242
        // Carousel cards leave the next one peeking in from the trailing edge.
        static let carouselShare: CGFloat = 0.83
        static let phoneShare: CGFloat = 0.6
        static let phoneInset: CGFloat = 0.15
        static let raisedPhoneInset: CGFloat = 0.06
    }
}

// MARK: - Hero

private struct WhatsNewHero: View {
    let isPlaying: Bool

    @State private var isRevealed = false
    @State private var hasRisen = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private typealias Constants = BrightWhatsNewSheetV5.Constants
    private typealias Reveal = BrightWhatsNewSheetV5.Constants

    var body: some View {
        VStack(spacing: .spacing8x) {
            BrightText("Welcome to V5.", size: .huge, color: .defaultWhite)
                .whatsNewReveal(isRevealed) { content, hidden in
                    content
                        .opacity(1 - hidden)
                        .offset(y: hidden * Reveal.textRise)
                        .blur(radius: hidden * Reveal.revealBlur)
                }

            WhatsNewPhone(clip: .init(name: "whats_new_home_v5"), isPlaying: isPlaying && hasRisen && !reduceMotion, width: Constants.heroPhoneWidth)
                .rotation3DEffect(.degrees(Hero.yaw), axis: (x: Hero.pitch, y: -1, z: 0), perspective: Hero.perspective)
                .rotationEffect(.degrees(Hero.roll))
                .whatsNewReveal(isRevealed, delay: Reveal.revealStagger) { content, hidden in
                    content
                        .opacity(1 - hidden)
                        .scaleEffect(1 - hidden * Reveal.mediaShrink, anchor: .bottom)
                        .offset(y: hidden * Reveal.mediaRise)
                }
        }
        .padding(.top, .spacing12x + .spacing6x)
        .frame(maxWidth: .infinity, alignment: .top)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.defaultBlack)
        .clipped()
        .onAppear { isRevealed = true }
        // Holds the clip on its first frame until the phone has mostly risen in,
        // so the widgets loading in isn't missed behind the fade.
        .task {
            try? await Task.sleep(for: .seconds(Reveal.revealStagger + Reveal.revealDuration * 0.6))
            hasRisen = true
        }
    }

    private enum Hero {
        static let yaw: Double = 18
        static let pitch: CGFloat = 0.25
        static let roll: Double = 6
        static let perspective: CGFloat = 0.6
    }
}

// MARK: - Section

private struct WhatsNewSectionView: View {
    let section: WhatsNewSection

    @State private var isVisible = false
    @State private var isRevealed = false
    @State private var page: Int? = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private typealias Constants = BrightWhatsNewSheetV5.Constants
    private typealias Reveal = BrightWhatsNewSheetV5.Constants

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            VStack(alignment: .leading, spacing: .spacing2x) {
                BrightText(section.title, size: .heading, weight: .regular)
                    .whatsNewReveal(isRevealed) { content, hidden in
                        content
                            .opacity(1 - hidden)
                            .offset(x: -hidden * Reveal.itemSlide)
                            .blur(radius: hidden * Reveal.revealBlur)
                    }

                BrightText(section.detail, size: .body1, color: .lightTextColor)
                    .lineSpacing(.lineSpacingMedium)
                    .fixedSize(horizontal: false, vertical: true)
                    .whatsNewReveal(isRevealed, delay: Reveal.revealStagger) { content, hidden in
                        content
                            .opacity(1 - hidden)
                            .offset(y: hidden * Reveal.textRise)
                            .blur(radius: hidden * Reveal.revealBlur)
                    }
            }
            .padding(.horizontal, .spacing5x)

            cards
                .padding(.top, .spacing5x)
                .whatsNewReveal(isRevealed, delay: Reveal.revealStagger * 2) { content, hidden in
                    content
                        .opacity(1 - hidden)
                        .scaleEffect(1 - hidden * Reveal.mediaShrink, anchor: .top)
                        .offset(y: hidden * Reveal.mediaRise)
                }
        }
        .padding(.top, .spacing8x)
        .onScrollVisibilityChange(threshold: Constants.visibleShare) { visible in
            isVisible = visible
            if visible { isRevealed = true }
        }
    }

    @ViewBuilder
    private var cards: some View {
        switch section.layout {
        case .stack:
            VStack(spacing: .spacing3x) {
                ForEach(Array(section.cards.enumerated()), id: \.offset) { _, card in
                    WhatsNewCardView(card: card, isActive: isVisible && !reduceMotion, isRevealed: isRevealed)
                }
            }
            .padding(.horizontal, .spacing5x)
        case .carousel:
            VStack(spacing: .spacing3x) {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: .spacing3x) {
                        ForEach(Array(section.cards.enumerated()), id: \.offset) { index, card in
                            WhatsNewCardView(card: card, isActive: isVisible && page == index && !reduceMotion, isRevealed: isRevealed)
                                .containerRelativeFrame(.horizontal) { length, _ in length * Constants.carouselShare }
                                .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, .spacing5x, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $page)
                .scrollIndicators(.hidden)
                .scrollClipDisabled()

                BrightPageIndicatorV5(total: section.cards.count, activeIndex: $page)
            }
        }
    }
}

// MARK: - Cards

private struct WhatsNewCardView: View {
    let card: WhatsNewCard
    let isActive: Bool
    let isRevealed: Bool

    private typealias Constants = BrightWhatsNewSheetV5.Constants

    var body: some View {
        GeometryReader { proxy in
            media(in: proxy.size)
        }
        .frame(height: card.height)
        .background(card.background)
        .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))
    }

    @ViewBuilder
    private func media(in size: CGSize) -> some View {
        switch card.media {
        case .phone(let clip, let isTilted):
            WhatsNewPhone(clip: clip, isPlaying: isActive, width: size.width * Constants.phoneShare)
                .rotation3DEffect(.degrees(isTilted ? Tilt.yaw : 0), axis: (x: Tilt.pitch, y: 1, z: 0), perspective: Tilt.perspective)
                .rotationEffect(.degrees(isTilted ? Tilt.roll : 0))
                .padding(.top, size.width * card.phoneInset)
                .frame(width: size.width, height: size.height, alignment: .top)
        case .fullPhone(let clip):
            let height = size.height - .spacing3x * 2
            WhatsNewPhone(clip: clip, isPlaying: isActive, width: height * WhatsNewPhone.Constants.device.width / WhatsNewPhone.Constants.device.height)
                .frame(width: size.width, height: size.height)
        case .screen(let clip, let zoom, let focus):
            WhatsNewScreen(clip: clip, isPlaying: isActive, zoom: zoom, focus: focus, size: size)
        case .stats:
            WhatsNewStats(isActive: isRevealed)
                .frame(width: size.width, height: size.height)
        }
    }

    private enum Tilt {
        static let yaw: Double = 22
        static let pitch: CGFloat = 0.3
        static let roll: Double = -10
        static let perspective: CGFloat = 0.6
    }
}

// A clip filling the card, scaled by `zoom` and shifted so `focus` (a point in
// the recording) sits as near the middle of the card as its edges allow.
private struct WhatsNewScreen: View {
    let clip: WhatsNewClip
    let isPlaying: Bool
    let zoom: CGFloat
    let focus: UnitPoint
    let size: CGSize

    var body: some View {
        let width = size.width * zoom
        let height = width / WhatsNewPhone.Constants.screen.width * WhatsNewPhone.Constants.screen.height
        let slackX = max(width - size.width, 0) / 2
        let slackY = max(height - size.height, 0) / 2

        WhatsNewClipV5(name: clip.name, range: clip.range, isPlaying: isPlaying)
            .frame(width: width, height: height)
            .offset(
                x: min(max((0.5 - focus.x) * width, -slackX), slackX),
                y: min(max((0.5 - focus.y) * height, -slackY), slackY)
            )
            .frame(width: size.width, height: size.height)
            .clipped()
    }
}

// An iPhone 18 Pro in black, drawn at its real point size so the screen corner
// token reads true, then scaled down to `width`. The bezel and frame are strokes
// centred on the screen's outline, so they grow outward concentric with it.
private struct WhatsNewPhone: View {
    let clip: WhatsNewClip
    let isPlaying: Bool
    let width: CGFloat

    var body: some View {
        let scale = width / Constants.device.width
        let screenShape = RoundedRectangle(cornerRadius: .screenCornerRadius, style: .continuous)

        ZStack(alignment: .top) {
            WhatsNewClipV5(name: clip.name, range: clip.range, isPlaying: isPlaying)
                .frame(width: Constants.screen.width, height: Constants.screen.height)
                .background(Color.defaultBlack)
                .clipShape(screenShape)

            Capsule()
                .fill(Color.defaultBlack)
                .frame(width: Constants.island.width, height: Constants.island.height)
                .padding(.top, Constants.islandTop)
        }
        .background {
            screenShape.stroke(Color.defaultBlack, lineWidth: Constants.bezel * 2)
        }
        .background {
            // The metal band's sheen, catching light on the top left and bottom right.
            screenShape.stroke(
                LinearGradient(
                    colors: [
                        Color.defaultWhite.opacity(.veryLowOpacity),
                        Color.defaultWhite.opacity(.finalBossLowOpacity),
                        Color.defaultWhite.opacity(.minimalOpacity),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: (Constants.bezel + Constants.frame) * 2
            )
        }
        .background {
            screenShape.stroke(Color.defaultBlack, lineWidth: (Constants.bezel + Constants.frame) * 2)
        }
        .padding(Constants.bezel + Constants.frame)
        .background(alignment: .topLeading) { buttons }
        .shadow(color: Color.defaultBlack.opacity(.veryLowOpacity), radius: Constants.shadow, x: Constants.shadow / 2, y: Constants.shadow)
        .scaleEffect(scale, anchor: .topLeading)
        .frame(width: width, height: Constants.device.height * scale, alignment: .topLeading)
    }

    // Action button and volume rocker on the left, side button and Camera Control
    // on the right, each half tucked behind the frame.
    private var buttons: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Constants.leftButtons, id: \.top) { button in
                Capsule()
                    .fill(Color.defaultBlack)
                    .frame(width: Constants.buttonDepth * 2, height: button.height)
                    .offset(x: -Constants.buttonDepth, y: button.top)
            }
            ForEach(Constants.rightButtons, id: \.top) { button in
                Capsule()
                    .fill(Color.defaultBlack)
                    .frame(width: Constants.buttonDepth * 2, height: button.height)
                    .offset(x: Constants.device.width - Constants.buttonDepth, y: button.top)
            }
        }
        .frame(width: Constants.device.width, height: Constants.device.height, alignment: .topLeading)
    }

    enum Constants {
        // The recordings are 900 × 1956, the 402pt-wide iPhone 18 Pro screen at 3x.
        static let screen = CGSize(width: 402, height: 402 * 1956 / 900)
        static let bezel: CGFloat = 7
        static let frame: CGFloat = 4
        static let island = CGSize(width: 126, height: 37)
        static let islandTop: CGFloat = 11
        static let buttonDepth: CGFloat = 3
        static let shadow: CGFloat = 40
        static let leftButtons: [SideButton] = [.init(top: 150, height: 34), .init(top: 222, height: 62), .init(top: 298, height: 62)]
        static let rightButtons: [SideButton] = [.init(top: 250, height: 100), .init(top: 500, height: 64)]
        static let device = CGSize(width: screen.width + (bezel + frame) * 2, height: screen.height + (bezel + frame) * 2)
    }

    struct SideButton {
        let top: CGFloat
        let height: CGFloat
    }
}

private struct WhatsNewStats: View {
    let isActive: Bool

    @State private var tests = 0
    @State private var countries = 0

    private typealias Reveal = BrightWhatsNewSheetV5.Constants

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            HStack(spacing: .spacing2x) {
                glyph("arrow.turn.up.right")
                BrightText("over", size: .giant, color: .defaultLighthouseBlue)
            }
            BrightText(tests.formatted(.number), size: .giant, color: .defaultWhite)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(tests)))
            BrightText("tests in", size: .giant, color: .defaultWhite)
            HStack(spacing: .spacing2x) {
                glyph("globe.asia.australia.fill")
                BrightText("\(countries)", size: .giant, color: .defaultLighthouseBlue)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(countries)))
            }
            BrightText("countries.", size: .giant, color: .defaultWhite)
        }
        .lineLimit(1)
        .minimumScaleFactor(Stats.minimumScale)
        .padding(.spacing6x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [.defaultSkyBlue, .defaultElectricBlue, .defaultDeepBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onChange(of: isActive, initial: true) { _, active in
            guard active else { return }
            withAnimation(.smooth(duration: Reveal.revealDuration * 2).delay(Reveal.revealStagger * 3)) {
                tests = Stats.tests
                countries = Stats.countries
            }
        }
    }

    private func glyph(_ name: String) -> some View {
        Image(systemName: name)
            .font(.standard(size: .giant, weight: .regular))
            .foregroundStyle(Color.defaultLighthouseBlue)
    }

    private enum Stats {
        static let tests = 55_000
        static let countries = 45
        static let minimumScale: CGFloat = 0.6
    }
}

// MARK: - Paging

private extension View {
    func whatsNewPage() -> some View {
        containerRelativeFrame(.vertical, alignment: .top)
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

// MARK: - Clip

// Loops a bundled, silent .mp4 (or one stretch of it, in seconds) from the start
// each time it begins playing.
private struct WhatsNewClipV5: UIViewRepresentable {
    let name: String
    var range: ClosedRange<Double>? = nil
    let isPlaying: Bool

    func makeUIView(context: Context) -> WhatsNewPlayerView {
        let view = WhatsNewPlayerView()
        if let url = Bundle.main.url(forResource: name, withExtension: "mp4") {
            // Even a muted player takes the default solo audio session and stops
            // whatever else is playing, so mix in the background instead.
            try? AVAudioSession.sharedInstance().setCategory(.ambient)
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

private final class WhatsNewPlayerView: UIView {
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

// MARK: - Content

private struct WhatsNewClip {
    let name: String
    var range: ClosedRange<Double>? = nil
}

private struct WhatsNewCard {
    enum Media {
        case phone(WhatsNewClip, isTilted: Bool = false)
        // The whole phone, fitted to the card's height instead of cut off by it.
        case fullPhone(WhatsNewClip)
        case screen(WhatsNewClip, zoom: CGFloat, focus: UnitPoint)
        case stats
    }

    let media: Media
    var background: Color = .defaultSheetBackground
    var height: CGFloat = BrightWhatsNewSheetV5.Constants.cardHeight
    // How far a cut-off phone sits below the card's top, as a share of its width.
    var phoneInset: CGFloat = BrightWhatsNewSheetV5.Constants.phoneInset
}

private struct WhatsNewSection: Identifiable {
    enum Layout {
        case stack
        case carousel
    }

    let title: String
    let detail: String
    let layout: Layout
    let cards: [WhatsNewCard]

    var id: String { title }

    private typealias Constants = BrightWhatsNewSheetV5.Constants

    // Clip stretches are in seconds, cut where each recording moves to its next scene.
    static let all: [Self] = [
        .init(
            title: "Lighthouse",
            detail: "An AI layer that reads all of Bright. Use a leading model or bring your own API key.",
            layout: .stack,
            cards: [
                .init(media: .phone(.init(name: "whats_new_lighthouse_v5", range: 3.6...18.1)), phoneInset: Constants.raisedPhoneInset),
                .init(
                    media: .screen(.init(name: "whats_new_lighthouse_v5", range: 18.1...34.5), zoom: 1.1, focus: .init(x: 0.5, y: 0.45)),
                    background: .defaultBlack,
                    height: Constants.wideCardHeight
                ),
            ]
        ),
        .init(
            title: "Waypoint",
            detail: "Set short and long term health goals, and Bright retunes every widget, from sleep to nutrition, to keep you on course.",
            layout: .carousel,
            cards: [
                .init(media: .phone(.init(name: "whats_new_waypoint_v5"))),
                .init(
                    media: .screen(.init(name: "whats_new_waypoint_v5", range: 0...16), zoom: 1.35, focus: .init(x: 0.5, y: 0.33)),
                    background: .defaultBlack
                ),
            ]
        ),
        .init(
            title: "Vault",
            detail: "Your genetic, lifestyle, wearable and clinical data in one place, ready to review or share with anyone via a link.",
            layout: .carousel,
            cards: [
                .init(media: .phone(.init(name: "whats_new_vault_v5", range: 0...13.2))),
                .init(media: .phone(.init(name: "whats_new_vault_v5", range: 13.2...19.5))),
            ]
        ),
        .init(
            title: "Guided Testing",
            detail: "Order lab tests and medical scans from labs around the world, no subscription needed, with results sent to your Vault.",
            layout: .carousel,
            cards: [
                .init(media: .phone(.init(name: "whats_new_guided_testing_v5", range: 1.5...14.6), isTilted: true)),
                .init(media: .stats),
            ]
        ),
        .init(
            title: "Exercise Planner",
            detail: "Import or generate workouts and runs, learn form from 3D guides, plan routes before you head out, and track every set.",
            layout: .carousel,
            cards: [
                .init(media: .phone(.init(name: "whats_new_exercise_v5", range: 0...7))),
                .init(media: .fullPhone(.init(name: "whats_new_exercise_v5", range: 7...21))),
                .init(media: .fullPhone(.init(name: "whats_new_exercise_v5", range: 21...33.5))),
                .init(media: .fullPhone(.init(name: "whats_new_exercise_v5", range: 33.5...45.6))),
            ]
        ),
        .init(
            title: "Atlas",
            detail: "A global health monitor built on real-time Bright data, so you can see how your health compares with people like you.",
            layout: .carousel,
            cards: [
                .init(media: .phone(.init(name: "whats_new_atlas_v5", range: 0...11.2)), background: .defaultBlack),
                .init(media: .phone(.init(name: "whats_new_atlas_v5", range: 11.2...23.9)), background: .defaultBlack),
            ]
        ),
    ]
}

#Preview {
    BrightWhatsNewSheetV5()
}
