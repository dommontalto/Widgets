//
//  BrightPageView.swift
//  Widgets
//
//  Copyright © 2025 Bryan Jordan. All rights reserved.
//

import SwiftUI

struct BrightPageView<Content: View, Toolbar: ToolbarContent>: View {
    let title: String
    let scrollableTitle: Bool
    let horizontalPadding: CGFloat
    let backgroundColor: Color
    let bottomSafeArea: Bool
    let infoButton: (() -> Void)?
    let toolbar: Toolbar
    let content: Content

    @State private var inlineTitleOpacity: CGFloat = 0
    @State private var scrollY: CGFloat = 0

    private var largeTitleFade: CGFloat {
        1 - min(1, max(0, (scrollY - .spacing2x) / Constants.titleFadeDistance))
    }

    init(
        title: String = "",
        scrollableTitle: Bool = true,
        horizontalPadding: CGFloat = .spacing3x,
        backgroundColor: Color = .defaultBackground,
        bottomSafeArea: Bool = true,
        infoButton: (() -> Void)? = nil,
        @ToolbarContentBuilder toolbar: () -> Toolbar,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.scrollableTitle = scrollableTitle
        self.horizontalPadding = horizontalPadding
        self.backgroundColor = backgroundColor
        self.bottomSafeArea = bottomSafeArea
        self.infoButton = infoButton
        self.toolbar = toolbar()
        self.content = content()
    }

    var body: some View {
        Group {
            if !title.isEmpty, scrollableTitle {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        BrightText(title, size: .huge205)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, .spacing3x)
                            .padding(.bottom, .spacing4x + .spacing05x)
                            .opacity(largeTitleFade)
                            .blur(radius: (1 - largeTitleFade) * 5)
                        content
                            .padding(.horizontal, horizontalPadding)
                    }
                }
                .scrollIndicators(.hidden)
                .modifier(InlineTitleScrollTracking(inlineTitleOpacity: $inlineTitleOpacity, scrollY: $scrollY))
            } else {
                content
                    .padding(.horizontal, horizontalPadding)
                    .modifier(InlineTitleScrollTracking(inlineTitleOpacity: $inlineTitleOpacity, scrollY: $scrollY))
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .safeAreaPadding(bottomSafeArea ? .bottom : [])
            .scrollDismissesKeyboard(.interactively)
            .background(backgroundColor.edgesIgnoringSafeArea(.all))
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                if !title.isEmpty {
                    ToolbarItem(placement: .principal) {
                        BrightText(title, size: .subheading)
                            .opacity(inlineTitleOpacity)
                            .blur(radius: (1 - inlineTitleOpacity) * 6)
                            .scaleEffect(1.15 - 0.15 * inlineTitleOpacity)
                    }
                }
                toolbar
                if let infoButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: infoButton) {
                            Image(systemName: "info")
                        }
                    }
                }
            }
    }
}

extension BrightPageView where Toolbar == EmptyToolbarContent {
    init(
        title: String = "",
        scrollableTitle: Bool = true,
        horizontalPadding: CGFloat = .spacing3x,
        backgroundColor: Color = .defaultBackground,
        bottomSafeArea: Bool = true,
        infoButton: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.scrollableTitle = scrollableTitle
        self.horizontalPadding = horizontalPadding
        self.backgroundColor = backgroundColor
        self.bottomSafeArea = bottomSafeArea
        self.infoButton = infoButton
        toolbar = EmptyToolbarContent()
        self.content = content()
    }
}

private enum Constants {
    static let titleFadeDistance: CGFloat = 52
}

private struct InlineTitleScrollTracking: ViewModifier {
    @Binding var inlineTitleOpacity: CGFloat
    @Binding var scrollY: CGFloat

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.y + $0.contentInsets.top
            } action: { _, newY in
                scrollY = newY
                let newOpacity = min(1, max(0, (newY - 56) / 10))
                if inlineTitleOpacity != newOpacity {
                    withAnimation(.brightEaseInOut) {
                        inlineTitleOpacity = newOpacity
                    }
                }
            }
    }
}
