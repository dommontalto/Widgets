//
//  CarouselView.swift
//  Widgets
//
//  Created by Zoe Friedman on 28/7/2023.
//

import SwiftUI

private enum Constants {
    static let swipeThreshold: CGFloat = 50
}

@Observable
class CarouselViewState {
    init(
        activeIndex: Int = 0,
        screenDrag: Float = 0.0,
        maxViewWidth: CGFloat = UIScreen.main.bounds.width,
        activeCardWidth: CGFloat = UIScreen.main.bounds.width,
        hiddenCardWidth: CGFloat = UIScreen.main.bounds.width,
        peakingCardWidth: CGFloat = 0,
        cardSpacing: CGFloat = 0
    ) {
        self.activeIndex = activeIndex
        self.screenDrag = screenDrag
        self.maxViewWidth = maxViewWidth
        self.activeCardWidth = activeCardWidth
        self.hiddenCardWidth = hiddenCardWidth
        self.peakingCardWidth = peakingCardWidth
        self.cardSpacing = cardSpacing
    }

    static func empty() -> CarouselViewState {
        .init()
    }

    var activeIndex: Int
    var screenDrag: Float
    var maxViewWidth: CGFloat
    var activeCardWidth: CGFloat
    var hiddenCardWidth: CGFloat
    var peakingCardWidth: CGFloat
    var cardSpacing: CGFloat
}

struct CarouselView<Items: View>: View {
    @Bindable var viewState: CarouselViewState

    let items: Items
    let numberOfItems: Int
    var onActiveItemChanged: ((Int) -> Void)?

    @GestureState var isDetectingDrag = false

    @inlinable
    init(
        viewState: CarouselViewState,
        numberOfItems: Int,
        onActiveItemChanged: ((Int) -> Void)? = nil,
        @ViewBuilder _ items: () -> Items
    ) {
        self.viewState = viewState
        self.numberOfItems = numberOfItems
        self.onActiveItemChanged = onActiveItemChanged
        self.items = items()
    }

    var body: some View {
        let totalSpacing = (CGFloat(numberOfItems) - 1) * viewState.cardSpacing
        let totalCanvasWidth: CGFloat = viewState
            .activeCardWidth + (viewState.hiddenCardWidth * (CGFloat(numberOfItems) - 1)) + totalSpacing
        let xOffsetToShift = (totalCanvasWidth - viewState.maxViewWidth) / 2
        let leftPadding = viewState.peakingCardWidth + viewState.cardSpacing
        let totalMovement = viewState.hiddenCardWidth + viewState.cardSpacing

        let activeOffset = xOffsetToShift + leftPadding - (totalMovement * CGFloat(viewState.activeIndex))
        let nextOffset = xOffsetToShift + leftPadding - (totalMovement * CGFloat(viewState.activeIndex) + 1)

        var calcOffset = Float(activeOffset)

        if calcOffset != Float(nextOffset) {
            calcOffset = Float(activeOffset) + viewState.screenDrag
        }

        return HStack(alignment: .center, spacing: viewState.cardSpacing) {
            items
        }
        .offset(x: CGFloat(calcOffset), y: 0)
        .highPriorityGesture(
            DragGesture()
                .onChanged { value in
                    if (viewState.activeIndex == 0 && value.translation.width > 0) ||
                        (viewState.activeIndex == numberOfItems - 1 && value.translation.width < 0) {
                        viewState.screenDrag = Float(value.translation.width) / 2 // Reduce drag sensitivity
                    } else {
                        viewState.screenDrag = Float(value.translation.width)
                    }
                }
                .onEnded { value in
                    viewState.screenDrag = 0

                    if value.translation.width < -Constants.swipeThreshold, viewState.activeIndex < numberOfItems - 1 {
                        viewState.activeIndex += 1
                    } else if value.translation.width > Constants.swipeThreshold, viewState.activeIndex > 0 {
                        viewState.activeIndex -= 1
                    }

                    withAnimation(
                        .bouncy(duration: 1, extraBounce: 0.5)
                    ) {
                        if (viewState.activeIndex == 0 && value.translation.width > 0) ||
                            (viewState.activeIndex == numberOfItems - 1 && value.translation.width < 0) {
                            viewState.screenDrag = 0
                        }
                    }

                    onActiveItemChanged?(viewState.activeIndex)
                }
        )
        .animation(
            .interpolatingSpring(stiffness: 300, damping: 20),
            value: viewState.screenDrag
        )
    }
}

#Preview {
    VStack {
        CarouselView(viewState: CarouselViewState.empty(), numberOfItems: 3) {
            Image("sb_demo")
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width)
            Image("scc_demo")
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width)
            Image("sg_demo")
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width)
        }
    }
}
