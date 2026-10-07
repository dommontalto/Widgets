//
//  BrightToastV5.swift
//  Widgets
//
//  Created by Dom Montalto on 2/10/2026.
//

import SwiftUI

// The app's one toast: a glass pill that drops out of the Dynamic Island.
// Call it from anywhere through `BrightToastPresenterV5.shared`; the root view
// hosts it once with `.brightToastHostV5()`.
//
//     BrightToastPresenterV5.shared.loading("Syncing…")
//     BrightToastPresenterV5.shared.success("Synced")
//     BrightToastPresenterV5.shared.error("Couldn't delete template")
enum BrightToastV5Kind: Equatable {
    case loading
    case success
    case error
}

struct BrightToastV5Message: Equatable {
    // Showing the same text twice still restarts the toast.
    let id = UUID()
    let kind: BrightToastV5Kind
    let text: String
}

@MainActor @Observable
final class BrightToastPresenterV5 {
    static let shared = BrightToastPresenterV5()

    private(set) var message: BrightToastV5Message?
    @ObservationIgnored private var dismissTask: Task<Void, Never>?

    // Stays up until replaced by `success` or `error`, or dismissed.
    func loading(_ text: String) {
        show(BrightToastV5Message(kind: .loading, text: text))
    }

    func success(_ text: String) {
        show(BrightToastV5Message(kind: .success, text: text))
    }

    func error(_ text: String) {
        show(BrightToastV5Message(kind: .error, text: text))
    }

    func dismiss() {
        dismissTask?.cancel()
        message = nil
    }

    private func show(_ message: BrightToastV5Message) {
        dismissTask?.cancel()
        // The pill is already open after a loading step, so a success there
        // needs less time on screen than one that has to drop out first.
        let followsLoading = self.message?.kind == .loading
        self.message = message

        let minimumHold: Duration
        switch message.kind {
        case .loading: return
        case .success: minimumHold = followsLoading ? Constants.successAfterLoadingHold : Constants.hold
        case .error: minimumHold = Constants.hold
        }
        let hold = min(max(minimumHold, readingTime(for: message.text)), Constants.maxHold)

        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: hold)
            guard !Task.isCancelled else { return }
            self?.message = nil
        }
    }

    // Long messages stay up long enough to read at a relaxed pace.
    private func readingTime(for text: String) -> Duration {
        let words = text.split(whereSeparator: \.isWhitespace).count
        return Constants.readingLeadIn + Constants.readingTimePerWord * words
    }
}

extension View {
    // Hosts the shared toast in its own window, so it shows over sheets and
    // full-screen covers too. Apply once, on the app's root view.
    func brightToastHostV5() -> some View {
        background {
            BrightToastWindowInstaller()
        }
    }

    // Shows the shared toast whenever a screen's flag turns on, then turns it
    // straight back off so the next one fires too.
    func brightToastV5(_ kind: BrightToastV5Kind, isPresented: Binding<Bool>, text: String) -> some View {
        onChange(of: isPresented.wrappedValue) { _, isShowing in
            guard isShowing else { return }
            switch kind {
            case .loading: BrightToastPresenterV5.shared.loading(text)
            case .success: BrightToastPresenterV5.shared.success(text)
            case .error: BrightToastPresenterV5.shared.error(text)
            }
            isPresented.wrappedValue = false
        }
    }
}

private struct BrightToastV5: View {
    var presenter: BrightToastPresenterV5

    @Environment(\.scenePhase) private var scenePhase
    // Lags the presenter on the way out so the pill keeps its look while it retracts.
    @State private var shown: BrightToastV5Message?
    @State private var progress: CGFloat = 0
    // The threshold shader is only needed while the pill is joined to the
    // island; once it has dropped clear, it would just alias the edges.
    @State private var isSettled = false
    @State private var isExpanded = false
    // Flips once the pill has opened, so a toast that arrives as a success
    // or error still plays the tick or cross animation in front of the user.
    @State private var isRevealed = false
    @State private var isLeaving = false
    @State private var labelSize = CGSize.zero

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                // Lays the label out at its natural size, wrapping as many lines
                // as it needs, so the pill can open to fit without the text reflowing.
                // A blank stands in for the icon so the orb doesn't animate and
                // the tick doesn't buzz twice.
                pillContent(isMeasuring: true)
                    .hidden()
                    // Measured after layout, outside the message's own transaction,
                    // so the spring has to be applied here for the pill to bounce.
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                        withAnimation(.brightBouncy) { labelSize = size }
                    }
                    // Clear of the nav bar's corner buttons either side.
                    .frame(maxWidth: proxy.size.width - Constants.sideInset * 2)

                if shown != nil {
                    island(safeArea: proxy.safeAreaInsets)
                }
            }
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
        .onChange(of: presenter.message) { _, new in
            update(to: new)
        }
    }

    private func island(safeArea: EdgeInsets) -> some View {
        let hasIsland = safeArea.top >= Constants.islandSafeAreaMin
        // Lands the pill's top on the nav bar's, level with its corner buttons on
        // every phone. Without an island it drops from just above the screen edge.
        let drop = hasIsland
            ? (safeArea.top + Constants.islandHeight) / 2
            : safeArea.top + Constants.islandHeight
        let offset = drop * progress

        return Rectangle()
            .fill(.clear)
            .frame(height: hasIsland ? safeArea.top : 0)
            .overlay(alignment: hasIsland ? .center : .top) {
                Capsule()
                    .fill(Color.defaultBlack)
                    // Slightly smaller than the real island, so it never bleeds past it.
                    .frame(width: Constants.islandWidth, height: Constants.islandHeight)
                    .opacity(scenePhase == .active ? 1 : 0)
                    .mask {
                        Capsule()
                            .padding(.top, Constants.islandInset)
                    }
                    .overlay(alignment: .top) {
                        pill
                            .scaleEffect(pillScale, anchor: .top)
                            .offset(y: offset)
                    }
                    .compositingGroup()
                    .blur(radius: Constants.blurRadius * (1 - progress))
                    .visualEffect { [isSettled, alphaThreshold = Constants.alphaThreshold] content, proxy in
                        content.layerEffect(
                            ShaderLibrary.brightAlphaThreshold(.float(alphaThreshold)),
                            maxSampleOffset: proxy.size,
                            isEnabled: !isSettled
                        )
                    }
                    .overlay(alignment: .top) {
                        pillLabel
                            .scaleEffect(pillScale, anchor: .top)
                            .offset(y: offset)
                    }
                    .offset(y: hasIsland ? 0 : -Constants.islandHeight)
            }
    }

    // The gooey drip, sized like the label laid over it. Glass can't go
    // through the threshold shader, so the glass ball rides on top and this
    // only draws the neck, thinning away as it drops.
    private var pill: some View {
        pillShape
            .fill(Color.defaultBlack)
            .frame(width: pillWidth, height: pillHeight)
            .opacity(isSettled ? 0 : 1 - progress)
    }

    // Starts about island height, so the ball doesn't poke out above it.
    private var pillScale: CGFloat {
        Constants.pillStartScale + (1 - Constants.pillStartScale) * progress
    }

    private var pillLabel: some View {
        pillContent(isMeasuring: false)
            // Pinned at its natural size while the pill opens around it.
            .frame(width: labelSize.width, height: labelSize.height)
            .frame(width: pillWidth, height: pillHeight)
            .clipShape(pillShape)
            .opacity(isExpanded ? 1 : 0)
            // Behind the island until it drops, so the ball is glass the whole way down.
            .background {
                pillShape
                    .fill(.clear)
                    .modifier(BrightGlassEffectV5(
                        shape: .roundedRect,
                        cornerRadius: .cardCornerRadius,
                        tint: .toastGlassTint,
                        interactive: false
                    ))
            }
    }

    // A capsule on one line, since the radius clamps to half its height; a longer
    // message grows downwards into a card.
    private var pillShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous)
    }

    private func pillContent(isMeasuring: Bool) -> some View {
        HStack(spacing: .spacing1x) {
            ZStack {
                if !isMeasuring {
                    icon
                }
            }
            .frame(width: Constants.iconSize, height: Constants.iconSize)

            BrightText(shown?.text ?? "", size: .subheading, color: .defaultWhite, weight: .regular)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.numericText())
                .brightShimmerV5(isActive: kind == .loading)
        }
        .padding(.vertical, .spacing1x)
        .padding(.leading, .spacing105x)
        .padding(.trailing, .spacing2x)
    }

    // The tick and cross stay mounted under the orb so flipping them plays
    // their own symbol replace and haptic.
    private var icon: some View {
        ZStack {
            BrightTickV5(isTicked: isRevealed && kind == .success)
                .opacity(kind == .success ? .opaque : .zero)
            BrightCrossV5(isCrossed: isRevealed && kind == .error)
                .opacity(kind == .error ? .opaque : .zero)
            BrightSolvingOrbV5(size: Constants.orbSize)
                .environment(\.colorScheme, .dark)
                .scaleEffect(kind == .loading ? 1 : Constants.orbExitScale)
                .opacity(kind == .loading ? .opaque : .zero)
        }
    }

    private var kind: BrightToastV5Kind {
        shown?.kind ?? .loading
    }

    private var pillWidth: CGFloat {
        isExpanded ? labelSize.width : Constants.pillHeight
    }

    private var pillHeight: CGFloat {
        isExpanded ? max(labelSize.height, Constants.pillHeight) : Constants.pillHeight
    }

    private func update(to new: BrightToastV5Message?) {
        guard let new else {
            retract()
            return
        }

        if shown == nil || isLeaving {
            shown = new
            dropOut()
        } else {
            withAnimation(.brightBouncy) { shown = new }
        }
    }

    private func dropOut() {
        isLeaving = false
        isSettled = false
        withAnimation(Constants.drop) {
            progress = 1
        } completion: {
            guard presenter.message != nil, !isLeaving else { return }
            isSettled = true
            withAnimation(.brightBouncy) {
                isExpanded = true
            } completion: {
                withAnimation(.brightBouncy) { isRevealed = true }
            }
        }
    }

    private func retract() {
        isLeaving = true
        withAnimation(.brightSnappy) {
            isExpanded = false
        } completion: {
            guard presenter.message == nil else { return }
            isSettled = false
            isRevealed = false
            withAnimation(Constants.retract) {
                progress = 0
            } completion: {
                guard presenter.message == nil else { return }
                shown = nil
                isLeaving = false
            }
        }
    }
}

// A zero-size view in the app's hierarchy that finds its window scene and
// gives the toast a window of its own on it.
private struct BrightToastWindowInstaller: UIViewRepresentable {
    func makeUIView(context: Context) -> BrightToastInstallerView {
        BrightToastInstallerView()
    }

    func updateUIView(_ uiView: BrightToastInstallerView, context: Context) {}
}

private final class BrightToastInstallerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _) in
            view.syncStyle()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let scene = window?.windowScene else { return }
        BrightToastWindow.install(in: scene)
        syncStyle()
    }

    // The toast's window doesn't inherit an in-app light/dark override, so
    // it copies whatever style the app's own window resolved to.
    private func syncStyle() {
        guard let scene = window?.windowScene else { return }
        BrightToastWindow.window(for: scene)?.overrideUserInterfaceStyle = traitCollection.userInterfaceStyle
    }
}

private final class BrightToastWindow: UIWindow {
    private static var windows: [ObjectIdentifier: BrightToastWindow] = [:]

    static func window(for scene: UIWindowScene) -> BrightToastWindow? {
        windows[ObjectIdentifier(scene)]
    }

    static func install(in scene: UIWindowScene) {
        guard window(for: scene) == nil else { return }

        let window = BrightToastWindow(windowScene: scene)
        // Only as tall as the toast needs: a full-screen window on top would
        // take over the status bar style from the app's own window.
        window.frame = CGRect(
            x: 0,
            y: 0,
            width: scene.screen.bounds.width,
            height: Constants.windowHeight
        )
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear

        let host = UIHostingController(rootView: BrightToastV5(presenter: .shared))
        host.view.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = false

        windows[ObjectIdentifier(scene)] = window
    }

    // Never takes a touch; everything goes through to the app beneath.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        nil
    }
}

private enum Constants {
    // iPhone Air tops out at 68, and every island phone is at least 59.
    static let islandSafeAreaMin: CGFloat = 59
    static let islandWidth: CGFloat = 100
    static let islandHeight: CGFloat = 33
    static let islandInset: CGFloat = 5
    static let pillHeight: CGFloat = 44
    static let orbSize: CGFloat = 28
    static let iconSize: CGFloat = 30
    static let orbExitScale: CGFloat = 0.6
    static let pillStartScale: CGFloat = 0.7
    static let sideInset: CGFloat = .spacing12x
    static let blurRadius: CGFloat = 25
    static let alphaThreshold: Float = 0.5
    static let windowHeight: CGFloat = 360
    static let hold: Duration = .seconds(3)
    static let successAfterLoadingHold: Duration = .seconds(1.5)
    static let readingLeadIn: Duration = .seconds(1)
    static let readingTimePerWord: Duration = .milliseconds(300)
    static let maxHold: Duration = .seconds(10)
    static let drop: Animation = .smooth(duration: 0.45)
    static let retract: Animation = .smooth(duration: 0.4)
}

#Preview {
    VStack(spacing: .spacing2x) {
        BrightPillButton("Sync", systemImage: "arrow.triangle.2.circlepath") {
            BrightToastPresenterV5.shared.loading("Syncing…")
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                BrightToastPresenterV5.shared.success("Synced")
            }
        }
        BrightPillButton("Success", systemImage: "checkmark") {
            BrightToastPresenterV5.shared.success("Meal logged")
        }
        BrightPillButton("Error", systemImage: "xmark") {
            BrightToastPresenterV5.shared.error("Couldn't delete template")
        }
        BrightPillButton("Long error", systemImage: "text.alignleft") {
            BrightToastPresenterV5.shared.error("It looks like your username is invalid or does not exist.")
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.defaultBackground)
    .brightToastHostV5()
}
