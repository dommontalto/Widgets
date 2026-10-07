//
//  SwipeViewModifier.swift
//  Widgets
//
//  Created by Gangajaliya Sandeep on 1/9/2023.
//

import Foundation
import SwiftUI

public struct SwipeViewModifier: ViewModifier {
    // swipe cell modifier
    // - Parameters:
    //   - id: the string id of this cell. The default value is a uuid string. If you want to set the
    // currentUserInteractionCellID yourself, e.g. for tap to close functionality, you need to override this id value
    // with your own cell id.
    //   - cellWidth: the width of the content view - typically a cell or row in a list under which the swipe to reveal
    // menu should appear.
    //   - leadingSideGroup: the button group on the leading side that shall appear when the user swipes the cell to the
    // right
    //   - trailingSideGroup: the button group on the trailing side that shall appear when the user swipes the cell to
    // the left
    //   - currentUserInteractionCellID: a Binding of an optional UUID that should be set either in the view model of
    // the parent view in which the cells appear or as a State variable into the parent view itself. Don't assign it a
    // value!
    //   - settings: settings. can be omitted in which case the settings struct default values apply.

    var id: String
    // Measured from the cell when omitted or infinite.
    var cellWidth: CGFloat?
    var leadingSideGroup: [SwipeViewModifierActionItem] = []
    var trailingSideGroup: [SwipeViewModifierActionItem] = []
    @Binding var currentUserInteractionCellID: String?
    var settings = SwipeViewModifierSettings()
    var cornerRadius: CGFloat = 0

    @State private var offsetX: CGFloat = 0
    @State private var measuredWidth: CGFloat = 0

    @State private var hapticFeedbackOccurred = false
    @State private var openSideLock: SwipeViewModifierGroupSide?

    @Binding var shouldHideActions: Bool
    public var trailingRevealed: (() -> Void)?

    private var width: CGFloat {
        if let cellWidth, cellWidth.isFinite { cellWidth } else { measuredWidth }
    }

    public func body(content: Content) -> some View {
        ZStack {
            if leadingSideGroup.isEmpty == false,
               offsetX != 0 {
                swipeToRevealArea(swipeItemGroup: leadingSideGroup, side: .leading)
            }

            if trailingSideGroup.isEmpty == false, offsetX != 0 {
                swipeToRevealArea(swipeItemGroup: trailingSideGroup, side: .trailing)
            }

            content
                .offset(x: offsetX)
                .highPriorityGesture(
                    DragGesture(
                        minimumDistance: 30,
                        coordinateSpace: .local
                    )
                    .onChanged(dragOnChanged(value:))
                    .onEnded(dragOnEnded(value:))
                )
        }
        .edgesIgnoringSafeArea(.horizontal)
        .clipped()
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { measuredWidth = $0 }
        .onChange(of: currentUserInteractionCellID) {
            if let currentDragCellID = currentUserInteractionCellID,
               currentDragCellID != id, openSideLock != nil {
                // if this cell has an open side area and is not the cell being dragged, close the cell
                setOffsetX(value: 0)
                // reset the drag cell id to nil
                currentUserInteractionCellID = nil
            }
        }
        .onChange(of: shouldHideActions) {
            if shouldHideActions {
                setOffsetX(value: 0)
            }
        }
    }

    func swipeToRevealArea(
        swipeItemGroup: [SwipeViewModifierActionItem],
        side: SwipeViewModifierGroupSide
    ) -> some View {
        HStack {
            if side == .trailing {
                Spacer()
            }
            ZStack {
                HStack(spacing: 0) {
                    ForEach(swipeItemGroup) { item in
                        Button {
                            setOffsetX(value: 0)
                            Task { @MainActor in
                                try? await Task.sleep(for: .seconds(0.3))
                                item.actionCallback()
                            }
                        } label: {
                            buttonContentView(item: item, group: swipeItemGroup, side: side)
                        }.buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
            .opacity(swipeRevealAreaOpacity(side: side))

            if side == .leading {
                Spacer()
            }
        }
        .cornerRadius(cornerRadius)
    }

    func buttonContentView(
        item: SwipeViewModifierActionItem,
        group: [SwipeViewModifierActionItem],
        side: SwipeViewModifierGroupSide
    ) -> some View {
        ZStack {
            item.backgroundColor
            HStack {
                if warnSwipeOutCondition(
                    side: side,
                    hasSwipeOut: item.swipeOutAction
                ),
                    item.swipeOutButtonView != nil {
                    item.swipeOutButtonView!()
                } else {
                    item.buttonView()
                }
            }

        }.frame(width: itemButtonWidth(item: item, itemGroup: group, side: side))
    }

    func menuWidth(side: SwipeViewModifierGroupSide) -> CGFloat {
        switch side {
        case .leading:
            leadingSideGroup.map(\.buttonWidth).reduce(0, +)
        case .trailing:
            trailingSideGroup.map(\.buttonWidth).reduce(0, +)
        }
    }

    // MARK: drag gesture

    func dragOnChanged(value: DragGesture.Value) {
        let horizontalTranslation = value.translation.width
        if nonDraggableCondition(horizontalTranslation: horizontalTranslation) {
            return
        }

        if openSideLock != nil {
            // if one side is open, we need to add the menu width!
            let menuWidth = openSideLock == .leading ? menuWidth(side: .leading) : menuWidth(side: .trailing)
            offsetX = menuWidth * openSideLock!.sideFactor + horizontalTranslation
            triggerHapticFeedbackIfNeeded(horizontalTranslation: horizontalTranslation)
            return
        }

        triggerHapticFeedbackIfNeeded(horizontalTranslation: horizontalTranslation)

        if horizontalTranslation > 8 || horizontalTranslation <
            -8 { // makes sure the swipe cell doesn't open too easily
            currentUserInteractionCellID = id
            offsetX = horizontalTranslation
        } else {
            offsetX = 0
        }
    }

    func nonDraggableCondition(horizontalTranslation: CGFloat) -> Bool {
        offsetX == 0 &&
            (leadingSideGroup.isEmpty && horizontalTranslation > 0 || trailingSideGroup
                .isEmpty && horizontalTranslation < 0)
    }

    func dragOnEnded(value: DragGesture.Value) {
        let swipeOutTriggerValue = width * settings.swipeOutTriggerRatio

        if offsetX == 0 {
            openSideLock = nil
        } else if offsetX > 0 {
            if leadingSideGroup.isEmpty == false {
                if offsetX < settings.openTriggerValue
                    || (openSideLock == .leading && offsetX < menuWidth(side: .leading) * 0.8) {
                    setOffsetX(value: 0)
                } else if let leftItem = leadingSideGroup.filter({ $0.swipeOutAction == true }).first,
                          offsetX.magnitude > swipeOutTriggerValue {
                    swipeOutAction(item: leftItem, sideFactor: 1)
                } else {
                    lockSideMenu(side: .leading)
                }
            } else {
                // leading group emtpy
                setOffsetX(value: 0)
            }
        } else if offsetX < 0 {
            if trailingSideGroup.isEmpty == false {
                if offsetX.magnitude < settings.openTriggerValue
                    || (openSideLock == .trailing && offsetX > -menuWidth(side: .trailing) * 0.8) {
                    setOffsetX(value: 0)
                } else if let rightItem = trailingSideGroup.filter({ $0.swipeOutAction == true }).first,
                          offsetX.magnitude > swipeOutTriggerValue {
                    swipeOutAction(item: rightItem, sideFactor: -1)
                } else {
                    lockSideMenu(side: .trailing)
                }
            } else {
                // trailing group emtpy
                setOffsetX(value: 0)
            }
        }
    }

    func triggerHapticFeedbackIfNeeded(horizontalTranslation: CGFloat) {
        let side: SwipeViewModifierGroupSide = horizontalTranslation > 0 ? .leading : .trailing
        let group = side == .leading ? leadingSideGroup : trailingSideGroup

        let swipeOutActionCondition = warnSwipeOutCondition(side: side, hasSwipeOut: true)
        if let item = swipeOutItemWithHapticFeedback(group: group),
           hapticFeedbackOccurred == false,
           swipeOutActionCondition == true {
            item.swipeOutHapticFeedbackType!.play()
            hapticFeedbackOccurred = true
        }
    }

    func swipeOutItemWithHapticFeedback(
        group: [SwipeViewModifierActionItem]
    ) -> SwipeViewModifierActionItem? {
        if let item = group.filter({ $0.swipeOutAction == true }).first {
            if item.swipeOutHapticFeedbackType != nil {
                return item
            }
        }
        return nil
    }

    func swipeOutAction(item: SwipeViewModifierActionItem, sideFactor: CGFloat) {
        if item.swipeOutIsDestructive {
            let swipeOutWidth = width + 10
            setOffsetX(value: swipeOutWidth * sideFactor)
            openSideLock = nil
        } else {
            setOffsetX(value: 0) // open side lock set in function!
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.3))
            item.actionCallback()
        }
    }

    func lockSideMenu(side: SwipeViewModifierGroupSide) {
        setOffsetX(value: side.sideFactor * menuWidth(side: side))
        openSideLock = side
        hapticFeedbackOccurred = false
    }

    func setOffsetX(value: CGFloat) {
        withAnimation(.brightSpring) {
            offsetX = value
        }
        if offsetX == 0 {
            openSideLock = nil
            hapticFeedbackOccurred = false
        } else {
            trailingRevealed?()
        }
    }

    func itemButtonWidth(
        item: SwipeViewModifierActionItem,
        itemGroup: [SwipeViewModifierActionItem],
        side: SwipeViewModifierGroupSide
    ) -> CGFloat {
        let dynamicButtonWidth = dynamicButtonWidth(item: item, itemCount: itemGroup.count, side: side)
        let triggerValue = width * settings.swipeOutTriggerRatio
        let swipeOutActionCondition = side == .leading ? offsetX > triggerValue : offsetX < -triggerValue

        if item.swipeOutAction, swipeOutActionCondition {
            return offsetX.magnitude + settings.addWidthMargin
        } else if swipeOutActionCondition, item.swipeOutAction == false, itemGroup.contains(where: {
            $0.swipeOutAction == true
        }) {
            return 0
        } else {
            return dynamicButtonWidth
        }
    }

    func dynamicButtonWidth(
        item: SwipeViewModifierActionItem,
        itemCount: Int,
        side: SwipeViewModifierGroupSide
    ) -> CGFloat {
        let menuWidth = menuWidth(side: side)
        return (offsetX.magnitude + settings.addWidthMargin) * (item.buttonWidth / menuWidth)
    }

    func warnSwipeOutCondition(
        side: SwipeViewModifierGroupSide,
        hasSwipeOut: Bool
    ) -> Bool {
        if hasSwipeOut == false { return false }
        let triggerValue = width * settings.swipeOutTriggerRatio
        return (side == .trailing && offsetX < -triggerValue) || (side == .leading && offsetX > triggerValue)
    }

    func swipeRevealAreaOpacity(side: SwipeViewModifierGroupSide) -> Double {
        switch side {
        case .leading:
            offsetX > 5 ? 1 : 0
        case .trailing:
            offsetX < -5 ? 1 : 0
        }
    }
}

extension View {
    public func castToAnyView() -> AnyView {
        AnyView(self)
    }
}

public enum SwipeViewModifierGroupSide {
    case leading
    case trailing

    var sideFactor: CGFloat {
        switch self {
        case .leading:
            1

        case .trailing:
            -1
        }
    }
}

public struct SwipeViewModifierActionItem: Identifiable {
    public var id: String
    public var buttonView: () -> AnyView
    public var swipeOutButtonView: (() -> AnyView)?
    public var buttonWidth: CGFloat
    public var backgroundColor: Color
    public var swipeOutAction: Bool
    public var swipeOutHapticFeedbackType: BrightHaptic?
    public var swipeOutIsDestructive: Bool
    public var actionCallback: () -> Void

    /**
     Initializer
     - Parameter id: Required to identify each buttin in the side menu. Default is a random uuid string.
     - Parameter buttonView: The view in the foreground of the menu button. Make sure to set a maximum frame height less than the cell height!
     - Parameter swipeOutButtonView: Alternative button view that is displayed only when the offset during swipe is beyond the swipe out trigger value.
     - Parameter  buttonWidth: Width of the button. The the open side menu width is calculated from the sum of all button widths. Default is 75.
     - Parameter backgroundColor: The background colour of the the menu button.
     - Parameter swipeOutAction: A Boolean that determines if a swipe out action is activated or not. Default is false.
     - Parameter swipeOutHapticFeedbackType: If a swipeOutAction is activated, a haptic feedback will occur after the swipe out threshold is passed. Default is nil.
     - Parameter swipeOutIsDestructive: A Boolean that determines if the swipe out is destructive. If true, the content cell view will be "move out of sight" once the swipe out is triggered.
     */
    public init(
        id: String = UUID().uuidString,
        buttonView: @escaping () -> AnyView,
        swipeOutButtonView: (() -> AnyView)? = nil,
        buttonWidth: CGFloat = 75,
        backgroundColor: Color,
        swipeOutAction: Bool = false,
        swipeOutHapticFeedbackType: BrightHaptic? = nil,
        swipeOutIsDestructive: Bool = true,
        actionCallback: @escaping () -> Void
    ) {
        self.id = id
        self.buttonView = buttonView
        self.swipeOutButtonView = swipeOutButtonView
        self.buttonWidth = buttonWidth
        self.backgroundColor = backgroundColor
        self.swipeOutAction = swipeOutAction
        self.swipeOutHapticFeedbackType = swipeOutHapticFeedbackType
        self.swipeOutIsDestructive = swipeOutIsDestructive
        self.actionCallback = actionCallback
    }
}

// Swipe View Settings
public struct SwipeViewModifierSettings {
    // initializer
    public init(
        openTriggerValue: CGFloat = 60,
        swipeOutTriggerRatio: CGFloat = 0.7,
        addWidthMargin: CGFloat = 0
    ) {
        self.openTriggerValue = openTriggerValue
        self.swipeOutTriggerRatio = swipeOutTriggerRatio
        self.addWidthMargin = addWidthMargin
    }
    // minimum horizontal translation value necessary to open the side menu
    public var openTriggerValue: CGFloat
    // the ratio of the total cell width that triggers a swipe out action (provided one action has swipe out activated)
    public var swipeOutTriggerRatio: CGFloat = 0.7
    // An additional value to add to the open menu width. This is useful if the cell has rounded corners.
    public var addWidthMargin: CGFloat = .cardCornerRadius
}
