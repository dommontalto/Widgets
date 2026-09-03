//
//  BrightKeyboardDismissDrag.swift
//  Widgets
//
//  Created by Dom Montalto on 3/9/2026.
//

import SwiftUI

extension View {
    // Lets a downward drag that starts over this view pull the keyboard down
    // with the finger, the way dragging the thread already does.
    func brightKeyboardDismissDrag(isActive: Bool) -> some View {
        background(KeyboardDismissProbe(isActive: isActive))
    }
}

// Only a scroll view's interactive dismiss mode can make the keyboard track a
// finger, so an invisible one sits behind the view and lends its pan
// recognizer to the hosting view. Touches over the view reach that recognizer
// because the host is an ancestor of everything drawn here.
private struct KeyboardDismissProbe: UIViewRepresentable {
    var isActive: Bool

    func makeUIView(context: Context) -> ProbeView {
        ProbeView()
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {
        uiView.scrollView.isActive = isActive
    }
}

private final class ProbeView: UIView {
    let scrollView = TrackingScrollView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        scrollView.region = self
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.backgroundColor = .clear
        addSubview(scrollView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        scrollView.contentSize = CGSize(width: bounds.width, height: bounds.height + 1)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        let pan = scrollView.panGestureRecognizer
        guard window != nil else {
            pan.view?.removeGestureRecognizer(pan)
            return
        }
        var host: UIView = self
        while let parent = host.superview, !(parent is UIWindow) {
            host = parent
        }
        host.addGestureRecognizer(pan)
    }
}

private final class TrackingScrollView: UIScrollView, UIGestureRecognizerDelegate {
    var isActive = false
    weak var region: UIView?

    // The scroll view is its own pan's delegate, so this filters the borrowed
    // recognizer down to downward drags that begin over the region.
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === panGestureRecognizer else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
        guard isActive, let region, let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        guard region.bounds.contains(pan.location(in: region)) else { return false }
        let translation = pan.translation(in: region)
        guard translation.y > 0, translation.y > abs(translation.x) else { return false }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }

    // Taps, the chips' horizontal scroll and SwiftUI's own gestures carry on
    // alongside the drag.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
