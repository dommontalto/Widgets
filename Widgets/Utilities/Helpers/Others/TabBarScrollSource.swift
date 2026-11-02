//
//  TabBarScrollSource.swift
//  Widgets
//

import SwiftUI

// Names the scroll view it sits in as the one the tab bar watches, so the dock
// minimises with it. SwiftUI only finds a tab's outermost scroll view, which on
// a paged screen is the sideways pager rather than the page being scrolled. Put
// it in the background of a page's content, active while that page is showing.
struct TabBarScrollSource: UIViewRepresentable {
    var isActive: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        guard isActive else { return }
        DispatchQueue.main.async {
            guard let scrollView = sequence(first: view, next: \.superview)
                .lazy
                .compactMap({ $0 as? UIScrollView })
                .first
            else { return }

            var responder: UIResponder? = view.next
            while let current = responder, !(current is UITabBarController) {
                (current as? UIViewController)?.setContentScrollView(scrollView, for: .bottom)
                responder = current.next
            }
        }
    }
}
