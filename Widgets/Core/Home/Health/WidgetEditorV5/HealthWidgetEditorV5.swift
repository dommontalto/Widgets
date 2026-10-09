//
//  HealthWidgetEditorV5.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import SwiftUI

// Edit-mode state for the Health grid: jiggle, the add/edit sheets, dragging,
// and auto-scrolling the page while a widget is held near an edge.
@MainActor @Observable
final class HealthWidgetEditorV5 {
    let layout = HealthWidgetLayoutV5()

    var isEditing = false {
        didSet {
            guard !isEditing else { return }
            endAutoScroll()
            dragging = nil
            resizing = nil
            isResizing = false
        }
    }

    var isShowingAddSheet = false
    var editingWidget: HealthWidgetItemV5?

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
        var target: HealthGridPositionV5?
        var isLifted = true

        var location: CGPoint {
            CGPoint(x: origin.x + translation.width, y: origin.y + translation.height + scrollOffset)
        }
    }

    private(set) var resizing: Resize?
    // Kept apart from `resizing` so the page can stop scrolling under the handle without
    // redrawing on every frame of the drag.
    private(set) var isResizing = false

    // Held by its top corner on the side away from the handle, so the frame stretches
    // from a fixed point however the grid reflows underneath it.
    struct Resize: Equatable {
        let widgetID: UUID
        let row: Int
        let startColumn: Int
        let anchor: CGPoint
        let growsLeading: Bool
        let startFrame: CGSize
        var translation: CGSize = .zero

        // The frame under the finger, rubber-banding past the style's smallest and
        // largest sizes the way a scroll view does past its ends.
        func frame(for sizes: [BrightWidgetSizeV5], cellSize: CGFloat) -> CGSize {
            let raw = rawFrame
            let frames = sizes.map { HealthWidgetGridMetricsV5.frame(for: $0, cellSize: cellSize) }
            return CGSize(
                width: Self.rubberBand(raw.width, between: frames.map(\.width)),
                height: Self.rubberBand(raw.height, between: frames.map(\.height))
            )
        }

        func isPastLimit(for sizes: [BrightWidgetSizeV5], cellSize: CGFloat) -> Bool {
            let raw = rawFrame
            let frames = sizes.map { HealthWidgetGridMetricsV5.frame(for: $0, cellSize: cellSize) }
            return Self.isOutside(raw.width, frames.map(\.width)) || Self.isOutside(raw.height, frames.map(\.height))
        }

        private var rawFrame: CGSize {
            CGSize(
                width: startFrame.width + (growsLeading ? -translation.width : translation.width),
                height: startFrame.height + translation.height
            )
        }

        private static func isOutside(_ value: CGFloat, _ limits: [CGFloat]) -> Bool {
            guard let lower = limits.min(), let upper = limits.max() else { return false }
            return value < lower || value > upper
        }

        private static func rubberBand(_ value: CGFloat, between limits: [CGFloat]) -> CGFloat {
            guard let lower = limits.min(), let upper = limits.max() else { return value }
            if value < lower {
                return lower - resisted(lower - value)
            }
            if value > upper {
                return upper + resisted(value - upper)
            }
            return value
        }

        // Eases towards `reach` however far the finger goes.
        private static func resisted(_ overshoot: CGFloat) -> CGFloat {
            let reach = CGFloat.spacing4x
            return reach * (1 - 1 / (overshoot / reach * Constants.rubberBandStiffness + 1))
        }

        func origin(for frame: CGSize) -> CGPoint {
            growsLeading ? CGPoint(x: anchor.x - frame.width, y: anchor.y) : anchor
        }

        // The cell a size lands in, its anchored edge kept where it started.
        func position(for size: BrightWidgetSizeV5) -> HealthGridPositionV5 {
            let lastColumn = HealthWidgetGridMetricsV5.columns - size.columns
            return HealthGridPositionV5(row: row, col: growsLeading ? lastColumn : min(startColumn, lastColumn))
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
    func add(_ widget: HealthWidgetItemV5) {
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

    func remove(_ widget: HealthWidgetItemV5) {
        BrightHaptic.success.play()
        withAnimation(.brightSpring) {
            layout.remove(id: widget.id)
        }
    }

    // MARK: - Dragging

    func dragChanged(_ value: DragGesture.Value, widget: HealthWidgetItemV5, cellSize: CGFloat, viewportHeight: CGFloat) {
        if dragging?.widgetID != widget.id {
            guard let position = layout.positions[widget.id] else { return }
            dragStartScrollY = scrollOffsetY
            withAnimation(.brightSpring) {
                dragging = Drag(widgetID: widget.id, origin: HealthWidgetGridMetricsV5.origin(of: position, cellSize: cellSize))
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

        let halfHeight = HealthWidgetGridMetricsV5.frame(for: widget.size, cellSize: cellSize).height / 2
        let edgeZone = viewportHeight / Constants.edgeZoneFraction
        if value.location.y + halfHeight > viewportHeight - edgeZone {
            startAutoScroll(direction: 1)
        } else if value.location.y - halfHeight < edgeZone {
            startAutoScroll(direction: -1)
        } else {
            endAutoScroll()
        }
    }

    func dragEnded(widget: HealthWidgetItemV5, cellSize: CGFloat) {
        endAutoScroll()
        guard var drag = dragging, let landing = layout.positions[widget.id] else { return }

        // Re-base onto the landing cell so the release springs from where the finger let go.
        drag.scrollOffset = scrollOffsetY - dragStartScrollY
        let current = drag.location
        drag.origin = HealthWidgetGridMetricsV5.origin(of: landing, cellSize: cellSize)
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

    // MARK: - Resizing

    // The frame follows the finger while the size underneath snaps to whichever of the
    // style's sizes it's closest to, reflowing the grid around it as it goes.
    func resizeChanged(_ value: DragGesture.Value, widget: HealthWidgetItemV5, cellSize: CGFloat) {
        guard let current = layout.widgets.first(where: { $0.id == widget.id }) else { return }
        if resizing?.widgetID != widget.id {
            guard let position = layout.positions[widget.id] else { return }
            let frame = HealthWidgetGridMetricsV5.frame(for: current.size, cellSize: cellSize)
            let origin = HealthWidgetGridMetricsV5.origin(of: position, cellSize: cellSize)
            let growsLeading = position.col > 0
            resizing = Resize(
                widgetID: widget.id,
                row: position.row,
                startColumn: position.col,
                anchor: growsLeading ? CGPoint(x: origin.x + frame.width, y: origin.y) : origin,
                growsLeading: growsLeading,
                startFrame: frame
            )
            isResizing = true
        }
        let wasPastLimit = resizing?.isPastLimit(for: current.style.sizes, cellSize: cellSize) == true
        resizing?.translation = value.translation
        if !wasPastLimit, resizing?.isPastLimit(for: current.style.sizes, cellSize: cellSize) == true {
            BrightHaptic.light.play()
        }

        guard let resizing,
              let size = HealthWidgetGridMetricsV5.nearestSize(
                  to: resizing.frame(for: current.style.sizes, cellSize: cellSize),
                  in: current.style.sizes,
                  cellSize: cellSize
              ),
              size != current.size else { return }

        BrightHaptic.light.play()
        withAnimation(.brightSpring) {
            layout.resize(current, to: size, at: resizing.position(for: size))
        }
    }

    // Bounces the frame onto the size it snapped to. Also runs when the touch is cancelled,
    // so a resize can never be left half-held for the next one to pick up.
    func resizeEnded() {
        guard resizing != nil else { return }
        isResizing = false
        layout.commitDrag()
        withAnimation(.brightBouncy) {
            resizing = nil
        }
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
        static let rubberBandStiffness: CGFloat = 0.55
    }
}
