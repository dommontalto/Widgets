//
//  BrightToastOverlay.swift
//  Widgets
//
//  Created by Zoe Friedman on 21/9/2023.
//

import SwiftUI

struct BrightToastOverlay: ViewModifier {
    @Binding var isShowing: Bool
    var bottomPadding: CGFloat
    var toast: BrightToast
    var toastType: BrightToastType

    init(
        isShowing: Binding<Bool>,
        bottomPadding: CGFloat = .spacing10x,
        toast: BrightToast,
        toastType: BrightToastType = .bottom
    ) {
        _isShowing = isShowing
        self.bottomPadding = bottomPadding
        self.toast = toast
        self.toastType = toastType
    }

    func body(content: Content) -> some View {
        ZStack {
            content
            toastOverlay
        }
    }

    var toastOverlay: some View {
        VStack {
            if toastType == .top {
                if isShowing {
                    toastView
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, .spacing3x)
                        .padding(.top, bottomPadding)
                        .transition(.move(edge: .top))
                        .onAppear {
                            Task { @MainActor in
                                try? await Task.sleep(for: .seconds(.toastModalDismissDelay))
                                withAnimation {
                                    isShowing = false
                                }
                            }
                        }
                        .swipe(up: {
                            withAnimation {
                                isShowing = false
                            }
                        })
                }
                Spacer()
            }
            if toastType == .bottom {
                Spacer()
                if isShowing {
                    toastView
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, .spacing3x)
                        .padding(.bottom, bottomPadding)
                        .transition(.move(edge: .bottom))
                        .onAppear {
                            Task { @MainActor in
                                try? await Task.sleep(for: .seconds(.toastModalDismissDelay))
                                withAnimation {
                                    isShowing = false
                                }
                            }
                        }
                        .swipe(down: {
                            withAnimation {
                                isShowing = false
                            }
                        })
                }
            }
        }
        .ignoresSafeArea(.all)
        .animation(.brightSpring, value: isShowing)
    }

    var toastView: some View {
        toastContent
            .modifier(BrightGlassEffectV5(shape: .capsule))
    }

    @ViewBuilder
    var toastContent: some View {
        VStack {
            switch toast {
            case let .singleLineWithLogo(text):
                SingleLineWithLogoToast(text: text)
                    .onTapGesture {
                        withAnimation {
                            isShowing = false
                        }
                    }
            case let .singleLine(text):
                SingleLineToast(text: text)
                    .onTapGesture {
                        withAnimation {
                            isShowing = false
                        }
                    }
            case let .error(text: text):
                TopErrorToast(text: text)
                    .onTapGesture {
                        withAnimation {
                            isShowing = false
                        }
                    }
            case let .statusPill(text, icon, color):
                StatusPillToast(text: text, icon: icon, color: color)
                    .onTapGesture {
                        withAnimation {
                            isShowing = false
                        }
                    }
            }
        }
    }
}

#Preview {
    VStack {
        Text("Hello world")
        Spacer()
    }
    .modifier(BrightToastOverlay(
        isShowing: Binding.constant(true),
        toast: .singleLineWithLogo(text: "Hello")
    ))
}
