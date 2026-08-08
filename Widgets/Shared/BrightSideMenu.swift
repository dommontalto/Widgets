//
//  BrightSideMenu.swift
//  Bright
//
//  Created by Dom Montalto on 12/5/2026.
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

// A reusable left-edge slide-in side menu.
// Driven by a horizontal pan gesture (with a left-edge bias for nested scroll views)
// and a bindable `isExpanded` flag for programmatic open/close.
struct BrightSideMenu<MenuContent: View, Content: View>: View {
    var isEnabled: Bool = true
    var canOpenBySwipe: Bool = true
    var sideBarWidth: CGFloat = 280
    @Binding var isExpanded: Bool
    @ViewBuilder var menuContent: (_ progress: CGFloat) -> MenuContent
    @ViewBuilder var content: (_ progress: CGFloat) -> Content

    @State private var progress: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var haptic = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .leading) {
            Color.defaultSheetBackground
                .ignoresSafeArea()
            sideMenu
            mainContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(.rect)
        .gesture(
            BrightSideMenuGesture(
                isEnabled: isEnabled,
                canOpenBySwipe: canOpenBySwipe,
                isExpanded: $isExpanded
            ) { gesture in
                handleGesture(gesture)
            }
        )
        .brightHaptic(.soft, trigger: haptic)
        .onChange(of: isExpanded) { _, newValue in
            withAnimation(animation) {
                if newValue && progress != 1 {
                    expandMenu()
                } else if !newValue && progress != 0 {
                    dismissMenu()
                }
            }
        }
    }

    private var sideMenu: some View {
        menuContent(progress)
            .frame(width: sideBarWidth)
            .frame(maxHeight: .infinity)
            .opacity(progress)
            .scaleEffect(0.95 + (0.05 * progress))
    }

    private var mainContent: some View {
        content(progress)
            .containerRelativeFrame(.horizontal)
            .frame(maxHeight: .infinity)
            .background {
                backgroundShape
                    .fill(Color.defaultBackground)
                    .ignoresSafeArea()
            }
            .overlay { dimmingOverlay }
            .mask {
                backgroundShape.ignoresSafeArea()
            }
            .compositingGroup()
            .shadow(color: .black.opacity(Double.ultraLowOpacity * Double(progress)), radius: 8, x: -6, y: 0)
            .offset(x: xOffset)
    }

    private var dimmingOverlay: some View {
        backgroundShape
            .fill(.ultraThinMaterial)
            .overlay {
                Color.black.opacity(colorScheme == .dark ? .lowOpacity : 0)
            }
            .ignoresSafeArea()
            .contentShape(.rect)
            .onTapGesture {
                withAnimation(animation) { dismissMenu() }
            }
            .opacity(progress)
    }

    private func handleGesture(_ gesture: UIPanGestureRecognizer) {
        let state = gesture.state
        let translation = gesture.translation(in: gesture.view).x + (isExpanded ? sideBarWidth : 0)
        let velocity = gesture.velocity(in: gesture.view).x / 5

        if state == .began || state == .changed {
            xOffset = min(max(translation, 0), sideBarWidth)
            progress = xOffset / sideBarWidth
        } else {
            withAnimation(animation) {
                if (xOffset + velocity) > (sideBarWidth / 2) {
                    expandMenu()
                } else {
                    dismissMenu()
                }
            }
        }
    }

    private func expandMenu() {
        if progress != 1 { haptic.toggle() }
        xOffset = sideBarWidth
        progress = 1
        isExpanded = true
    }

    private func dismissMenu() {
        if progress != 0 { haptic.toggle() }
        xOffset = 0
        progress = 0
        isExpanded = false
    }

    private var backgroundShape: Rectangle {
        Rectangle()
    }

    private var animation: Animation {
        .interactiveSpring(duration: 0.2, extraBounce: 0.02)
    }
}

private struct BrightSideMenuGesture: UIGestureRecognizerRepresentable {
    var isEnabled: Bool
    var canOpenBySwipe: Bool
    @Binding var isExpanded: Bool
    var handle: (UIPanGestureRecognizer) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.delegate = context.coordinator
        gesture.maximumNumberOfTouches = 1
        return gesture
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
        var parent: BrightSideMenuGesture

        init(parent: BrightSideMenuGesture) {
            self.parent = parent
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
                let velocity = panGesture.velocity(in: panGesture.view)
                let isHorizontalSwipe = abs(velocity.x) > abs(velocity.y)
                return (isHorizontalSwipe && velocity.x > 0 && parent.canOpenBySwipe) ||
                    (isHorizontalSwipe && velocity.x < 0 && parent.isExpanded)
            }
            return false
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            if let scrollview = otherGestureRecognizer.view as? UIScrollView {
                return scrollview.contentOffset.x <= 0
            }
            return false
        }
    }
}
