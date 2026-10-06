//
//  BrightPullToRefreshScrollView.swift
//  Widgets
//
//  Created by Gangajaliya Sandeep on 23/5/2025.
//

import SwiftUI

struct BrightPullToRefreshScrollView<Content: View>: View {

    @Binding var isLoading: Bool
    @Binding var scrollToBottomTrigger: Bool
    let showScrollIndicators: ScrollIndicatorVisibility
    let threshold: CGFloat
    let defaultTopPadding: CGFloat
    let scrollEnabled: Bool
    let content: () -> Content
    let onRefresh: (() -> Void)
    let onOffsetChange: ((CGFloat) -> Void)?

    @State private var pullOffset: CGFloat = 0
    @State private var isRefreshing = false
    @State private var topPadding: CGFloat = 0
    @State private var loaderScale: CGFloat = 1.0

    @State private var filledIndexes: Set<Int> = []
    @State private var didTrigger: Bool = false
    @State private var loaderProgress: CGFloat = 0

    private var innerRadiusWidth: CGFloat {
        Constants.loaderSize * 0.88
    }

    init(
        isLoading: Binding<Bool>,
        scrollToBottomTrigger: Binding<Bool> = .constant(false),
        showScrollIndicators: ScrollIndicatorVisibility = .hidden,
        threshold: CGFloat = Constants.defaultThresold,
        defaultTopPadding: CGFloat = 0,
        scrollEnabled: Bool = true,
        @ViewBuilder content: @escaping () -> Content,
        onRefresh: @escaping () -> Void,
        onOffsetChange: ((CGFloat) -> Void)? = nil
    ) {
        self._isLoading = isLoading
        self._scrollToBottomTrigger = scrollToBottomTrigger
        self.showScrollIndicators = showScrollIndicators
        self.threshold = threshold
        self.defaultTopPadding = defaultTopPadding
        self.scrollEnabled = scrollEnabled
        self.content = content
        self.onRefresh = onRefresh
        self.onOffsetChange = onOffsetChange
    }

    var body: some View {
        ZStack(alignment: .top) {

            if pullOffset > 0 || isRefreshing {
                VStack(spacing: .spacing0x) {
                    Spacer(minLength: 0)
                    loader
                        .scaleEffect(effectiveScale)
                    Spacer(minLength: 0)
                }
                .frame(maxHeight: pullOffset)
                .padding(.top, defaultTopPadding)
            }
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: .spacing0x) {
                        GeometryReader { geo -> Color in
                            DispatchQueue.main.async {
                                let frame = geo.frame(in: .named(Constants.pullToRefreshText))
                                let offset = frame.minY - defaultTopPadding
                                pullOffset = max(offset, 0)
                                onOffsetChange?(frame.minY)
                                if offset <= defaultTopPadding {
                                    didTrigger = false
                                }
                            }
                            return Color.clear
                        }
                        .frame(height: 0)

                        content()

                        Color.clear
                            .frame(height: 1)
                            .id("scrollToBottom")
                    }
                    .padding(.top, defaultTopPadding + topPadding)
                    .animation(.easeInOut, value: isRefreshing)
                }
                .scrollIndicators(showScrollIndicators)
                .scrollClipDisabled()
                .scrollDisabled(!scrollEnabled)
                .coordinateSpace(name: Constants.pullToRefreshText)
                .onChange(of: scrollToBottomTrigger) { _, shouldScroll in
                    if shouldScroll {
                        withAnimation(.brightEaseInOut) {
                            proxy.scrollTo("scrollToBottom", anchor: .bottom)
                        }
                        scrollToBottomTrigger = false
                    }
                }
            }
        }
        .onChange(of: pullOffset) { _, newValue in
            if newValue >= threshold, !isRefreshing, !didTrigger {
                startAnimation()
            }
            loaderProgress = min(pullOffset / threshold, 1)
            if newValue == 0 {
                withAnimation {
                    topPadding = isRefreshing ? (Constants.loaderSize + .spacing2x) : 0
                }
            }
        }
        .brightHapticV5(.light, trigger: loaderProgress) { _, new in
            new != 0 && !isRefreshing && !didTrigger
        }
        .onChange(of: isLoading) { _, newValue in
            if !newValue, isRefreshing {
                endRefreshing()
            }
        }
    }

    var loader: some View {
        ZStack {
            ForEach(0..<Constants.barCount, id: \.self) { index in
                let color: Color = {
                    if isRefreshing {
                        if filledIndexes.contains(index) {
                            return Color.defaultWhiteBlack
                        } else {
                            return Color.gray.opacity(0.3)
                        }
                    } else {
                        if loaderProgress >= CGFloat(index) / CGFloat(Constants.barCount) {
                            return Color.defaultWhiteBlack
                        } else {
                            return Color.gray.opacity(0.3)
                        }
                    }
                }()
                Rectangle()
                    .fill(color)
                    .frame(width: Constants.barWidth)
                    .offset(y: -innerRadiusWidth)
                    .rotationEffect(.degrees(Double(index) / Double(Constants.barCount) * 360))
                    .animation(.easeInOut(duration: 0.1), value: filledIndexes)
            }
        }
        .frame(width: Constants.loaderSize, height: Constants.loaderSize)
        .clipShape(RoundedRectangle(cornerRadius: .squareCornerRadius))
    }

    private func startAnimation() {
        isLoading = true
        isRefreshing = true
        didTrigger = true
        filledIndexes = Set(0..<Constants.barCount)

        onRefresh()
        startBouncyScaleAnimation()

        BrightHaptic.medium.play()
    }

    private func endRefreshing() {
        pullOffset = 0
        topPadding = 0
        isRefreshing = false
    }

    private var effectiveScale: CGFloat {
        if isRefreshing {
            return loaderScale
        } else {
            return loaderProgress
        }
    }

    private func startBouncyScaleAnimation() {
        withAnimation(.bouncy(duration: 0.3, extraBounce: 0.4)) {
            loaderScale = 1.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.bouncy(duration: 0.3, extraBounce: 0.4)) {
                loaderScale = 1.0
            }
        }
    }
}

private class Constants {
    static let loaderSize: CGFloat = 32
    static let defaultThresold: CGFloat = 100
    static let barCount: Int = 28
    static let barWidth: CGFloat = 1
    static let pullToRefreshText: String = "BrightPullToRefreshScrollView"
}
