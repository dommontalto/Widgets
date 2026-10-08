//
//  HealthWidgetEditor.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import SwiftUI

// Edit-mode state for the Health grid: jiggle, the add/edit sheets, dragging,
// and auto-scrolling the page while a widget is held near an edge.
@MainActor @Observable
final class HealthWidgetEditor {
    let layout = HealthWidgetLayout()

    var isEditing = false {
        didSet {
            guard !isEditing else { return }
            endAutoScroll()
            dragging = nil
        }
    }

    var isShowingAddSheet = false
    var editingWidget: HealthWidgetItem?

    var isShowingSheet: Bool {
        isShowingAddSheet || editingWidget != nil
    }

    // Fed by the page's scroll view so a held widget can push it.
    var scrollOffsetY: CGFloat = 0
    var scrollMaxOffsetY: CGFloat = 0
    var scrollPosition = ScrollPosition(edge: .top)

    private(set) var dragging: Drag?

    struct Drag: Equatable {
        let widgetID: UUID
        var origin: CGPoint
        var translation: CGSize = .zero
        var scrollOffset: CGFloat = 0
        var target: HealthGridPosition?
        var isLifted = true

        var location: CGPoint {
            CGPoint(x: origin.x + translation.width, y: origin.y + translation.height + scrollOffset)
        }
    }

    @ObservationIgnored private var dragStartScrollY: CGFloat = 0
    @ObservationIgnored private var autoScrollDirection: CGFloat = 0
    @ObservationIgnored private var autoScrollTask: Task<Void, Never>?

    func beginEditing() {
        guard !isEditing else { return }
        BrightHaptic.medium.play()
        withAnimation(.brightEaseInOut) {
            isEditing = true
        }
    }

    func endEditing() {
        BrightHaptic.medium.play()
        withAnimation(.brightEaseInOut) {
            isEditing = false
        }
    }

    // Adds a widget at the end of the grid, then scrolls down to it once the sheet
    // has gone. The first widget on an empty grid also starts edit mode.
    func add(_ widget: HealthWidgetItem) {
        let wasEmpty = layout.widgets.isEmpty
        layout.add(widget)

        if wasEmpty {
            withAnimation(.brightEaseInOut) {
                isEditing = true
            }
        }

        Task { @MainActor in
            try? await Task.sleep(for: Constants.revealDelay)
            withAnimation(.brightEaseInOut) {
                scrollPosition.scrollTo(edge: .bottom)
            }
        }
    }

    func remove(_ widget: HealthWidgetItem) {
        BrightHaptic.success.play()
        withAnimation(.brightSpring) {
            layout.remove(id: widget.id)
        }
    }

    // MARK: - Dragging

    func dragChanged(_ value: DragGesture.Value, widget: HealthWidgetItem, cellSize: CGFloat, viewportHeight: CGFloat) {
        if dragging?.widgetID != widget.id {
            guard let position = layout.positions[widget.id] else { return }
            dragStartScrollY = scrollOffsetY
            withAnimation(.brightSpring) {
                dragging = Drag(widgetID: widget.id, origin: HealthWidgetGridMetrics.origin(of: position, cellSize: cellSize))
            }
        }
        dragging?.translation = value.translation

        if let location = dragging?.location,
           let target = layout.cell(at: location, cellSize: cellSize),
           target != dragging?.target {
            dragging?.target = target
            withAnimation(.brightSpring) {
                layout.preview(widget, at: target)
            }
        }

        let halfHeight = HealthWidgetGridMetrics.frame(for: widget.size, cellSize: cellSize).height / 2
        let edgeZone = viewportHeight / Constants.edgeZoneFraction
        if value.location.y + halfHeight > viewportHeight - edgeZone {
            startAutoScroll(direction: 1)
        } else if value.location.y - halfHeight < edgeZone {
            startAutoScroll(direction: -1)
        } else {
            endAutoScroll()
        }
    }

    func dragEnded(widget: HealthWidgetItem, cellSize: CGFloat) {
        endAutoScroll()
        guard var drag = dragging, let landing = layout.positions[widget.id] else { return }

        // Re-base onto the landing cell so the release springs from where the finger let go.
        drag.scrollOffset = scrollOffsetY - dragStartScrollY
        let current = drag.location
        drag.origin = HealthWidgetGridMetrics.origin(of: landing, cellSize: cellSize)
        drag.translation = CGSize(width: current.x - drag.origin.x, height: current.y - drag.origin.y)
        drag.scrollOffset = 0
        dragging = drag

        withAnimation(.brightSpring) {
            dragging?.translation = .zero
            dragging?.isLifted = false
        } completion: { [weak self] in
            guard self?.dragging?.widgetID == widget.id else { return }
            self?.dragging = nil
        }

        layout.commitDrag()
    }

    // MARK: - Auto-scroll

    private func startAutoScroll(direction: CGFloat) {
        autoScrollDirection = direction
        guard autoScrollTask == nil else { return }
        autoScrollTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.autoScrollStep()
                try? await Task.sleep(for: Constants.autoScrollFrame)
            }
        }
    }

    private func endAutoScroll() {
        autoScrollTask?.cancel()
        autoScrollTask = nil
        autoScrollDirection = 0
    }

    private func autoScrollStep() {
        guard autoScrollDirection != 0 else { return }
        let target = min(max(scrollOffsetY + autoScrollDirection * Constants.autoScrollSpeed, 0), scrollMaxOffsetY)
        scrollPosition.scrollTo(point: CGPoint(x: 0, y: target))
        // Follows the page's real movement, so the widget stops when the page pins at an edge.
        dragging?.scrollOffset = scrollOffsetY - dragStartScrollY
    }

    private enum Constants {
        static let edgeZoneFraction: CGFloat = 8
        static let autoScrollSpeed: CGFloat = 5
        static let autoScrollFrame: Duration = .milliseconds(16)
        static let revealDelay: Duration = .milliseconds(300)
    }
}
