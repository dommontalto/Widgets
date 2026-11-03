//
//  BrightBottomButtonV5.swift
//  Widgets
//
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

private struct BrightBottomButtonV5<Label: View>: ViewModifier {
    let button: Label

    @Environment(\.brightLighthouseRestHeight) private var lighthouseRestHeight
    @State private var keyboardShown = false
    @State private var isInSheet = false

    // Lifted clear of the resting Lighthouse bar; otherwise, and while the keyboard
    // covers the bar, it sits just off the bottom.
    private var isLifted: Bool {
        lighthouseRestHeight > .zero && !keyboardShown && !isInSheet
    }

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: .spacing0x) {
                button
                    .frame(maxWidth: .infinity)
                    .padding(.top, .spacing2x)
                    .padding(.bottom, isLifted ? .spacing12x : .spacing2x)
            }
            .background(BrightSheetProbeV5(isInSheet: $isInSheet))
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                keyboardShown = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardShown = false
            }
    }
}

private struct BrightSheetProbeV5: UIViewRepresentable {
    @Binding var isInSheet: Bool

    func makeUIView(context: Context) -> ProbeView {
        ProbeView { isInSheet = $0 }
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {}

    final class ProbeView: UIView {
        let report: (Bool) -> Void

        init(report: @escaping (Bool) -> Void) {
            self.report = report
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }

        required init?(coder: NSCoder) { nil }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            var responder: UIResponder? = self
            while let next = responder, !(next is UIViewController) { responder = next.next }
            let isInSheet = (responder as? UIViewController)?.presentingViewController != nil
            DispatchQueue.main.async { self.report(isInSheet) }
        }
    }
}

extension View {
    func brightBottomButtonV5(@ViewBuilder _ button: () -> some View) -> some View {
        modifier(BrightBottomButtonV5(button: button()))
    }
}

#Preview {
    NavigationStack {
        BrightPageViewV5(title: "Personal Details") {
            Text("Content")
        }
        .brightBottomButtonV5 {
            BrightPillButton("Save", buttonSize: .large) {}
        }
    }
}
