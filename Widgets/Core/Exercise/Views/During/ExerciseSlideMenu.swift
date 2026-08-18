//
//  ExerciseSlideMenu.swift
//  Widgets
//
//  Created by Dom Montalto on 12/5/2026.
//

import SwiftUI

// The live run's left-edge menu, built as two pages of one horizontal scroll
// view: the menu, then the content. Scrolling back to the menu walks the content
// right and brings the menu on from the left, and the drag, the snap and the
// rubber band all come from the scroll view rather than a hand-rolled gesture.
//
// Nothing is offset, scaled or clipped, so the content keeps whatever corners it
// already had.
struct ExerciseSlideMenu<MenuContent: View, Content: View>: View {
    // A share of the screen rather than a width: it has to be settled before the
    // scroll view lays out, or the content grows underneath a scroll offset that
    // has already come to rest and the menu starts out part-open.
    var sideBarRatio: CGFloat = Constants.defaultSideBarRatio
    @Binding var isExpanded: Bool
    @ViewBuilder var menuContent: MenuContent
    @ViewBuilder var content: Content

    @State private var page: ExerciseSlideMenuPage? = .content
    @State private var haptic = false

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: .spacing0x) {
                    menuContent
                        .frame(width: proxy.size.width * sideBarRatio)
                        .frame(maxHeight: .infinity)
                        .id(ExerciseSlideMenuPage.menu)

                    content
                        .frame(width: proxy.size.width)
                        .frame(maxHeight: .infinity)
                        .overlay { closeCatcher }
                        .id(ExerciseSlideMenuPage.content)
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $page, anchor: .leading)
            .scrollBounceBehavior(.basedOnSize)
            .defaultScrollAnchor(.trailing)
        }
        .background {
            Color.defaultBackground
                .ignoresSafeArea()
        }
        .brightHaptic(.soft, trigger: haptic)
        // Every open and close lands here — the drag's own comes back around
        // through the page handler below — so the haptic only needs firing once.
        .onChange(of: isExpanded) { _, isExpanded in
            haptic.toggle()

            let wanted: ExerciseSlideMenuPage = isExpanded ? .menu : .content
            guard page != wanted else { return }
            withAnimation(.brightSnappy) { page = wanted }
        }
        .onChange(of: page) { _, page in
            let expanded = page == .menu
            guard expanded != isExpanded else { return }
            isExpanded = expanded
        }
    }

    // No dimming — this only exists so a tap on the pushed-aside content closes
    // the menu instead of reaching the controls behind it.
    private var closeCatcher: some View {
        Color.clear
            .contentShape(.rect)
            .allowsHitTesting(isExpanded)
            .onTapGesture { isExpanded = false }
    }
}

private enum ExerciseSlideMenuPage: Hashable {
    case menu
    case content
}

private enum Constants {
    static let defaultSideBarRatio: CGFloat = 0.8
}
