//
//  LighthouseModelWheel.swift
//  Widgets
//

import SwiftUI

// The choices laid round a dial on the right edge. Scrolling turns the dial and
// the row level with the handle is the pick; tapping any other row turns the
// dial to it. The dial keeps its own position and hands the pick out only once
// it settles, so the screen redrawing mid-scroll can't feed back into it.
struct LighthouseModelWheel: View {
    @Binding var selection: LighthouseModelChoice

    @State private var scrolled: LighthouseModelChoice?
    @State private var hasAppeared = false

    private let choices = LighthouseModelChoice.allCases

    var body: some View {
        // Meant to fill the screen, safe areas and all, so the snap point, the
        // handle and the curve all share the screen's middle.
        GeometryReader { proxy in
            let height = proxy.size.height
            let centreY = proxy.frame(in: .global).midY

            ZStack(alignment: .topLeading) {
                rim(x: proxy.size.width - Constants.rimTrailing, midY: height / 2)

                dial(height: height, centreY: centreY)
                    .offset(x: hasAppeared ? .zero : Constants.enterOffset)
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
        ScrollView(.vertical) {
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
            .background(ScrollViewBounceOff())
        }
        .contentMargins(.vertical, max(.zero, (height - Constants.rowHeight) / 2), for: .scrollContent)
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

                BrightText(title(of: choice), size: .body1, color: isSelected ? .textColor : .lightTextColor, weight: .medium)
                    .lineLimit(1)
                    .padding(.horizontal, isSelected ? .spacing2x : .spacing0x)
                    .padding(.vertical, isSelected ? .spacing1x : .spacing0x)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(Color.defaultCards)
                                .strokeBorder(Color.textColor.opacity(.ultraLowOpacity))
                        }
                    }

                icon(of: choice)
                    .frame(width: Constants.tileWidth, height: Constants.tileHeight)
                    .background {
                        Capsule()
                            .fill(isSelected ? tint(of: choice).opacity(.minimalOpacity) : Color.textColor.opacity(.finalBossLowOpacity))
                            .strokeBorder(isSelected ? tint(of: choice) : .clear, lineWidth: Constants.selectedStroke)
                    }
            }
            .padding(.trailing, Constants.rimTrailing + Constants.rimGap)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.brightSnappy, value: isSelected)
    }

    // The dial's rim, with the handle marking the live row.
    private func rim(x: CGFloat, midY: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .stroke(Color.textColor.opacity(.minimalOpacity), lineWidth: Constants.rimWidth)
                .frame(width: Constants.dialRadius * 2, height: Constants.dialRadius * 2)
                .position(x: x + Constants.dialRadius, y: midY)

            Capsule()
                .fill(Color.textColor.opacity(.lowOpacity))
                .frame(width: Constants.handleWidth, height: Constants.handleHeight)
                .position(x: x + Constants.handleWidth / 2 - Constants.handleInset, y: midY)
        }
        .opacity(hasAppeared ? .opaque : .zero)
        .scaleEffect(hasAppeared ? 1 : Constants.rimStartScale, anchor: .trailing)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func icon(of choice: LighthouseModelChoice) -> some View {
        if let model = choice.model {
            Image(model.tierImageName)
                .resizable()
                .scaledToFill()
                .frame(width: Constants.logoSize, height: Constants.logoSize)
                .clipShape(Circle())
        } else {
            Image(systemName: LighthouseModelChoice.apiKeySymbol)
                .font(.standard(size: .heading, weight: .regular))
                .foregroundStyle(Color.textColor)
        }
    }

    private func tint(of choice: LighthouseModelChoice) -> Color {
        choice.model?.tint ?? .textColor
    }

    private func title(of choice: LighthouseModelChoice) -> String {
        choice.model?.displayName ?? LighthouseModelChoice.apiKeyTitle
    }

    private typealias Constants = LighthouseModelWheelConstants
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
    // margins, which would put the curve's flat point below the handle.
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

// The dial stops dead at its first and last rows: a bounce past them drags the
// rows off the handle. SwiftUI only turns bouncing off for content that fits,
// so this reaches the scroll view it sits in.
private struct ScrollViewBounceOff: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        DispatchQueue.main.async {
            let scrollView = sequence(first: view, next: \.superview)
                .lazy
                .compactMap { $0 as? UIScrollView }
                .first
            scrollView?.bounces = false
        }
    }
}

private enum LighthouseModelWheelConstants {
    static let rowHeight: CGFloat = .spacing12x + .spacing1x
    static let tileWidth: CGFloat = .spacing12x + .spacing3x
    static let tileHeight: CGFloat = .spacing10x
    static let logoSize: CGFloat = .spacing6x
    static let selectedStroke: CGFloat = 1.5
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
    static let rimWidth: CGFloat = 1
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
