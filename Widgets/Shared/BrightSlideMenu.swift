//
//  BrightSlideMenu.swift
//  Widgets
//
//  Created by Dom Montalto on 14/9/2026.
//

import SwiftUI

// A left-edge menu. The content slides right off the menu sitting behind it,
// driven by a pan that only takes a drag it can use: rightwards to open, and
// leftwards only once it's open. Everything else — a row's swipe actions
// included — the content keeps.
//
// Nothing is masked or clipped on the way across, so the content keeps whatever
// corners it already had. The menu is only in the stack while it's showing or
// on its way: a pane laid out beside the content while the keyboard is up is
// taller than the keyboard leaves room for, the stack grows to fit it, and
// anything hanging off the content's bottom edge ends up under the keyboard.
// It isn't faded either — glass buttons under a fading ancestor only draw once
// it settles.
struct BrightSlideMenu<MenuContent: View, Content: View>: View {
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
                    .overlay { closeCatcher }
                    .offset(x: offset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .gesture(BrightSlideMenuPan(isExpanded: isExpanded) { pan in
                handle(pan, over: width)
            })
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

    // No dimming — this only exists so a tap on the pushed-aside content closes
    // the menu instead of reaching the controls behind it.
    private var closeCatcher: some View {
        Color.clear
            .contentShape(.rect)
            .allowsHitTesting(isExpanded)
            .onTapGesture {
                withAnimation(.brightSnappy) { isExpanded = false }
            }
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

// Takes only the drags the menu can act on: a rightward one when it's closed, a
// leftward one when it's open. A trailing swipe on a row is neither, so the row
// still gets it, and a vertical drag is left to whatever scrolls.
private struct BrightSlideMenuPan: UIGestureRecognizerRepresentable {
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
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        handle(recognizer)
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: BrightSlideMenuPan

        init(parent: BrightSlideMenuPan) {
            self.parent = parent
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: pan.view)
            guard abs(velocity.x) > abs(velocity.y) else { return false }
            return velocity.x > 0 ? !parent.isExpanded : parent.isExpanded
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
    // Damps the throw velocity into a distance the projection can use.
    static let flick: CGFloat = 5
}
