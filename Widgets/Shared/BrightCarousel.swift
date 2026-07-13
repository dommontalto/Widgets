//
//  BrightCarousel.swift
//  Widgets
//
//  Created by Dom Montalto on 13/7/2026.
//

import SwiftUI

struct BrightCarouselTier: Identifiable, Hashable {
    let id: String
    let name: String
    let label: String
}

struct BrightCarousel<Item: Identifiable & Hashable, Card: View>: View {
    let items: [Item]
    @Binding var activeIndex: Int?
    var cardWidthRatio: CGFloat = 0.65
    var tiers: ((Item) -> [BrightCarouselTier])?
    var selectedTiers: Binding<[Item.ID: BrightCarouselTier]>?
    @ViewBuilder let card: (Item, CGFloat) -> Card

    @State private var scrollPosition: ScrollPosition
    @State private var carouselWidth: CGFloat = 0
    @State private var hapticTrigger = 0
    @State private var visibleIndex: Int?
    @State private var scrollTarget: Item.ID?

    init(
        items: [Item],
        activeIndex: Binding<Int?>,
        cardWidthRatio: CGFloat = 0.65,
        tiers: ((Item) -> [BrightCarouselTier])? = nil,
        selectedTiers: Binding<[Item.ID: BrightCarouselTier]>? = nil,
        @ViewBuilder card: @escaping (Item, CGFloat) -> Card
    ) {
        self.items = items
        self._activeIndex = activeIndex
        self.cardWidthRatio = cardWidthRatio
        self.tiers = tiers
        self.selectedTiers = selectedTiers
        self.card = card
        self._scrollPosition = State(initialValue: .init(idType: Item.ID.self))
    }

    private var cardWidth: CGFloat {
        guard carouselWidth > 0 else { return 200 }
        return carouselWidth * cardWidthRatio
    }

    private var horizontalInset: CGFloat {
        guard carouselWidth > 0 else { return .spacing4x }
        return (carouselWidth - cardWidth) / 2
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: .spacing05x) {
                ForEach(items) { item in
                    VStack(spacing: .spacing4x) {
                        card(item, cardWidth)
                        if tiers != nil {
                            tierMenu(item)
                        }
                    }
                    .frame(width: cardWidth)
                    .contentShape(Rectangle())
                    .scrollTransition(.animated(.brightBouncy)) { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : 0.5)
                            .scaleEffect(phase.isIdentity ? 1 : 0.85)
                    }
                    .id(item.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition($scrollPosition)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .contentMargins(.horizontal, horizontalInset, for: .scrollContent)
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { carouselWidth = $0 }
        .onScrollTargetVisibilityChange(idType: Item.ID.self, threshold: 0.5) { visible in
            guard let first = visible.first,
                  let index = items.firstIndex(where: { $0.id == first }) else { return }
            visibleIndex = index
            if let target = scrollTarget {
                if first == target {
                    scrollTarget = nil
                    hapticTrigger += 1
                }
                return
            }
            if activeIndex != index {
                activeIndex = index
                hapticTrigger += 1
            }
        }
        .onChange(of: activeIndex) { _, newIndex in
            guard let newIndex, items.indices.contains(newIndex), newIndex != visibleIndex else { return }
            scrollTarget = items[newIndex].id
            withAnimation(.brightBouncy) {
                scrollPosition.scrollTo(id: items[newIndex].id)
            }
        }
        .onScrollPhaseChange { _, newPhase in
            if newPhase == .idle, scrollTarget != nil {
                scrollTarget = nil
                if activeIndex != visibleIndex { activeIndex = visibleIndex }
            }
        }
        .onAppear {
            if let index = activeIndex, items.indices.contains(index) {
                scrollPosition.scrollTo(id: items[index].id)
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: hapticTrigger)
    }

    // MARK: Tier picker

    private func tierMenu(_ item: Item) -> some View {
        let itemTiers = tiers?(item) ?? []
        let selected = selectedTiers?.wrappedValue[item.id] ?? itemTiers.first

        return Menu {
            ForEach(itemTiers) { tier in
                Button {
                    selectedTiers?.wrappedValue[item.id] = tier
                } label: {
                    Label {
                        Text("\(tier.name) — \(tier.label)")
                    } icon: {
                        if tier.id == selected?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: .spacing1x) {
                Text(selected?.name ?? "")
                    .font(.standard(size: .subheading2, weight: .light))
                    .foregroundStyle(Color.textColor)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.semiLightTextColor)
            }
            .animation(.brightBouncy, value: selected?.id)
            .frame(maxWidth: .infinity)
        }
    }
}
