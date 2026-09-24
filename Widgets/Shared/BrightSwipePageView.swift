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
    // Rendered as a template, so an asset icon picks up the selected/unselected
    // tint rather than keeping its own colours.
    let image: String?

    init(title: String, systemImage: String? = nil, image: String? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.image = image
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
    // The height of the title block above the pills, title-to-pill gap
    // included, measured from the overlay's hidden copy of it.
    var titleBlockHeight: CGFloat = 0
}

// MARK: - BrightSwipePageView

// Horizontal paging view with either a floating glass-pill header
// (`showHeader: true`) or an inline pill row below an optional big title.
struct BrightSwipePageView<Content: View>: View {
    let pages: [SwipePage]
    let fakeLargeTitle: String?
    let titleAccessory: AnyView?
    // Sits at the trailing end of the pill row — a filter or an action that
    // belongs to the page rather than to a nav bar. It travels with the
    // pills, so it stays beside them as they follow the title up.
    let pillAccessory: AnyView?
    // Size / weight of the large title. Defaults match the screen-level call
    // sites; sheets that follow a tighter header spec can shrink it.
    let titleSize: FontSizes
    let titleWeight: Font.Weight
    // Rendered directly beneath the large title (e.g. a session's time range and
    // source), so it scrolls, fades and blurs away with it.
    let titleSubtitle: AnyView?
    // The gap between the large title block and the pill row beneath it.
    // Both the visible overlay and the per-page spacer use it, so they stay
    // in step — a sheet with a tight header passes 0.
    let titlePillSpacing: CGFloat
    // How far the pill row travels upward as the large title scrolls away,
    // stopping it just below the nav bar. `nil` follows the title all the way:
    // the pills stop where the title block began, however tall it measures —
    // for a sheet, which has no bar to stop under.
    let pillFollowMaxShift: CGFloat?
    // Hide it to give a page the full sheet, e.g. an expanded map.
    let navigationBarVisibility: Visibility
    let showInlineTabs: Bool
    // When `false`, no pill draws as the selected one — for a sheet at a
    // height that shows the row but none of the page under it, where marking
    // one would promise a page that isn't there. The pager still has a
    // selection; only the row stops saying so.
    let marksSelectedPill: Bool
    let disableHorizontalScroll: Bool
    // When `true`, a page brings its own scroll view (or wants the bare
    // frame, as a Metal globe does), so the pager hands it the frame and
    // insets it under the title and pills instead of wrapping it in a scroll
    // view of its own. Defaults to `false` — the large title scrolls away
    // with the content, the way every screen-level call site takes it.
    let pagesBringTheirOwnScroll: Bool
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
    let onRefresh: (() async -> Void)?
    // A tap on a pill, selected or not, before the selection moves. The
    // selection change itself carries the haptic, so a tap on the pill that
    // is already selected is otherwise silent — a host can decide it is not.
    let onPillTap: ((Int) -> Void)?
    @Binding var selectedIndex: Int
    @ViewBuilder let content: (Int) -> Content

    @State private var scrollPosition: Int?
    @State private var hasSettledInitialPage = false

    // Pages the pills changed, so their haptic is not doubled by a swipe's.
    @State private var pillTapPending = false
    // Counts page changes that came from a swipe — the ones that buzz.
    @State private var swipeTick = 0
    @State private var state = BrightSwipePageState()

    init(
        pages: [SwipePage],
        fakeLargeTitle: String? = nil,
        titleAccessory: AnyView? = nil,
        pillAccessory: AnyView? = nil,
        titleSize: FontSizes = .huge205,
        titleWeight: Font.Weight = .light,
        titleSubtitle: AnyView? = nil,
        titlePillSpacing: CGFloat = .spacing2x,
        pillFollowMaxShift: CGFloat? = SwipePageConstants.pillFollowMaxShift,
        navigationBarVisibility: Visibility = .visible,
        showInlineTabs: Bool = true,
        marksSelectedPill: Bool = true,
        disableHorizontalScroll: Bool = false,
        pagesBringTheirOwnScroll: Bool = false,
        collapsesTitleToToolbar: Bool = true,
        scrollDismissesKeyboardMode: ScrollDismissesKeyboardMode = .automatic,
        onPageScroll: ((Int, CGFloat, CGFloat) -> Void)? = nil,
        verticalScrollPosition: Binding<ScrollPosition>? = nil,
        scrollControlledPageIndex: Int? = nil,
        verticalScrollDisabledPageIndex: Int? = nil,
        bottomSafeArea: Bool = true,
        backgroundColor: Color? = nil,
        onRefresh: (() async -> Void)? = nil,
        onPillTap: ((Int) -> Void)? = nil,
        selectedIndex: Binding<Int>,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self.pages = pages
        self.fakeLargeTitle = fakeLargeTitle
        self.titleAccessory = titleAccessory
        self.pillAccessory = pillAccessory
        self.titleSize = titleSize
        self.titleWeight = titleWeight
        self.titleSubtitle = titleSubtitle
        self.titlePillSpacing = titlePillSpacing
        self.pillFollowMaxShift = pillFollowMaxShift
        self.navigationBarVisibility = navigationBarVisibility
        self.showInlineTabs = showInlineTabs
        self.marksSelectedPill = marksSelectedPill
        self.disableHorizontalScroll = disableHorizontalScroll
        self.pagesBringTheirOwnScroll = pagesBringTheirOwnScroll
        self.collapsesTitleToToolbar = collapsesTitleToToolbar
        self.scrollDismissesKeyboardMode = scrollDismissesKeyboardMode
        self.onPageScroll = onPageScroll
        self.verticalScrollPosition = verticalScrollPosition
        self.scrollControlledPageIndex = scrollControlledPageIndex
        self.verticalScrollDisabledPageIndex = verticalScrollDisabledPageIndex
        self.bottomSafeArea = bottomSafeArea
        self.backgroundColor = backgroundColor
        self.onRefresh = onRefresh
        self.onPillTap = onPillTap
        _selectedIndex = selectedIndex
        // Start the scroll position at the selected page so the appear-time sync
        // is a no-op — otherwise the nil→index change trips `.brightHaptic`
        // and fires a spurious haptic when the view first mounts.
        _scrollPosition = State(initialValue: selectedIndex.wrappedValue)
        self.content = content
    }

    var body: some View {
        pager
            // An overlay, not a sibling in a stack: its size must not count.
            // In a sheet shorter than the title block it is taller than the
            // pager, and as a sibling it would size the whole view, which a
            // sheet then centres — lifting the title and everything pinned
            // beside it.
            // Its own view, not a function of this one: the header reads the
            // scroll state every frame a page moves, and a read here would
            // re-run the pager, and with it every page, on each of them.
            .overlay(alignment: .top) {
                if shouldShowFloatingPill {
                    FloatingPillOverlay(
                        state: state,
                        pages: pages,
                        fakeLargeTitle: fakeLargeTitle ?? "",
                        titleAccessory: titleAccessory,
                        titleSubtitle: titleSubtitle,
                        titleSize: titleSize,
                        titleWeight: titleWeight,
                        titlePillSpacing: titlePillSpacing,
                        pillFollowMaxShift: pillFollowMaxShift,
                        pillAccessory: pillAccessory,
                        marksSelectedPill: marksSelectedPill,
                        activePage: scrollPosition ?? selectedIndex,
                        scrollPosition: scrollPosition,
                        onPillTap: handlePillTap
                    )
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
            .brightSoftScrollEdges()
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
        ScrollViewReader { proxy in
            scrollView(proxy)
                // `scrollPosition` is seeded with the selected page, so assigning
                // it again can't move anything. Jumping through the proxy does,
                // and leaves the binding — and the haptic riding it — alone.
                .onAppear { proxy.scrollTo(selectedIndex) }
        }
    }

    private var initialAnchor: UnitPoint {
        guard pages.count > 1 else { return .leading }
        return UnitPoint(x: CGFloat(selectedIndex) / CGFloat(pages.count - 1), y: 0)
    }

    private func scrollView(_ proxy: ScrollViewProxy) -> some View {
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
        .defaultScrollAnchor(initialAnchor, for: .initialOffset)
        .scrollPosition(id: $scrollPosition)
        .scrollDisabled(disableHorizontalScroll)
        .scrollIndicators(.hidden)
        .brightHaptic(.impact, trigger: swipeTick)
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.x } action: { _, new in
            state.scrollOffset = new
        }
        .onScrollGeometryChange(for: CGFloat.self) { $0.containerSize.width } action: { _, new in
            state.containerWidth = new
            if !hasSettledInitialPage, new > 0 {
                hasSettledInitialPage = true
                proxy.scrollTo(selectedIndex)
            }
        }
        .onChange(of: scrollPosition) { _, newValue in
            // A swipe clicks into place; a pill tap already buzzed in the
            // tag, so the change it drives is silent here.
            if pillTapPending {
                pillTapPending = false
            } else {
                swipeTick += 1
            }
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
            if let fakeLargeTitle, !pagesBringTheirOwnScroll {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
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
                            .padding(.bottom, titlePillSpacing)
                        }
                        // Reserve the pill row's height whether or not the inline
                        // tabs are shown, so hiding them (e.g. Health edit mode)
                        // doesn't shift the content up.
                        Color.clear
                            .frame(height: SwipePageConstants.pillHeight)
                            .padding(.bottom, .spacing2x)
                        content(i)
                    }
                }
                .scrollDismissesKeyboard(scrollDismissesKeyboardMode)
                .scrollDisabled(i == verticalScrollDisabledPageIndex)
                .modifier(OptionalRefresh(action: onRefresh))
                .modifier(OptionalScrollPosition(
                    position: i == scrollControlledPageIndex ? verticalScrollPosition : nil
                ))
                .modifier(PageScrollTracking { handlePageScroll(at: i, metrics: $0) })
            } else if showInlineTabs {
                content(i)
                    .frame(maxHeight: .infinity)
                    .safeAreaInset(edge: .top, spacing: 0) {
                        // Clear of the pills, and of the title above them when
                        // there is one — measured, since the page has no copy
                        // of the title to reserve the space for it.
                        Color.clear
                            .frame(height: state.titleBlockHeight + SwipePageConstants.pillHeight + .spacing1x)
                    }
                    // Reports the page's own scroll view, so the title and
                    // pills follow it up exactly as they do when the pager
                    // supplies the scroll view itself. A page with no scroll
                    // view of its own — a globe — simply never reports, and
                    // its title stays put.
                    .modifier(PageScrollTracking { handlePageScroll(at: i, metrics: $0) })
            } else {
                content(i)
                    .frame(maxHeight: .infinity)
            }
        }
    }

    private func handlePageScroll(at i: Int, metrics: PageScrollMetrics) {
        onPageScroll?(i, metrics.y, metrics.maxY)
        // The header follows the first stretch of a scroll and then holds:
        // the title has faded and frozen, the pills have stopped under it.
        // Past that point the offset is clamped, so a long scroll writes
        // once at the cap and the header sits still instead of re-rendering
        // every frame to the same place. Everything below reads the same
        // numbers the overlay does.
        let followRun = pillFollowMaxShift ?? state.titleBlockHeight
        let headerCap = max(SwipePageConstants.titleFadeSettled, .spacing2x + followRun)
        let newY = min(metrics.y, headerCap)
        // The geometry reports on any change, and a sheet changing height
        // changes the container every frame while it moves. Only the offset
        // drives the header, so a report that leaves it where it was writes
        // nothing — an observable write fires its readers whether or not
        // the value moved.
        guard state.pageScrollY[i] != newY else { return }
        state.pageOpacities[i] = min(1, max(0, (newY - 2) / 5))
        state.pageTitleOpacities[i] = min(1, max(0, (newY - 56) / 10))
        state.pageScrollY[i] = newY
        if i == scrollPosition {
            updateActiveOpacity()
        }
    }

    // MARK: Floating inline pill overlay

    // A pill tap, selected or not: tell the host, then move the page.
    private func handlePillTap(_ i: Int) {
        // Only a tap that moves the page is followed by a
        // change to keep quiet for; one on the selected
        // pill would leave the flag set for the next swipe.
        if (scrollPosition ?? selectedIndex) != i { pillTapPending = true }
        onPillTap?(i)
        withAnimation(.brightBouncy) {
            scrollPosition = i
            selectedIndex = i
        }
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

// MARK: - Floating pill overlay

// The pinned title and the pill row under it, following the active page's
// scroll. It reads `BrightSwipePageState` in its own body, so a scroll
// write re-renders this and leaves the pager and its pages alone.
private struct FloatingPillOverlay: View {
    let state: BrightSwipePageState
    let pages: [SwipePage]
    let fakeLargeTitle: String
    let titleAccessory: AnyView?
    let titleSubtitle: AnyView?
    let titleSize: FontSizes
    let titleWeight: Font.Weight
    let titlePillSpacing: CGFloat
    let pillFollowMaxShift: CGFloat?
    let pillAccessory: AnyView?
    let marksSelectedPill: Bool
    let activePage: Int
    let scrollPosition: Int?
    let onPillTap: (Int) -> Void

    var body: some View {
        let scrollY = state.pageScrollY[activePage] ?? 0
        let followRun = pillFollowMaxShift ?? state.titleBlockHeight
        let upwardCap: CGFloat = fakeLargeTitle.isEmpty ? 0 : followRun
        let pillFollowShift = -min(scrollY, upwardCap)

        // Fake the nav-bar scroll-edge fade: since the pinned title lives in the
        // overlay (not the scroll view), it no longer dissolves under the bar on
        // its own, so we fade + blur it out as it scrolls up toward the bar.
        let titleFadeStart: CGFloat = .spacing2x
        let titleFade = 1 - min(1, max(0, (scrollY - titleFadeStart) / max(1, followRun)))
        // Freeze the title once it has fully faded out — otherwise it keeps
        // travelling up one-to-one with the scroll and snaps back with force
        // (over a long, inconsistent distance) when you scroll down again.
        let titleFreeze = titleFadeStart + followRun
        let titleShift = -min(scrollY, titleFreeze)

        let maxRangeX = max(0, CGFloat(pages.count - 1) * state.containerWidth)
        let horizontalOverscroll: CGFloat = {
            if state.scrollOffset < 0 { return -state.scrollOffset }
            if state.scrollOffset > maxRangeX { return maxRangeX - state.scrollOffset }
            return 0
        }()

        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                if !fakeLargeTitle.isEmpty {
                    VStack(alignment: .leading, spacing: .spacing1x) {
                        BrightText(fakeLargeTitle, size: titleSize, weight: titleWeight)
                        if let titleSubtitle {
                            titleSubtitle
                        }
                    }
                    .padding(.leading, .spacing3x)
                    .padding(.bottom, titlePillSpacing)
                    // At its natural height, whatever the overlay is given.
                    // In a short sheet the overlay is shorter than the title,
                    // and a squeezed copy would set the pills higher than
                    // the slot the page reserves for them — so they would
                    // drop as the sheet grows.
                    .fixedSize(horizontal: false, vertical: true)
                    .hidden()
                    // The space the title reserves for itself, in the overlay
                    // that carries the pills — and, measured, how far the
                    // pills may follow it up.
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                        state.titleBlockHeight = height
                    }
                }
                pillRow
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
                .fixedSize(horizontal: false, vertical: true)
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

    private var pillRow: some View {
        HStack(spacing: SwipePageConstants.inlineTabSpacing) {
            ForEach(pages.indices, id: \.self) { i in
                BrightTag(
                    title: pages[i].title,
                    image: pages[i].image,
                    systemImage: pages[i].systemImage,
                    isSelected: marksSelectedPill && activePage == i,
                    action: { onPillTap(i) }
                )
            }

            if let pillAccessory {
                Spacer(minLength: .spacing1x)
                pillAccessory
            }
        }
        .padding(.leading, .spacing3x)
        .padding(.trailing, pillAccessory == nil ? 0 : .spacing3x)
    }
}

private struct PageScrollTracking: ViewModifier {
    let onChange: (PageScrollMetrics) -> Void

    func body(content: Content) -> some View {
        content
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
                onChange(new)
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

// Not `private`: `pillFollowMaxShift` is the default for an initialiser parameter,
// so it has to be at least as visible as the initialiser itself.
enum SwipePageConstants {
    static let pillHeight: CGFloat = BrightButtonSizes.small.rawValue
    static let inlineTabSpacing: CGFloat = .spacing1x
    // Max upward distance the floating pill travels as the big title scrolls away,
    // stopping it just below the nav bar.
    static let pillFollowMaxShift: CGFloat = 52
    // The scroll offset past which the page and title opacities the header
    // derives from a scroll have both reached 1: (56 + 10) in
    // `handlePageScroll`. Beyond it a scroll changes nothing the header shows.
    static let titleFadeSettled: CGFloat = 66
}
