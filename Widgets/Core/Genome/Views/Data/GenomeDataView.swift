//
//  GenomeView.swift
//  DNA
//
//  BrightDNAStrandV5 on black with base-pair annotations. Tap a rung to
//  select it and show its data in the bottom right.
//

import SwiftUI
import simd

struct ProjectedRung {
    let index: Int
    var screen: CGPoint
    var screenA: CGPoint
    var screenB: CGPoint
    var visible: Bool
}

@MainActor
@Observable
final class GenomeState {
    var yaw: Float = 0.6
    var distance: Float = 3.0           // fixed (no zoom); close framing of the strand
    var panY: Float = 0                 // scroll position along the strand
    var panVelocity: Float = 0          // momentum after releasing a scroll (world units/sec)
    var spinVelocity: Float = 0         // momentum after releasing a twist (rad/sec)
    var selectedRung: Int?
    var markers: [GenomeDataMarker] = []
    var rungs: [ProjectedRung] = []
    var contentHeight: Float = BrightDNAStrandBuilderV5.height(for: BrightDNAStrandBuilderV5.fallbackRungCount)
    // Per-rung 0…1 selection fade, advanced each frame by the renderer so the
    // annotation colours/box can animate in and out.
    var selectionFade: [Int: Float] = [:]
    var isInteracting = false           // true only while a drag is in progress
    var isOnScreen = false              // the entrance waits for this, so a swipe to Data still sees it
}

// MARK: - Root

struct GenomeDataView: View {
    var markers: [GenomeDataMarker] = []
    var isActive = true
    var focus: Binding<String?> = .constant(nil)

    @State private var state = GenomeState()
    @State private var selectedSection = 0
    // The page is screen-tall but sits under the title and tabs, so its bottom runs off screen by this much.
    @State private var hiddenBelow: CGFloat = 0
    // The dock's top edge and this view's bottom, on screen, so the description can sit just above the dock.
    @State private var dockTop: CGFloat?
    @State private var viewBottom: CGFloat = 0

    var body: some View {
        ZStack {
            Color.defaultBackground.ignoresSafeArea()
            BrightDNAStrandV5(state: state)
                .ignoresSafeArea()
                .mask(edgeFade)
            GenomeRungAnnotations(state: state)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .mask(edgeFade)
        }
        .overlay(alignment: .topLeading) {
            if let marker = selectedMarker {
                GenomeStrandMarkerHeader(marker: marker)
                    .id(marker.id)
                    .padding(.horizontal, .spacing4x)
                    .padding(.top, .spacing3x)
                    .transition(.opacity.combined(with: .offset(y: -.spacing2x)))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if let meaning = selectedMarker?.meaning, !meaning.isEmpty {
                GenomeStrandMarkerMeaning(meaning: meaning)
                    .padding(.horizontal, .spacing4x)
                    .padding(.bottom, descriptionBottomGap)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .id(selectedMarker?.id)
                    .transition(.genomeSwirl)
            }
        }
        .overlay(alignment: .trailing) {
            if !state.markers.isEmpty {
                sectionSelector
                    .padding(.trailing, .spacing1x)
                    .padding(.bottom, .spacing10x + .spacing4x + hiddenBelow)
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).maxY } action: { viewBottom = $0 }
        .onAppear { dockTop = Self.dockTop() }
        .onGeometryChange(for: CGFloat.self) { proxy in
            max(0, proxy.size.height - (proxy.bounds(of: .scrollView)?.maxY ?? proxy.size.height))
        } action: { hiddenBelow = $0 }
        .animation(.brightBouncy, value: state.selectedRung)
        .onChange(of: isActive, initial: true) { _, active in
            if active { state.isOnScreen = true }
        }
        .onAppear { state.markers = markers }
        .onChange(of: markers) { _, new in state.markers = new }
        .onChange(of: focus.wrappedValue, initial: true) { _, name in
            guard let name, let index = markers.firstIndex(where: { $0.canonicalName == name }) else { return }
            state.markers = markers
            state.panVelocity = 0
            state.spinVelocity = 0
            state.selectedRung = index
            focus.wrappedValue = nil
        }
        .onChange(of: state.selectedRung) { _, rung in
            guard let rung, !state.markers.isEmpty else { return }
            let count = state.markers.count
            withAnimation(.brightBouncy) {
                selectedSection = count - 1 - ((rung % count) + count) % count
            }
        }
    }

    // Same gap above the dock as the badge has below the pills.
    private var descriptionBottomGap: CGFloat {
        guard let dockTop else { return .spacing12x + hiddenBelow }
        return max(0, viewBottom - dockTop) + .spacing3x
    }

    private static func dockTop() -> CGFloat? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        func tabBarController(in controller: UIViewController?) -> UITabBarController? {
            guard let controller else { return nil }
            if let tabs = controller as? UITabBarController { return tabs }
            return controller.children.lazy.compactMap { tabBarController(in: $0) }.first
                ?? tabBarController(in: controller.presentedViewController)
        }
        guard let bar = tabBarController(in: window?.rootViewController)?.tabBar, !bar.isHidden else { return nil }
        return bar.convert(bar.bounds, to: nil).minY
    }

    private var sectionSelector: some View {
        let count = max(state.markers.count, 1)
        return BrightDotSelectorV5(
            items: (1...count).map { BrightDotSelectorItem(title: "\($0)") },
            selectedIndex: $selectedSection
        ) { i in
            state.panVelocity = 0
            state.spinVelocity = 0
            if state.selectedRung != nil {
                state.selectedRung = count - 1 - i
            } else {
                state.panY = state.contentHeight * (0.5 - (Float(i) + 0.5) / Float(count))
            }
        }
    }

    private var selectedMarker: GenomeDataMarker? {
        guard let rung = state.selectedRung, !state.markers.isEmpty else { return nil }
        let count = state.markers.count
        return state.markers[((rung % count) + count) % count]
    }

    // Fades the strand (and its annotations) out at the top and bottom edges.
    private var edgeFade: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.14),
                .init(color: .black, location: 0.86),
                .init(color: .clear, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Rung annotations (base-pair letters, connecting line, end dots)

private struct GenomeRungAnnotations: View {
    let state: GenomeState

    // Fallback base-pair strings for rungs without a genotype marker. Cycles
    // A-T, T-A, G-C, C-G so the strand still reads as DNA when data is absent.
    private static let letterPairs: [(base: String, pair: String)] = [
        ("A", "T"), ("T", "A"), ("G", "C"), ("C", "G"),
    ]

    private func marker(for index: Int) -> GenomeDataMarker? {
        guard !state.markers.isEmpty else { return nil }
        return state.markers[index % state.markers.count]
    }

    private static let dotRadius: CGFloat = 3.5
    private static let letterOffset: CGFloat = 20
    private static let boxSize = CGSize(width: 22, height: 28)
    // Fade the annotation out as the rung turns edge-on (its two ends converge)
    // and back in as it opens up on the other side.
    private static let fadeOutLength: CGFloat = 50
    private static let fadeInLength: CGFloat = 110
    // Only rungs near the middle of the screen are labelled: full within the
    // inner radius, gone past the outer, as fractions of the view height.
    private static let centerInner: CGFloat = 0.1
    private static let centerOuter: CGFloat = 0.24

    var body: some View {
        Canvas(rendersAsynchronously: true) { ctx, size in
            for rung in state.rungs where rung.visible {
                draw(rung, in: ctx, size: size)
            }
        }
    }

    private func draw(_ rung: ProjectedRung, in ctx: GraphicsContext, size: CGSize) {
        let a = rung.screenA
        let b = rung.screenB

        // Cull only when the whole annotation (letters included) is off-screen,
        // so it slides past the edges instead of popping.
        let margin = Self.letterOffset + Self.boxSize.height
        let bounds = CGRect(origin: .zero, size: size).insetBy(dx: -margin, dy: -margin)
        guard bounds.contains(a) || bounds.contains(b) else { return }

        let dx = b.x - a.x
        let dy = b.y - a.y
        let length = (dx * dx + dy * dy).squareRoot()

        let alpha = min(max((length - Self.fadeOutLength) / (Self.fadeInLength - Self.fadeOutLength), 0), 1)
        guard alpha > 0.01 else { return }
        let dir = CGPoint(x: dx / length, y: dy / length)

        // 0…1 selection fade drives line/letter opacity and the box reveal.
        let t = Double(state.selectionFade[rung.index] ?? 0)

        // The selected rung always shows, wherever it is.
        let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        let fromCenter = hypot(mid.x - size.width / 2, mid.y - size.height / 2) / size.height
        let centerRamp = min(max((Self.centerOuter - fromCenter) / (Self.centerOuter - Self.centerInner), 0), 1)
        let central = max(centerRamp * centerRamp * (3 - 2 * centerRamp), t)
        guard central > 0.01 else { return }

        // While a rung is selected the others fade away, so only its bar shows.
        let focus = Double(state.selectionFade.values.max() ?? 0)
        let unfocused = 1 - focus * (1 - t)

        var ctx = ctx
        ctx.opacity = alpha * central * unfocused
        let rungMarker = marker(for: rung.index)
        let accent = Color.defaultOrange

        var line = Path()
        line.move(to: a)
        line.addLine(to: b)
        ctx.stroke(
            line,
            with: .color(accent.opacity(0.25 + 0.75 * t)),
            lineWidth: 0.5
        )

        for point in [a, b] {
            let dot = Path(ellipseIn: CGRect(
                x: point.x - Self.dotRadius,
                y: point.y - Self.dotRadius,
                width: Self.dotRadius * 2,
                height: Self.dotRadius * 2
            ))
            ctx.fill(dot, with: .color(accent))
        }

        let letters = rungMarker?.basePair ?? Self.letterPairs[rung.index % Self.letterPairs.count]
        let letterA = CGPoint(x: a.x - dir.x * Self.letterOffset, y: a.y - dir.y * Self.letterOffset)
        let letterB = CGPoint(x: b.x + dir.x * Self.letterOffset, y: b.y + dir.y * Self.letterOffset)

        drawLetter(letters.0, at: letterA, accent: accent, selection: t, in: ctx)
        drawLetter(letters.1, at: letterB, accent: accent, selection: t, in: ctx)
    }

    private func drawLetter(
        _ letter: String,
        at point: CGPoint,
        accent: Color,
        selection t: Double,
        in ctx: GraphicsContext
    ) {
        ctx.draw(
            Text(letter)
                .font(.standard(size: .heading, weight: .light))
                .foregroundColor(accent),
            at: point
        )

        if t > 0.01 {
            // Box grows from 80% and fades in with the selection.
            let scale = 0.8 + 0.2 * t
            let box = CGRect(
                x: point.x - Self.boxSize.width * scale / 2,
                y: point.y - Self.boxSize.height * scale / 2,
                width: Self.boxSize.width * scale,
                height: Self.boxSize.height * scale
            )
            ctx.stroke(
                Path(roundedRect: box.insetBy(dx: 0.25, dy: 0.25), cornerRadius: 6),
                with: .color(accent.opacity(0.6 * t)),
                lineWidth: 0.5
            )
        }
    }
}

private struct GenomeStrandMarkerHeader: View {
    let marker: GenomeDataMarker

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            if let level = marker.evidenceLevel {
                GenomeEvidenceChip(level: GenomeEvidenceLevel(level))
            }

            BrightText(marker.gene, size: .standout2, color: .defaultOrange, weight: .medium)

            if let result = marker.resultLabel ?? (marker.rawValue.isEmpty ? nil : marker.rawValue) {
                BrightText(Self.lined(result), size: .body1, weight: .medium)
            }

            if let rsid = marker.rsid {
                BrightText(rsid, size: .body2, color: .lightTextColor, weight: .regular)
                    .monospaced()
            }
        }
        .frame(maxWidth: GenomeStrandPanel.width, alignment: .leading)
    }

    // "One copy of C and one copy of T" reads as one allele per line.
    private static func lined(_ result: String) -> String {
        result
            .components(separatedBy: " and ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: "\n")
    }
}

// Swirls the description in from the bottom-right corner: small, turned and faded to full.
private struct GenomeSwirl: ViewModifier {
    let progress: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(0.3 + 0.7 * progress, anchor: .bottomTrailing)
            .rotationEffect(.degrees(-20 * (1 - progress)), anchor: .bottomTrailing)
            .opacity(progress)
    }
}

private extension AnyTransition {
    static var genomeSwirl: AnyTransition {
        .modifier(active: GenomeSwirl(progress: 0), identity: GenomeSwirl(progress: 1))
            .animation(.brightBouncy)
    }
}

private struct GenomeStrandMarkerMeaning: View {
    let meaning: String

    @State private var textHeight: CGFloat = 0

    // A short line hugs its text; a longer one wraps at the panel width.
    var body: some View {
        ViewThatFits(in: .horizontal) {
            card(text.fixedSize())
            card(text.fixedSize(horizontal: false, vertical: true))
        }
        .frame(width: GenomeStrandPanel.width + .spacing2x * 2, alignment: .bottomTrailing)
        .fixedSize(horizontal: false, vertical: true)
    }

    // Up to about 280 characters shows in full; anything longer scrolls in place.
    private func card(_ content: some View) -> some View {
        Group {
            if textHeight > GenomeStrandPanel.meaningHeight {
                ScrollView(showsIndicators: false) { content }
                    .frame(height: GenomeStrandPanel.meaningHeight)
            } else {
                content
            }
        }
        .padding(.spacing2x)
        .modifier(BrightGlassEffectV5(shape: .roundedRect, cornerRadius: .cardCornerRadius, interactive: false))
    }

    private var text: some View {
        BrightText(meaning, size: .body3, color: .lightTextColor, weight: .regular)
            .multilineTextAlignment(.trailing)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { textHeight = $0 }
    }
}

private enum GenomeStrandPanel {
    static let width: CGFloat = 240
    static let meaningHeight: CGFloat = .spacing12x * 2
}

#Preview {
    GenomeDataView()
}
