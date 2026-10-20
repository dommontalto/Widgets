//
//  WhatsNewMoreSceneV5.swift
//  Widgets
//

import SwiftUI

struct WhatsNewMoreSceneV5: View {
    let isActive: Bool

    @State private var selected = WhatsNewMoreItem.all[0]
    @State private var tapTick = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private typealias Reveal = BrightWhatsNewSheetV5.Constants

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            VStack(alignment: .leading, spacing: .spacing2x) {
                BrightText("And so much more.", size: .standout1, color: .semiLightTextColor, weight: .regular)
                    .whatsNewReveal(isActive) { content, hidden in
                        content
                            .opacity(1 - hidden)
                            .offset(x: -hidden * Reveal.itemSlide)
                            .blur(radius: hidden * Reveal.revealBlur)
                    }

                BrightText("Tap anything to learn more.", size: .body1, color: .lightTextColor, weight: .regular)
                    .whatsNewReveal(isActive, delay: Reveal.revealStagger) { content, hidden in
                        content
                            .opacity(1 - hidden)
                            .offset(y: hidden * Reveal.textRise)
                            .blur(radius: hidden * Reveal.revealBlur)
                    }
            }
            .padding(.horizontal, .spacing5x)
            .padding(.top, .spacing4x)

            VStack(spacing: .spacing2x) {
                ForEach(Array(WhatsNewMoreItem.rows.enumerated()), id: \.offset) { index, row in
                    WhatsNewMarquee(
                        items: row,
                        selected: selected,
                        isReversed: index.isMultiple(of: 2) == false,
                        speed: Constants.speeds[index % Constants.speeds.count],
                        isAnimating: isActive && !reduceMotion,
                        onSelect: select
                    )
                    .whatsNewReveal(isActive, delay: Reveal.revealStagger * Double(index + 2)) { [index] content, hidden in
                        content
                            .opacity(1 - hidden)
                            .offset(x: hidden * (index.isMultiple(of: 2) ? 1 : -1) * Reveal.mediaRise)
                    }
                }
            }
            .padding(.top, .spacing5x)

            Spacer(minLength: .spacing4x)

            WhatsNewMoreDetail(item: selected)
                .padding(.horizontal, .spacing3x)
                .padding(.bottom, .spacing4x)
                .whatsNewReveal(isActive, delay: Reveal.revealStagger * 5) { content, hidden in
                    content
                        .opacity(1 - hidden)
                        .scaleEffect(1 - hidden * Reveal.mediaShrink, anchor: .bottom)
                        .offset(y: hidden * Reveal.mediaRise)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .brightHapticV5(.light, trigger: tapTick)
        .task(id: Spotlight(isActive: isActive, tapTick: tapTick)) {
            guard isActive else {
                selected = WhatsNewMoreItem.all[0]
                return
            }
            // A tap holds the spotlight longer before it starts wandering again.
            var hold = tapTick == 0 ? Constants.spotlightHold : Constants.tapHold
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(hold))
                } catch {
                    return
                }
                hold = Constants.spotlightHold
                let index = WhatsNewMoreItem.all.firstIndex { $0.id == selected.id } ?? 0
                withAnimation(.smooth(duration: Constants.crossFade)) {
                    selected = WhatsNewMoreItem.all[(index + 1) % WhatsNewMoreItem.all.count]
                }
            }
        }
    }

    private func select(_ item: WhatsNewMoreItem) {
        tapTick += 1
        withAnimation(.smooth(duration: Constants.crossFade)) {
            selected = item
        }
    }

    private struct Spotlight: Equatable {
        let isActive: Bool
        let tapTick: Int
    }

    private enum Constants {
        static let speeds: [Double] = [18, 24, 14]
        static let spotlightHold: Double = 3.2
        static let tapHold: Double = 6
        static let crossFade: Double = 0.45
    }
}

// MARK: - Marquee

private struct WhatsNewMarquee: View {
    let items: [WhatsNewMoreItem]
    let selected: WhatsNewMoreItem
    let isReversed: Bool
    // Points per second.
    let speed: Double
    let isAnimating: Bool
    let onSelect: (WhatsNewMoreItem) -> Void

    @State private var rowWidth: CGFloat = 0

    var body: some View {
        TimelineView(.animation(paused: !isAnimating)) { timeline in
            HStack(spacing: .spacing1x) {
                chips
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { rowWidth = $0 + .spacing1x }
                chips
            }
            .fixedSize()
            .offset(x: offset(at: timeline.date))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: Constants.edgeFade),
                    .init(color: .black, location: 1 - Constants.edgeFade),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private var chips: some View {
        HStack(spacing: .spacing1x) {
            ForEach(items) { item in
                WhatsNewMoreChip(item: item, isSelected: item.id == selected.id) {
                    onSelect(item)
                }
            }
        }
    }

    private func offset(at date: Date) -> CGFloat {
        guard rowWidth > 0 else { return .zero }
        let travelled = CGFloat(date.timeIntervalSinceReferenceDate * speed).truncatingRemainder(dividingBy: rowWidth)
        return isReversed ? travelled - rowWidth : -travelled
    }

    private enum Constants {
        static let edgeFade: CGFloat = 0.08
    }
}

private struct WhatsNewMoreChip: View {
    let item: WhatsNewMoreItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacing1x) {
                WhatsNewMoreIcon(item: item, size: Constants.iconSize)
                BrightText(item.title, size: .body1, color: isSelected ? .textColor : .semiLightTextColor, weight: .regular)
            }
            .padding(.horizontal, .spacing2x)
            .frame(height: Constants.height)
            .background(isSelected ? item.color.opacity(.minimalOpacity) : Color.textColor.opacity(.finalBossLowOpacity), in: Capsule())
            .overlay {
                Capsule().stroke(isSelected ? item.color.opacity(.lowOpacity) : Color.textColor.opacity(.ultraLowOpacity), lineWidth: Constants.stroke)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.brightEaseInOut, value: isSelected)
    }

    private enum Constants {
        static let iconSize: FontSizes = .subheading2
        static let height: CGFloat = 40
        static let stroke: CGFloat = 1
    }
}

// MARK: - Detail

private struct WhatsNewMoreDetail: View {
    let item: WhatsNewMoreItem

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: .spacing2x) {
                WhatsNewMoreIcon(item: item, size: Constants.iconSize)
                    .shadow(color: item.color.opacity(.lowOpacity), radius: .spacing2x)
                    .padding(.bottom, .spacing05x)

                BrightText(item.title, size: .standout3, weight: .regular)

                BrightText(item.detail, size: .body1, color: .lightTextColor, weight: .regular)
                    .lineSpacing(.lineSpacingMedium)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .id(item.id)
            .transition(.blurReplace)
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, minHeight: Constants.minHeight, alignment: .topLeading)
        .background(alignment: .topLeading) {
            Circle()
                .fill(item.color)
                .frame(width: Constants.glowSize, height: Constants.glowSize)
                .blur(radius: Constants.glowBlur)
                .opacity(.veryLowOpacity)
                .offset(x: -Constants.glowSize / 4, y: -Constants.glowSize / 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))
        .modifier(BrightGlassEffectV5(shape: .roundedRect, interactive: false))
    }

    private enum Constants {
        static let iconSize: FontSizes = .standout1
        static let minHeight: CGFloat = 190
        static let glowSize: CGFloat = 180
        static let glowBlur: CGFloat = 50
    }
}

private struct WhatsNewMoreIcon: View {
    let item: WhatsNewMoreItem
    let size: FontSizes

    var body: some View {
        HStack(spacing: .spacing05x) {
            ForEach(item.icons, id: \.self) { icon in
                switch icon {
                case .symbol(let name):
                    Image(systemName: name)
                        .font(.standardSFPro(size: size, weight: .regular))
                        .foregroundStyle(item.color)
                case .image(let name):
                    Image(name)
                        .resizable()
                        .scaledToFit()
                }
            }
        }
        .frame(height: size.rawValue)
    }
}

// MARK: - Data

private struct WhatsNewMoreItem: Identifiable, Equatable {
    enum Icon: Hashable {
        case symbol(String)
        case image(String)
    }

    let id: String
    let icons: [Icon]
    let color: Color
    let detail: String

    var title: String { id }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }

    static var rows: [[Self]] {
        let third = (all.count + 2) / 3
        return stride(from: 0, to: all.count, by: third).map { Array(all[$0 ..< min($0 + third, all.count)]) }
    }

    static let all: [Self] = [
        .init(
            id: "Rebuilt UX/UI",
            icons: [.symbol("hare.fill")],
            color: .defaultSkyBlue,
            detail: "A faster, smoother and more stable Bright OS."
        ),
        .init(
            id: "Android and Web-App",
            icons: [.image(ImageNames.whatsNewAndroidWebIconV5)],
            color: .defaultGreen,
            detail: "Bright on every screen, with full sync between your phone, Android and the web."
        ),
        .init(
            id: "3D Avatar",
            icons: [.symbol("figure")],
            color: .defaultPink,
            detail: "Track muscle and cardio progress with a dedicated 3D avatar."
        ),
        .init(
            id: "Workout Library",
            icons: [.symbol("figure.rolling"), .symbol("figure.outdoor.cycle"), .symbol("figure.strengthtraining.traditional")],
            color: .defaultOrange,
            detail: "Explore over 800 motion-captured workouts, stretches and yoga poses on our 3D human model."
        ),
        .init(
            id: "Check-Ins",
            icons: [.symbol("person.badge.clock.fill")],
            color: .defaultSkyBlue,
            detail: "Bright keeps you pointed at your Waypoint by reviewing your data and adapting its suggestions."
        ),
        .init(
            id: "Explore",
            icons: [.symbol("map")],
            color: .defaultGreen,
            detail: "Filter the internet with your health data, so you only see products and services that suit you."
        ),
        .init(
            id: "Genome",
            icons: [.image(ImageNames.whatsNewDnaIconV5)],
            color: .defaultPurple,
            detail: "Upload or order a Whole-Genome Sequence so Bright can sync your lifestyle, wearable, clinical and genome data into the full picture."
        ),
        .init(
            id: "Experiments",
            icons: [.symbol("testtube.2")],
            color: .defaultYellow,
            detail: "Create observational studies across Bright users to test a hypothesis."
        ),
        .init(
            id: "Ask",
            icons: [.symbol("sparkles.2")],
            color: .defaultCyan,
            detail: "Answers to your health questions, drawn from Bright’s aggregated dataset alone."
        ),
        .init(
            id: "Global Health Ranking",
            icons: [.symbol("globe")],
            color: .defaultSkyBlue,
            detail: "Bright ranks your data against Atlas, relative to people with a similar health profile."
        ),
        .init(
            id: "Watch App",
            icons: [.symbol("applewatch")],
            color: .defaultGreen,
            detail: "A standalone Apple Watch app for the workout and running planner."
        ),
        .init(
            id: "Automated Journaling",
            icons: [.symbol("repeat")],
            color: .defaultPink,
            detail: "Bright records events to your Daily Log throughout the day, without manual entry."
        ),
        .init(
            id: "Social Sharing",
            icons: [.symbol("square.and.arrow.up")],
            color: .defaultOrange,
            detail: "Share what you see in any widget or section straight to social media."
        ),
        .init(
            id: "Customisation",
            icons: [.image(ImageNames.whatsNewWidgetsIconV5)],
            color: .defaultSkyBlue,
            detail: "Rearrange, resize and restyle every widget to suit you."
        ),
        .init(
            id: "API/MCP",
            icons: [.symbol("point.3.connected.trianglepath.dotted")],
            color: .defaultPink,
            detail: "Read and write all your Bright data over API and MCP, at no extra cost."
        ),
        .init(
            id: "Integrations",
            icons: [.image(ImageNames.whatsNewIntegrationsIconV5)],
            color: .defaultGreen,
            detail: "Over 50 direct integrations for wearables and apps, including Amazfit/Helio, Strava and Hevy."
        ),
        .init(
            id: "Languages",
            icons: [.symbol("character.bubble")],
            color: .defaultCyan,
            detail: "Bright is now available in over 50 languages."
        ),
        .init(
            id: "Compliance & Security",
            icons: [.symbol("lock.shield")],
            color: .defaultRed,
            detail: "HIPAA, GDPR, ISO 27001 and SOC 2 compliant, with AES-256 encryption."
        ),
    ]
}

#Preview {
    WhatsNewMoreSceneV5(isActive: true)
        .background(Color.defaultSheetBackground)
}
