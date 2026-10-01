//
//  BrightView.swift
//  Widgets
//
//  Created by Zoe Friedman on 6/10/2023.
//

import SwiftUI

struct BrightView<T: View, C: View>: View {
    let isScrollable: Bool
    let horizontalPadding: CGFloat
    let ignoresTopSafeArea: Bool
    let ignoresBottomArea: Bool
    let backButtonCallback: (() -> Void)?
    let backButtonDisabled: Bool
    let infoButtonCallback: (() -> Void)?
    let backgroundColor: Color
    let showsTitle: Bool
    let isSheet: Bool
    let hidesNavigationBar: Bool
    let titleContent: T
    let content: C

    init(
        isScrollable: Bool = false,
        horizontalPadding: CGFloat = .spacing4x,
        ignoresTopSafeArea: Bool = false,
        ignoresBottomArea: Bool = true,
        backButtonCallback: (() -> Void)? = nil,
        backButtonDisabled: Bool = false,
        infoButtonCallback: (() -> Void)? = nil,
        backgroundColor: Color = .defaultBackground,
        showsTitle: Bool = true,
        isSheet: Bool = false,
        hidesNavigationBar: Bool = true,
        @ViewBuilder titleContent: () -> T,
        @ViewBuilder content: () -> C
    ) {
        self.isScrollable = isScrollable
        self.horizontalPadding = horizontalPadding
        self.ignoresTopSafeArea = ignoresTopSafeArea
        self.ignoresBottomArea = ignoresBottomArea
        self.backButtonCallback = backButtonCallback
        self.backButtonDisabled = backButtonDisabled
        self.infoButtonCallback = infoButtonCallback
        self.backgroundColor = backgroundColor
        self.showsTitle = showsTitle
        self.isSheet = isSheet
        self.hidesNavigationBar = hidesNavigationBar
        self.titleContent = titleContent()
        self.content = content()
    }

    var body: some View {
        ZStack {
            if isScrollable {
                ScrollableMainView(
                    horizontalPadding: horizontalPadding,
                    showsTitle: showsTitle,
                    isSheet: isSheet,
                    titleContent: titleContent,
                    content: content
                )
                .modifier(
                    SafeAreaViewModifier(
                        ignoresTopSafeArea: ignoresTopSafeArea,
                        ignoresBottomSafeArea: ignoresBottomArea
                    )
                )
            } else {
                MainView(
                    showsTitle: showsTitle,
                    isSheet: isSheet,
                    titleContent: titleContent,
                    content: content
                )
                .padding(.horizontal, horizontalPadding)
                .modifier(
                    SafeAreaViewModifier(
                        ignoresTopSafeArea: ignoresTopSafeArea,
                        ignoresBottomSafeArea: ignoresBottomArea
                    )
                )
            }
            if backButtonCallback != nil || infoButtonCallback != nil {
                ButtonOverlay(
                    isSheet: isSheet,
                    backButtonDisabled: backButtonDisabled,
                    backButtonCallback: backButtonCallback,
                    infoButtonCallback: infoButtonCallback
                )
            }
        }
        .navigationBarBackButtonHidden(hidesNavigationBar)
        .toolbar(hidesNavigationBar ? .hidden : .visible, for: .navigationBar)
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
    }

    struct ScrollableMainView: View {
        let horizontalPadding: CGFloat
        let showsTitle: Bool
        let isSheet: Bool
        let titleContent: T
        let content: C

        var body: some View {
            ScrollView(showsIndicators: false) {
                MainView(
                    showsTitle: showsTitle,
                    isSheet: isSheet,
                    titleContent: titleContent,
                    content: content
                )
                .padding(.horizontal, horizontalPadding)
            }
            .frame(width: UIScreen.main.bounds.width)
            .scrollDismissesKeyboard(.interactively)
            .brightSoftScrollEdgesV5()
        }
    }

    struct MainView: View {
        let showsTitle: Bool
        let isSheet: Bool
        let titleContent: T
        let content: C

        var body: some View {
            VStack(spacing: .spacing0x) {
                if showsTitle {
                    titleContent
                }
                if isSheet {
                    content
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .top
                        )
                } else {
                    content
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .top
                        )
                        .scrollDismissesKeyboard(.interactively)
                }
            }
        }
    }

    struct ButtonOverlay: View {
        let isSheet: Bool
        let backButtonDisabled: Bool
        let backButtonCallback: (() -> Void)?
        let infoButtonCallback: (() -> Void)?

        var body: some View {
            HStack {
                if let backButtonCallback {
                    BrightRoundButton(systemImage: "chevron.left", onTapCallback: backButtonCallback)
                    .modifier(
                        DisabledViewModifier(disabled: backButtonDisabled)
                    )
                }

                Spacer()

                if let infoButtonCallback {
                    BrightRoundButton(systemImage: "info", onTapCallback: infoButtonCallback)
                }
            }
            .padding(.top, isSheet ? .spacing3x : (.spacing1x + .spacing05x))
            .padding(.horizontal, .spacing3x)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
        }
    }

    struct SafeAreaViewModifier: ViewModifier {
        let ignoresTopSafeArea: Bool
        let ignoresBottomSafeArea: Bool

        func body(content: Content) -> some View {
            if ignoresBottomSafeArea, ignoresTopSafeArea {
                content
                    .ignoresSafeArea(edges: .all)
            } else if ignoresBottomSafeArea {
                content
                    .ignoresSafeArea(edges: .bottom)
            } else if ignoresTopSafeArea {
                content
                    .ignoresSafeArea(edges: .top)
            } else {
                content
            }
        }
    }
}

#Preview {
    BrightView(titleContent: {}, content: {})
}
