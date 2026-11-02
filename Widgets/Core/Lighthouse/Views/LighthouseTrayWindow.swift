//
//  LighthouseTrayWindow.swift
//  Widgets
//

import SwiftUI
import UIKit

@MainActor @Observable
final class LighthouseTrayState {
    var detent = LighthouseTray.restDetent
    var rests = false
    // Sent as the tray opens, such as a widget's check-in; cleared once it settles back.
    var prompt: String?
}

// The tray's sheet, presented from a window of its own above the app's, so it
// can rest as the mini bar at the foot of a sub page while the page underneath
// pushes, pops and presents as normal.
struct LighthouseTrayRoot: View {
    @Bindable var state: LighthouseTrayState
    @Binding var isOpen: Bool

    private var isPresented: Binding<Bool> {
        Binding(
            get: { isOpen || state.rests },
            set: { presented in
                if !presented { isOpen = false }
            }
        )
    }

    var body: some View {
        Color.clear
            .ignoresSafeArea()
            .sheet(isPresented: isPresented, onDismiss: settle) {
                LighthouseTray(
                    detent: $state.detent,
                    hasRest: state.rests,
                    initialPrompt: state.prompt
                ) {
                    isOpen = false
                }
                .presentationBackgroundInteraction(.enabled(upThrough: LighthouseTray.halfDetent))
                .presentationDragIndicator(.visible)
            }
    }

    private func settle() {
        guard !isOpen else { return }
        state.detent = LighthouseTray.restDetent
        state.prompt = nil
    }
}

// Put in the background of the app's root view: it installs the tray's window
// over the app's once it's on screen, and keeps its root up to date.
struct LighthouseTrayWindowInstaller: UIViewRepresentable {
    let root: LighthouseTrayRoot

    func makeUIView(context: Context) -> InstallerView {
        InstallerView(root: root)
    }

    func updateUIView(_ view: InstallerView, context: Context) {
        view.root = root
    }

    final class InstallerView: UIView {
        var root: LighthouseTrayRoot {
            didSet { window.map { LighthouseTrayWindow.window(for: $0)?.update(root) } }
        }

        init(root: LighthouseTrayRoot) {
            self.root = root
            super.init(frame: .zero)
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
            guard let window, !(window is LighthouseTrayWindow) else { return }
            LighthouseTrayWindow.install(over: window, root: root)
            syncStyle()
        }

        private func syncStyle() {
            guard let window else { return }
            LighthouseTrayWindow.window(for: window)?.overrideUserInterfaceStyle = traitCollection.userInterfaceStyle
        }
    }
}

final class LighthouseTrayWindow: UIWindow {
    private static var windows: [ObjectIdentifier: LighthouseTrayWindow] = [:]

    private weak var appWindow: UIWindow?
    private var host: TrayHostingController?
    private var watch: Timer?
    private var isCovered = false

    static func window(for appWindow: UIWindow) -> LighthouseTrayWindow? {
        windows[ObjectIdentifier(appWindow)]
    }

    static func install(over appWindow: UIWindow, root: LighthouseTrayRoot) {
        guard window(for: appWindow) == nil, let scene = appWindow.windowScene else { return }
        let window = LighthouseTrayWindow(windowScene: scene)
        window.appWindow = appWindow
        window.windowLevel = UIWindow.Level(rawValue: appWindow.windowLevel.rawValue + 1)
        window.backgroundColor = .clear
        let host = TrayHostingController(rootView: root)
        host.appWindow = appWindow
        host.view.backgroundColor = .clear
        window.host = host
        window.rootViewController = host
        window.isHidden = false
        window.startWatching()
        windows[ObjectIdentifier(appWindow)] = window
    }

    func update(_ root: LighthouseTrayRoot) {
        host?.rootView = root
    }

    // Only the sheet takes touches; everywhere else falls through to the app.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isCovered, let hit = super.hitTest(point, with: event) else { return nil }
        guard let rootView = rootViewController?.view else { return hit }
        return hit === self || hit.isDescendant(of: rootView) ? nil : hit
    }

    // Anything the app presents (a sheet, a cover) would sit under this window,
    // so the tray fades away until it's gone.
    private func startWatching() {
        watch = Timer.scheduledTimer(withTimeInterval: Constants.checkInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.check() }
        }
    }

    private func check() {
        let appPresented = appWindow?.rootViewController?.presentedViewController
        let covered = appPresented.map { !$0.isBeingDismissed } ?? false
        if covered != isCovered {
            isCovered = covered
            if covered, isKeyWindow { appWindow?.makeKey() }
            UIView.animate(withDuration: Constants.fadeDuration) { self.alpha = covered ? .zero : 1 }
        }
        host?.setNeedsStatusBarAppearanceUpdate()
    }

    private enum Constants {
        static let checkInterval: TimeInterval = 0.15
        static let fadeDuration: TimeInterval = 0.25
    }
}

private final class TrayHostingController: UIHostingController<LighthouseTrayRoot> {
    weak var appWindow: UIWindow?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        appWindow?.rootViewController?.preferredStatusBarStyle ?? .default
    }

    override var prefersStatusBarHidden: Bool {
        appWindow?.rootViewController?.prefersStatusBarHidden ?? false
    }
}
