//
//  LighthouseModelWheel.swift
//  Widgets
//

import SwiftUI

// The choices laid round a dial on the right edge. Scrolling turns the dial and
// the row level with the middle is the pick, drawn larger; tapping any other row turns the
// dial to it. The dial keeps its own position and hands the pick out only once
// it settles, so the screen redrawing mid-scroll can't feed back into it.
struct LighthouseModelWheel: View {
    @Binding var selection: LighthouseModelChoice
    var slidesIn = true
    var glow: Double = .zero

    // The selected row's logo: drawn this size, its centre this far in from the right edge, level with the middle.
    static var selectedLogoSize: CGFloat { Constants.logoSize * Constants.selectedScale }
    static var selectedLogoTrailing: CGFloat { Constants.rimTrailing + Constants.rimGap + selectedLogoSize / 2 }

    @State private var scrolled: LighthouseModelChoice?
    @State private var hasAppeared = false
    // How much deeper the scroll view's own inset runs at the top than the bottom.
    @State private var topExcess: CGFloat = .zero

    private let choices = LighthouseModelChoice.allCases

    var body: some View {
        // Meant to fill the screen, safe areas and all, so the snap point and the
        // curve share the screen's middle.
        GeometryReader { proxy in
            let height = proxy.size.height

            ZStack(alignment: .topLeading) {
                rim(x: proxy.size.width - Constants.rimTrailing, midY: height / 2)

                dial(height: height, centreY: proxy.frame(in: .global).midY)
                    .offset(x: hasAppeared || !slidesIn ? .zero : Constants.enterOffset)
                    .opacity(hasAppeared ? .opaque : .zero)
            }
        }
        .onAppear {
            scrolled = selection
            withAnimation(.brightLiquid) { hasAppeared = true }
        }
        .brightHapticV5(.light, trigger: scrolled)
    }

    private func dial(height: CGFloat, centreY: CGFloat) -> some View {
        let margin = max(.zero, (height - Constants.rowHeight) / 2)
        return ScrollView(.vertical) {
            VStack(spacing: .spacing0x) {
                ForEach(choices, id: \.self) { choice in
                    row(choice)
                        .frame(height: Constants.rowHeight)
                        .visualEffect { content, proxy in
                            let placement = DialPlacement(proxy: proxy, centreY: centreY, viewportHeight: height)
                            return content
                                .offset(x: placement.offset)
                                .rotationEffect(placement.tilt, anchor: placement.pivot)
                                .scaleEffect(placement.scale, anchor: placement.pivot)
                                .opacity(placement.opacity)
                                .blur(radius: placement.blur)
                        }
                }
            }
            .scrollTargetLayout()
        }
        // The nav bar deepens the top inset past the bottom one, which let the first row
        // scroll below the middle; the top margin gives that extra back so both ends match.
        .contentMargins(.top, max(.zero, margin - topExcess), for: .scrollContent)
        .contentMargins(.bottom, margin, for: .scrollContent)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentInsets.top - geometry.contentInsets.bottom
        } action: { _, difference in
            topExcess += difference
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrolled, anchor: .center)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .ignoresSafeArea()
        .onScrollPhaseChange { _, phase in
            if phase == .idle { handOut() }
        }
    }

    private func handOut() {
        if let scrolled, scrolled != selection { selection = scrolled }
    }

    private func row(_ choice: LighthouseModelChoice) -> some View {
        let isSelected = choice == scrolled

        return Button {
            withAnimation(.brightSpring) { scrolled = choice }
            selection = choice
        } label: {
            HStack(spacing: .spacing2x) {
                Spacer(minLength: .spacing0x)

                BrightText(title(of: choice), size: .body1, weight: .medium)
                    .lineLimit(1)

                icon(of: choice)
                    .modifier(LighthouseModelGlow(color: choice.model?.tint ?? .clear, amount: isSelected ? glow : .zero))
                    .frame(width: Constants.tileWidth, height: Constants.tileWidth)
                    .opacity(isSelected ? .opaque : .lowOpacity)
            }
            .scaleEffect(isSelected ? Constants.selectedScale : 1, anchor: .trailing)
            .padding(.trailing, Constants.rimTrailing + Constants.rimGap)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.brightSnappy, value: isSelected)
    }

    // The handle marking the live row.
    private func rim(x: CGFloat, midY: CGFloat) -> some View {
        Capsule()
            .fill(Color.textColor.opacity(.lowOpacity))
            .frame(width: Constants.handleWidth, height: Constants.handleHeight)
            .position(x: x + Constants.handleWidth / 2 - Constants.handleInset, y: midY)
            .opacity(hasAppeared ? .opaque : .zero)
            .scaleEffect(hasAppeared ? 1 : Constants.rimStartScale, anchor: .trailing)
            .allowsHitTesting(false)
    }

    private func icon(of choice: LighthouseModelChoice) -> some View {
        Image(choice.model?.tierImageName ?? ImageNames.lighthouseApiKeyTierV5)
            .resizable()
            .scaledToFill()
            .frame(width: Constants.logoSize, height: Constants.logoSize)
            .clipShape(Circle())
    }

    private func title(of choice: LighthouseModelChoice) -> String {
        choice.model?.displayName ?? LighthouseModelChoice.apiKeyTitle
    }

    private typealias Constants = LighthouseModelWheelConstants
}

// A model's logo lit in its own colour, `amount` from off to full.
struct LighthouseModelGlow: ViewModifier {
    let color: Color
    let amount: Double

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(amount * Constants.strength), radius: Constants.radius * amount)
    }

    private enum Constants {
        static let radius: CGFloat = 16
        static let strength: Double = 0.45
    }
}

// Where a row sits on the dial, from how far it is above or below the middle:
// pushed right along the rim, leant round its tile like a spoke, and shrunk,
// faded and softened towards the ends.
private struct DialPlacement {
    let offset: CGFloat
    let tilt: Angle
    let pivot: UnitPoint
    let scale: CGFloat
    let opacity: Double
    let blur: CGFloat

    // Measured globally: the scroll view's own space starts inside its content
    // margins, which would put the curve's flat point below the middle.
    init(proxy: GeometryProxy, centreY: CGFloat, viewportHeight: CGFloat) {
        let distance = proxy.frame(in: .global).midY - centreY
        let angle = distance / Constants.dialRadius
        let fade = min(abs(distance) / max(viewportHeight / 2, 1), 1)

        offset = Constants.dialRadius * (1 - cos(angle))
        tilt = .radians(-angle * Constants.tiltShare)
        pivot = UnitPoint(x: 1 - Constants.tileCentre / max(proxy.size.width, 1), y: 0.5)
        scale = 1 - fade * Constants.edgeShrink
        opacity = 1 - fade * Constants.edgeFade
        blur = fade * Constants.edgeBlur
    }

    private typealias Constants = LighthouseModelWheelConstants
}

private enum LighthouseModelWheelConstants {
    static let rowHeight: CGFloat = .spacing12x + .spacing1x
    static let logoSize: CGFloat = .spacing6x
    static let tileWidth: CGFloat = logoSize
    static let selectedScale: CGFloat = 1.5
    // How far in from the right edge the rim crosses the middle.
    static let rimTrailing: CGFloat = .spacing10x
    static let rimGap: CGFloat = .spacing4x
    static let tileCentre: CGFloat = rimTrailing + rimGap + tileWidth / 2
    static let dialRadius: CGFloat = 420
    // Rows lean half as far as the dial turns, so the labels stay readable.
    static let tiltShare: Double = 0.5
    static let edgeShrink: CGFloat = 0.15
    static let edgeFade: Double = 0.8
    static let edgeBlur: CGFloat = 2
    static let handleWidth: CGFloat = .spacing6x
    static let handleHeight: CGFloat = .spacing2x
    static let handleInset: CGFloat = .spacing1x
    static let rimStartScale: CGFloat = 0.9
    static let enterOffset: CGFloat = .spacing12x
}

#Preview {
    @Previewable @State var selection = LighthouseModelChoice.model(.claude)
    LighthouseModelWheel(selection: $selection)
        .background(Color.defaultBackground)
}
