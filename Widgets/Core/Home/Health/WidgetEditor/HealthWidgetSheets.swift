//
//  HealthWidgetSheets.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import SwiftUI

struct AddWidgetSheet: View {
    let onAdd: (HealthWidgetItem) -> Void
    let onReset: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()
    @State private var isConfirmingReset = false

    var body: some View {
        BrightPageSheetViewV5(title: "Add Widget", path: $path) {
            ScrollView {
                VStack(spacing: .spacing4x) {
                    BrightRowGroupV5(color: .defaultSheetModalCards) {
                        ForEach(HealthWidgetKind.allCases) { kind in
                            BrightRowV5(kind.title, icon: .symbol(kind.systemImage, tint: kind.tint)) {
                                path.append(kind)
                            }
                        }
                    }

                    BrightRowGroupV5(color: .defaultSheetModalCards) {
                        BrightRowV5("Reset to default", icon: .symbol("arrow.counterclockwise"), trailing: .none) {
                            BrightHaptic.medium.play()
                            isConfirmingReset = true
                        }
                    }
                }
                .padding(.vertical, .spacing3x)
            }
            .scrollIndicators(.hidden)
            .navigationDestination(for: HealthWidgetKind.self) { kind in
                ChooseWidgetSizePage(kind: kind) { widget in
                    onAdd(widget)
                    dismiss()
                }
            }
            .alert("Reset layout?", isPresented: $isConfirmingReset) {
                Button("Cancel", role: .cancel) {}

                Button("Reset", role: .destructive) {
                    onReset()
                    dismiss()
                }
                .tint(.defaultRed)
            } message: {
                Text("Your widgets go back to the default layout.")
            }
        }
    }
}

struct EditWidgetSheet: View {
    let onSave: (HealthWidgetItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var widget: HealthWidgetItem

    init(widget: HealthWidgetItem, onSave: @escaping (HealthWidgetItem) -> Void) {
        self.onSave = onSave
        _widget = State(initialValue: widget)
    }

    var body: some View {
        BrightPageSheetViewV5(title: "Edit Widget", horizontalPadding: .spacing0x) {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    BrightHaptic.medium.play()
                    onSave(widget)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.defaultSkyBlue)
            }
        } content: {
            WidgetOptions(widget: $widget)
        }
    }
}

private struct ChooseWidgetSizePage: View {
    let onAdd: (HealthWidgetItem) -> Void

    @State private var widget: HealthWidgetItem

    init(kind: HealthWidgetKind, onAdd: @escaping (HealthWidgetItem) -> Void) {
        self.onAdd = onAdd
        _widget = State(initialValue: HealthWidgetItem(kind: kind, size: .small))
    }

    var body: some View {
        BrightPageViewV5(
            title: widget.kind.title,
            scrollableTitle: false,
            horizontalPadding: .spacing0x,
            backgroundColor: .defaultSheetBackground
        ) {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add") {
                    BrightHaptic.medium.play()
                    onAdd(widget)
                }
                .buttonStyle(.borderedProminent)
                .tint(.defaultSkyBlue)
            }
        } content: {
            WidgetOptions(widget: $widget)
        }
    }
}

// The widget on top, swiped between its styles, and its settings below.
private struct WidgetOptions: View {
    @Binding var widget: HealthWidgetItem

    @State private var stylePosition = ScrollPosition(idType: HealthWidgetStyle.self)
    @State private var edgeProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let cellSize = HealthWidgetGridMetrics.cellSize(containerWidth: geometry.size.width)
            let frame = HealthWidgetGridMetrics.frame(for: widget.size, cellSize: cellSize)
            let previewHeight = min(
                frame.height + .spacing4x * 2 + Constants.indicatorHeight,
                geometry.size.height - Constants.minimumPanelHeight
            )

            VStack(spacing: .spacing0x) {
                stylePager(cellSize: cellSize, room: previewHeight - Constants.indicatorHeight)
                    .frame(height: previewHeight)
                    .brightEdgeV5(progress: edgeProgress)
                    .zIndex(1)

                panel
            }
        }
        .animation(.brightBouncy, value: widget.size)
        .animation(.brightEaseInOut, value: widget.window)
        .onAppear {
            stylePosition.scrollTo(id: widget.style)
        }
    }

    private func stylePager(cellSize: CGFloat, room: CGFloat) -> some View {
        VStack(spacing: .spacing0x) {
            ScrollView(.horizontal) {
                HStack(spacing: .spacing0x) {
                    ForEach(widget.kind.styles) { style in
                        preview(of: style, cellSize: cellSize, room: room)
                            .containerRelativeFrame(.horizontal)
                            .id(style)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition($stylePosition)
            .onScrollTargetVisibilityChange(idType: HealthWidgetStyle.self, threshold: Constants.visibilityThreshold) { visible in
                if let style = visible.first, style != widget.style {
                    select(style)
                }
            }

            BrightPageIndicatorV5(total: widget.kind.styles.count, activeIndex: styleIndex)
                .frame(height: Constants.indicatorHeight, alignment: .top)
        }
    }

    // Shrinks to fit when the sheet is too short to show it at grid size.
    private func preview(of style: HealthWidgetStyle, cellSize: CGFloat, room: CGFloat) -> some View {
        var shown = widget
        shown.style = style
        if !style.sizes.contains(shown.size), let largest = style.sizes.last {
            shown.size = largest
        }
        let frame = HealthWidgetGridMetrics.frame(for: shown.size, cellSize: cellSize)
        let scale = min(max((room - .spacing4x * 2) / frame.height, 0), 1)

        return HealthWidgetView(widget: shown)
            .id(shown.window)
            .transition(.blurReplace)
            .frame(width: frame.width, height: frame.height)
            .scaleEffect(scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var panel: some View {
        ScrollView {
            settings
                .padding(.spacing3x)
        }
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            let progress = BrightEdgeV5.progress(forOffset: offset)
            guard progress != edgeProgress else { return }
            edgeProgress = progress
        }
        .frame(maxHeight: .infinity)
    }

    private var settings: some View {
        VStack(spacing: .spacing4x) {
            if widget.style.sizes.count > 1 {
                Picker("Size", selection: $widget.size) {
                    ForEach(widget.style.sizes, id: \.self) { size in
                        Text(size.title)
                            .tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .brightHapticV5(.light, trigger: widget.size)
                // A style with different sizes gets a new control that fades in, rather than
                // this one reshaping its segments, which smears its shadow mid-swipe.
                .id(widget.style.sizes)
                .transition(.opacity)
            }

            if widget.style.hasWindow {
                windowGroup("Rolling", windows: [.rolling1h, .rolling6h, .rolling12h])

                windowGroup("Fixed", windows: [.fixed6h, .fixed12h])
            } else {
                BrightPlaceholderViewV5(
                    systemImage: "slider.horizontal.3",
                    title: "No other customisation",
                    subtitle: "This widget only changes size."
                )
                .padding(.top, .spacing4x)
            }
        }
        .animation(.brightEaseInOut, value: widget.style)
    }

    private func windowGroup(_ header: String, windows: [BrightLineChartWidgetV5.Window]) -> some View {
        BrightRowGroupV5(header: header) {
            ForEach(windows) { option in
                BrightRowV5(option.span, trailing: .tick(option == widget.window)) {
                    BrightHaptic.light.play()
                    widget.window = option
                }
            }
        }
    }

    // A style that can't be shown at the current size takes its largest one instead.
    private func select(_ style: HealthWidgetStyle) {
        BrightHaptic.light.play()
        widget.style = style
        if !style.sizes.contains(widget.size), let largest = style.sizes.last {
            widget.size = largest
        }
    }

    private var styleIndex: Binding<Int?> {
        Binding {
            widget.kind.styles.firstIndex(of: widget.style)
        } set: { index in
            guard let index, widget.kind.styles.indices.contains(index) else { return }
            withAnimation(.brightSnappy) {
                stylePosition.scrollTo(id: widget.kind.styles[index])
            }
        }
    }

    private enum Constants {
        static let minimumPanelHeight: CGFloat = 200
        // The indicator's own 30pt pill, plus a gap above the scroll edge line.
        static let indicatorHeight: CGFloat = .spacing6x
        static let visibilityThreshold: Double = 0.5
    }
}
