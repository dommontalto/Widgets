//
//  BrightSideMenu.swift
//  Widgets
//
//  Created by Dom Montalto on 14/9/2026.
//

import SwiftUI

// A left-edge menu. The content slides right off the menu sitting behind it,
// dimming under a frosted veil as it goes, driven by a pan that only takes a
// drag it can use: rightwards to open, and leftwards only once it's open.
// Everything else — a row's swipe actions included — the content keeps.
//
// Nothing is masked or clipped on the way across, so the content keeps whatever
// corners it already had. The menu is only in the stack while it's showing or
// on its way: a pane laid out beside the content while the keyboard is up is
// taller than the keyboard leaves room for, the stack grows to fit it, and
// anything hanging off the content's bottom edge ends up under the keyboard.
// The menu is never faded or scaled either — glass buttons under a fading or
// scaling ancestor only draw once the slide settles.
struct BrightSideMenu<MenuContent: View, Content: View>: View {
    var isEnabled = true
    var canOpenBySwipe = true
    var sideBarRatio: CGFloat = Constants.defaultSideBarRatio
    @Binding var isExpanded: Bool
    @ViewBuilder var menuContent: MenuContent
    @ViewBuilder var content: Content

    @State private var offset: CGFloat = 0
    @State private var haptic = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width * sideBarRatio

            ZStack(alignment: .topLeading) {
                if isExpanded || offset > 0 {
                    menuContent
                        .frame(width: width)
                        .frame(maxHeight: .infinity)
                }

                content
                    .frame(width: proxy.size.width)
                    .frame(maxHeight: .infinity)
                    .overlay { veil(over: width) }
                    .overlay(alignment: .leading) { edge(over: width) }
                    .offset(x: offset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .gesture(
                BrightSideMenuPan(
                    isEnabled: isEnabled,
                    canOpenBySwipe: canOpenBySwipe,
                    isExpanded: isExpanded
                ) { pan in
                    handle(pan, over: width)
                }
            )
            // Every open and close lands here, the pan's included, so the
            // haptic only needs firing once — and the toolbar button gets the
            // same one the swipe does.
            .onChange(of: isExpanded) { _, isExpanded in
                haptic.toggle()
                withAnimation(.brightSnappy) { offset = isExpanded ? width : 0 }
            }
        }
        .brightHaptic(.soft, trigger: haptic)
    }

    // Frosts and darkens the pushed-aside content with the drag, and takes the
    // tap that closes the menu so it can't reach the controls behind.
    private func veil(over width: CGFloat) -> some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(Color.sideMenuDim)
            .ignoresSafeArea()
            .opacity(width > 0 ? Double(offset / width) : 0)
            .contentShape(.rect)
            .allowsHitTesting(isExpanded)
            .onTapGesture {
                withAnimation(.brightSnappy) { isExpanded = false }
            }
    }

    // A hairline down the content's leading edge with a soft shadow falling
    // off it onto the menu, so the content reads as lying over the menu
    // rather than beside it. Both come in with the drag.
    private func edge(over width: CGFloat) -> some View {
        let progress = width > 0 ? Double(offset / width) : 0
        return HStack(spacing: .spacing0x) {
            LinearGradient(
                colors: [.clear, .black.opacity(Constants.edgeShadowOpacity * progress)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: Constants.edgeShadowWidth)

            Color.white
                .opacity(Constants.edgeLineOpacity * progress)
                .frame(width: Constants.edgeLineWidth)
        }
        .ignoresSafeArea()
        .offset(x: -Constants.edgeShadowWidth)
        .allowsHitTesting(false)
    }

    private func handle(_ pan: UIPanGestureRecognizer, over width: CGFloat) {
        let translation = pan.translation(in: pan.view).x + (isExpanded ? width : 0)

        switch pan.state {
        case .began, .changed:
            offset = min(max(translation, 0), width)
        default:
            // Flicks land where they were thrown rather than where they let go.
            let projected = translation + pan.velocity(in: pan.view).x / Constants.flick
            setExpanded(projected > width / 2, over: width)
        }
    }

    private func setExpanded(_ expanded: Bool, over width: CGFloat) {
        withAnimation(.brightSnappy) {
            offset = expanded ? width : 0
            isExpanded = expanded
        }
    }
}

// Takes only the drags the menu can act on: a rightward one when it's closed
// (and swiping open is allowed), a leftward one when it's open. A trailing
// swipe on a row is neither, so the row still gets it, and a vertical drag is
// left to whatever scrolls.
private struct BrightSideMenuPan: UIGestureRecognizerRepresentable {
    var isEnabled: Bool
    var canOpenBySwipe: Bool
    var isExpanded: Bool
    var handle: (UIPanGestureRecognizer) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        pan.maximumNumberOfTouches = 1
        return pan
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        context.coordinator.parent = self
        recognizer.isEnabled = isEnabled
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        handle(recognizer)
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: BrightSideMenuPan

        init(parent: BrightSideMenuPan) {
            self.parent = parent
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: pan.view)
            guard abs(velocity.x) > abs(velocity.y) else { return false }
            return velocity.x > 0 ? !parent.isExpanded && parent.canOpenBySwipe : parent.isExpanded
        }

        // Lets a scroll view that's still at its leading edge hand the drag over,
        // rather than swallowing it.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            guard let scrollView = otherGestureRecognizer.view as? UIScrollView else { return false }
            return scrollView.contentOffset.x <= 0
        }
    }
}

private enum Constants {
    static let defaultSideBarRatio: CGFloat = 0.8
    static let edgeLineWidth: CGFloat = 0.5
    static let edgeLineOpacity: Double = .minimalOpacity
    static let edgeShadowWidth: CGFloat = .spacing6x
    static let edgeShadowOpacity: Double = .ultraLowOpacity
    // Damps the throw velocity into a distance the projection can use.
    static let flick: CGFloat = 5
}
