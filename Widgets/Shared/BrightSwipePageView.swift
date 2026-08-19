//
//  BrightSwipePageView.swift
//  Widgets
//
//  Created by Dom Montalto on 19/3/2026.
//

import SwiftUI

// MARK: - Public API

struct SwipePage {
    let title: String
    let systemImage: String?

    init(title: String, systemImage: String? = nil) {
        self.title = title
        self.systemImage = systemImage
    }
}

// Preference key used by pages that don't scroll directly (e.g. Insights)
// to report a manually-computed under-header opacity.
struct ScrollBlurOpacityKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// Normalized vertical scroll geometry for a page: `y` is 0 at the top,
// `maxY` is the largest offset the content can scroll to.
private struct PageScrollMetrics: Equatable {
    let y: CGFloat
    let maxY: CGFloat
}

// MARK: - State

// Scroll-derived state. Writes during scroll only invalidate the header /
// floating pill, not the parent or paged content.
@MainActor
@Observable
final class BrightSwipePageState {
    var scrollOffset: CGFloat = 0
    var containerWidth: CGFloat = 1

    var pageOpacities: [Int: CGFloat] = [:]
    var pageTitleOpacities: [Int: CGFloat] = [:]
    var pageScrollY: [Int: CGFloat] = [:]

    var preferenceOpacity: CGFloat = 0
    var activeOpacity: CGFloat = 0
    var activeTitleOpacity: CGFloat = 0
}

// MARK: - BrightSwipePageView

// Horizontal paging view with either a floating glass-pill header
// (`showHeader: true`) or an inline pill row below an optional big title.
struct BrightSwipePageView<Content: View>: View {
    let pages: [SwipePage]
    let fakeLargeTitle: String?
    let titleAccessory: AnyView?
    // Size / weight of the large title. Defaults match the screen-level call
    // sites; sheets that follow a tighter header spec can shrink it.
    let titleSize: FontSizes
    let titleWeight: Font.Weight
    // Rendered directly beneath the large title (e.g. a workout's time range and
    // source), so it scrolls, fades and blurs away with it.
    let titleSubtitle: AnyView?
    // How far the pill row travels upward as the large title scrolls away,
    // stopping it just below the nav bar. Sheets sit lower than a full screen,
    // so they need a longer run than the default.
    let pillFollowMaxShift: CGFloat
    let showInlineTabs: Bool
    let disableHorizontalScroll: Bool
    // When `true` (default), the large title collapses into a small nav-bar
    // title as it scrolls away. When `false`, nothing replaces it in the nav bar.
    let collapsesTitleToToolbar: Bool
    // Keyboard-dismiss behaviour for the per-page vertical scroll view. Set
    // `.interactively` when a page contains a text field that should follow a
    // drag (e.g. Vault's Data search). Must live on the inner vertical scroll,
    // not an ancestor — an ancestor binds it to the horizontal pager instead.
    let scrollDismissesKeyboardMode: ScrollDismissesKeyboardMode
    // Reports a page's vertical scroll as (page index, y, max scrollable y).
    let onPageScroll: ((Int, CGFloat, CGFloat) -> Void)?
    // Optional programmatic scroll control for a single page's vertical scroll
    // view (used by Health edit-mode drag auto-scroll). Applied only to the page
    // at `scrollControlledPageIndex`, leaving the other tabs untouched.
    let verticalScrollPosition: Binding<ScrollPosition>?
    let scrollControlledPageIndex: Int?
    let verticalScrollDisabledPageIndex: Int?
    // When `false`, the pager doesn't pad its content by the bottom safe area,
    // letting a page (e.g. Genome's full-bleed Metal strand) reach the screen
    // edge. Defaults to `true` — no effect on existing call sites.
    let bottomSafeArea: Bool
    // Full-bleed page background. Defaults to `nil` (no background) so sheet
    // call sites keep their own; standalone screens pass `.defaultBackground`.
    let backgroundColor: Color?
    // Hide it to give a page the full sheet, e.g. an expanded map.
    let navigationBarVisibility: Visibility
    let onRefresh: (() async -> Void)?
    @Binding var selectedIndex: Int
    @ViewBuilder let content: (Int) -> Content

    @State private var scrollPosition: Int?
    @State private var state = BrightSwipePageState()

    init(
        pages: [SwipePage],
        fakeLargeTitle: String? = nil,
        titleAccessory: AnyView? = nil,
        titleSize: FontSizes = .huge205,
        titleWeight: Font.Weight = .light,
        titleSubtitle: AnyView? = nil,
        pillFollowMaxShift: CGFloat = SwipePageConstants.pillFollowMaxShift,
        showInlineTabs: Bool = true,
        disableHorizontalScroll: Bool = false,
        collapsesTitleToToolbar: Bool = true,
        scrollDismissesKeyboardMode: ScrollDismissesKeyboardMode = .automatic,
        onPageScroll: ((Int, CGFloat, CGFloat) -> Void)? = nil,
        verticalScrollPosition: Binding<ScrollPosition>? = nil,
        scrollControlledPageIndex: Int? = nil,
        verticalScrollDisabledPageIndex: Int? = nil,
        bottomSafeArea: Bool = true,
        backgroundColor: Color? = nil,
        navigationBarVisibility: Visibility = .visible,
        onRefresh: (() async -> Void)? = nil,
        selectedIndex: Binding<Int>,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self.pages = pages
        self.fakeLargeTitle = fakeLargeTitle
        self.titleAccessory = titleAccessory
        self.titleSize = titleSize
        self.titleWeight = titleWeight
        self.titleSubtitle = titleSubtitle
        self.pillFollowMaxShift = pillFollowMaxShift
        self.showInlineTabs = showInlineTabs
        self.disableHorizontalScroll = disableHorizontalScroll
        self.collapsesTitleToToolbar = collapsesTitleToToolbar
        self.scrollDismissesKeyboardMode = scrollDismissesKeyboardMode
        self.onPageScroll = onPageScroll
        self.verticalScrollPosition = verticalScrollPosition
        self.scrollControlledPageIndex = scrollControlledPageIndex
        self.verticalScrollDisabledPageIndex = verticalScrollDisabledPageIndex
        self.bottomSafeArea = bottomSafeArea
        self.backgroundColor = backgroundColor
        self.navigationBarVisibility = navigationBarVisibility
        self.onRefresh = onRefresh
        _selectedIndex = selectedIndex
        // Start the scroll position at the selected page so the appear-time sync
        // is a no-op — otherwise the nil→index change trips `.brightHaptic`
        // and fires a spurious haptic when the view first mounts.
        _scrollPosition = State(initialValue: selectedIndex.wrappedValue)
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .top) {
            pager

            if shouldShowFloatingPill {
                floatingPillOverlay(fakeLargeTitle: fakeLargeTitle)
            }
        }
        .onPreferenceChange(ScrollBlurOpacityKey.self) { value in
            state.preferenceOpacity = value
            updateActiveOpacity()
        }
        .safeAreaPadding(bottomSafeArea ? .bottom : [])
        .background {
            if let backgroundColor {
                backgroundColor.ignoresSafeArea()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(navigationBarVisibility, for: .navigationBar)
        .toolbar {
            if collapsesTitleToToolbar {
                ToolbarItem(placement: .principal) {
                    if let fakeLargeTitle, !fakeLargeTitle.isEmpty {
                        BrightText(fakeLargeTitle, size: .subheading)
                            .opacity(state.activeTitleOpacity)
                            .blur(radius: (1 - state.activeTitleOpacity) * 6)
                            .scaleEffect(1.15 - 0.15 * state.activeTitleOpacity)
                    } else {
                        BrightText(".", size: .subheading)
                            .opacity(0)
                    }
                }
            }
        }
    }

    private var shouldShowFloatingPill: Bool {
        showInlineTabs
    }

    // MARK: Pager

    private var pager: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(pages.indices, id: \.self) { i in
                    page(at: i)
                        .containerRelativeFrame(.horizontal)
                        .id(i)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrollPosition)
        .scrollDisabled(disableHorizontalScroll)
        .scrollIndicators(.hidden)
        .brightHaptic(.impact, trigger: scrollPosition)
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.x } action: { _, new in
            state.scrollOffset = new
        }
        .onScrollGeometryChange(for: CGFloat.self) { $0.containerSize.width } action: { _, new in
            state.containerWidth = new
        }
        .onAppear { scrollPosition = selectedIndex }
        .onChange(of: scrollPosition) { _, newValue in
            if let newValue, newValue != selectedIndex {
                // Animate so anything bound to selectedIndex (e.g. conditional
                // toolbar items) transitions on swipe, matching the tab-tap path.
                withAnimation(.brightBouncy) { selectedIndex = newValue }
            }
            state.preferenceOpacity = 0
            updateActiveOpacity()
        }
        .onChange(of: selectedIndex) { _, newValue in
            if scrollPosition != newValue {
                withAnimation { scrollPosition = newValue }
            }
        }
    }

    @ViewBuilder
    private func page(at i: Int) -> some View {
        Group {
            if let fakeLargeTitle {
                ScrollView {
                    VStack(alignment: .leading, spacing: .spacing2x) {
                        if !fakeLargeTitle.isEmpty {
                            VStack(alignment: .leading, spacing: .spacing1x) {
                                HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
                                    BrightText(fakeLargeTitle, size: titleSize, weight: titleWeight)
                                    if let titleAccessory {
                                        titleAccessory
                                    }
                                }
                                if let titleSubtitle {
                                    titleSubtitle
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, .spacing3x)
                            // When the floating overlay is present it renders the
                            // visible (pinned) title; the per-page copy only reserves
                            // space so content keeps its position. With no overlay
                            // (showInlineTabs == false) the per-page title is shown.
                            .opacity(showInlineTabs ? 0 : 1)
                        }
                        // Reserve the pill row's height whether or not the inline
                        // tabs are shown, so hiding them (e.g. Health edit mode)
                        // doesn't shift the content up.
                        Color.clear.frame(height: SwipePageConstants.pillHeight)
                        content(i)
                    }
                }
                .scrollDismissesKeyboard(scrollDismissesKeyboardMode)
                .scrollDisabled(i == verticalScrollDisabledPageIndex)
                .modifier(OptionalRefresh(action: onRefresh))
                .modifier(OptionalScrollPosition(
                    position: i == scrollControlledPageIndex ? verticalScrollPosition : nil
                ))
            } else if showInlineTabs {
                content(i)
                    .frame(maxHeight: .infinity)
                    .safeAreaInset(edge: .top, spacing: 0) {
                        Color.clear.frame(height: SwipePageConstants.pillHeight + .spacing1x)
                    }
            } else {
                content(i)
                    .frame(maxHeight: .infinity)
            }
        }
        .onScrollGeometryChange(for: PageScrollMetrics.self) { geo in
            PageScrollMetrics(
                y: geo.contentOffset.y + geo.contentInsets.top,
                maxY: max(
                    0,
                    geo.contentSize.height + geo.contentInsets.top
                        + geo.contentInsets.bottom - geo.containerSize.height
                )
            )
        } action: { _, new in
            let newY = new.y
            state.pageOpacities[i] = min(1, max(0, (newY - 2) / 5))
            // Inline-title fade-in once the fake large title has scrolled out (~56pt).
            state.pageTitleOpacities[i] = min(1, max(0, (newY - 56) / 10))
            state.pageScrollY[i] = newY
            onPageScroll?(i, newY, new.maxY)
            if i == scrollPosition {
                updateActiveOpacity()
            }
        }
    }

    // MARK: Floating inline pill overlay

    @ViewBuilder
    private func floatingPillOverlay(fakeLargeTitle: String?) -> some View {
        let fakeLargeTitle = fakeLargeTitle ?? ""
        let activePage = scrollPosition ?? selectedIndex
        let scrollY = state.pageScrollY[activePage] ?? 0
        let upwardCap: CGFloat = fakeLargeTitle.isEmpty ? 0 : pillFollowMaxShift
        let pillFollowShift = -min(scrollY, upwardCap)

        // Fake the nav-bar scroll-edge fade: since the pinned title lives in the
        // overlay (not the scroll view), it no longer dissolves under the bar on
        // its own, so we fade + blur it out as it scrolls up toward the bar.
        let titleFadeStart: CGFloat = .spacing2x
        let titleFade = 1 - min(1, max(0, (scrollY - titleFadeStart) / pillFollowMaxShift))
        // Freeze the title once it has fully faded out — otherwise it keeps
        // travelling up one-to-one with the scroll and snaps back with force
        // (over a long, inconsistent distance) when you scroll down again.
        let titleFreeze = titleFadeStart + pillFollowMaxShift
        let titleShift = -min(scrollY, titleFreeze)

        let maxRangeX = max(0, CGFloat(pages.count - 1) * state.containerWidth)
        let horizontalOverscroll: CGFloat = {
            if state.scrollOffset < 0 { return -state.scrollOffset }
            if state.scrollOffset > maxRangeX { return maxRangeX - state.scrollOffset }
            return 0
        }()

        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: .spacing2x) {
                if !fakeLargeTitle.isEmpty {
                    VStack(alignment: .leading, spacing: .spacing1x) {
                        BrightText(fakeLargeTitle, size: titleSize, weight: titleWeight)
                        if let titleSubtitle {
                            titleSubtitle
                        }
                    }
                    .padding(.leading, .spacing3x)
                    .hidden()
                }
                inlineTabPillRow
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .offset(y: pillFollowShift)

            // Stuck title: fixed horizontally (lives outside the pager, so it
            // doesn't slide on page switches) yet tracks the active page's
            // vertical scroll one-to-one, so it scrolls fully out of sight.
            if !fakeLargeTitle.isEmpty {
                VStack(alignment: .leading, spacing: .spacing1x) {
                    HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
                        BrightText(fakeLargeTitle, size: titleSize, weight: titleWeight)
                        if let titleAccessory {
                            titleAccessory
                        }
                    }
                    if let titleSubtitle {
                        titleSubtitle
                    }
                }
                .padding(.leading, .spacing3x)
                .frame(maxWidth: .infinity, alignment: .leading)
                .offset(y: titleShift)
                .opacity(titleFade)
                .blur(radius: (1 - titleFade) * 5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .offset(x: horizontalOverscroll)
        .animation(.brightBouncy, value: scrollPosition)
    }

    private var inlineTabPillRow: some View {
        HStack(spacing: SwipePageConstants.inlineTabSpacing) {
            ForEach(pages.indices, id: \.self) { i in
                InlineTabPill(
                    title: pages[i].title,
                    systemImage: pages[i].systemImage,
                    isSelected: (scrollPosition ?? selectedIndex) == i,
                    action: {
                        withAnimation(.brightBouncy) {
                            scrollPosition = i
                            selectedIndex = i
                        }
                    }
                )
            }
        }
        .padding(.leading, .spacing3x)
    }

    // MARK: Derived state

    private func updateActiveOpacity() {
        let page = scrollPosition ?? selectedIndex
        let pageValue = state.pageOpacities[page] ?? 0
        // Use preferenceOpacity only for the page that set it (Insights),
        // which reports 0 from onScrollGeometryChange since it doesn't scroll directly.
        let newOpacity = pageValue > 0 ? pageValue : state.preferenceOpacity
        if state.activeOpacity != newOpacity {
            withAnimation(.brightEaseInOut) {
                state.activeOpacity = newOpacity
            }
        }
        let titleValue = state.pageTitleOpacities[page] ?? 0
        if state.activeTitleOpacity != titleValue {
            withAnimation(.brightEaseInOut) {
                state.activeTitleOpacity = titleValue
            }
        }
    }
}

// MARK: - Optional scroll position

// Applies `.scrollPosition` only when a binding is supplied, so pages without
// programmatic scroll control are left exactly as they were.
private struct OptionalScrollPosition: ViewModifier {
    let position: Binding<ScrollPosition>?

    func body(content: Content) -> some View {
        if let position {
            content.scrollPosition(position)
        } else {
            content
        }
    }
}

private struct OptionalRefresh: ViewModifier {
    let action: (() async -> Void)?

    func body(content: Content) -> some View {
        if let action {
            content.refreshable { await action() }
        } else {
            content
        }
    }
}

// MARK: - Inline pill tab

private struct InlineTabPill: View {
    let title: String
    let systemImage: String?
    let isSelected: Bool
    let action: () -> Void

    @State private var popTrigger: Int = 0
    @State private var suppressNextPop: Bool = false

    var body: some View {
        Button {
            suppressNextPop = true
            action()
        } label: {
            HStack(spacing: .spacing1x) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: SwipePageConstants.pillIconSize, weight: .medium))
                        .foregroundStyle(isSelected ? Color.textColor : Color.lightTextColor)
                }

                BrightText(
                    title,
                    size: .body1,
                    color: isSelected ? .textColor : .lightTextColor,
                    weight: .light
                )
            }
            .padding(.horizontal, .spacing105x)
            .frame(height: SwipePageConstants.pillHeight)
            .modifier(GlassEffect(shape: .capsule))
            .opacity(isSelected ? 1 : .semiLowOpacity)
            .keyframeAnimator(initialValue: 1.0, trigger: popTrigger) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(1.15, duration: 0.12)
                    CubicKeyframe(1.0, duration: 0.22)
                }
            }
            .padding(.vertical, .spacing1x)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .zIndex(isSelected ? 1 : 0)
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                if suppressNextPop {
                    suppressNextPop = false
                } else {
                    popTrigger += 1
                }
            } else {
                suppressNextPop = false
            }
        }
    }
}

// Not `private`: `pillFollowMaxShift` is the default for an initialiser parameter,
// so it has to be at least as visible as the initialiser itself.
enum SwipePageConstants {
    static let pillHeight: CGFloat = BrightButtonSizes.small.rawValue
    static let pillIconSize: CGFloat = 16
    static let inlineTabSpacing: CGFloat = .spacing1x
    // Max upward distance the floating pill travels as the big title scrolls away,
    // stopping it just below the nav bar.
    static let pillFollowMaxShift: CGFloat = 52
}
