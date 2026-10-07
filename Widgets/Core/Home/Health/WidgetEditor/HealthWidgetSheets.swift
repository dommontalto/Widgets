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
                ChooseWidgetSizePage(kind: kind) { size, window in
                    onAdd(HealthWidgetItem(kind: kind, size: size, window: window))
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
    let widget: HealthWidgetItem
    let onSave: (BrightWidgetSizeV5, BrightLineChartWidgetV5.Window) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var size: BrightWidgetSizeV5
    @State private var window: BrightLineChartWidgetV5.Window

    init(widget: HealthWidgetItem, onSave: @escaping (BrightWidgetSizeV5, BrightLineChartWidgetV5.Window) -> Void) {
        self.widget = widget
        self.onSave = onSave
        _size = State(initialValue: widget.size)
        _window = State(initialValue: widget.window)
    }

    var body: some View {
        BrightPageSheetViewV5(title: "Edit Widget", horizontalPadding: .spacing0x) {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    BrightHaptic.medium.play()
                    onSave(size, window)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.defaultSkyBlue)
            }
        } content: {
            WidgetOptions(kind: widget.kind, size: $size, window: $window)
        }
    }
}

private struct ChooseWidgetSizePage: View {
    let kind: HealthWidgetKind
    let onAdd: (BrightWidgetSizeV5, BrightLineChartWidgetV5.Window) -> Void

    @State private var size = BrightWidgetSizeV5.small
    @State private var window = BrightLineChartWidgetV5.Window.rolling1h

    var body: some View {
        BrightPageViewV5(
            title: kind.title,
            scrollableTitle: false,
            horizontalPadding: .spacing0x,
            backgroundColor: .defaultSheetBackground
        ) {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add") {
                    BrightHaptic.medium.play()
                    onAdd(size, window)
                }
                .buttonStyle(.borderedProminent)
                .tint(.defaultSkyBlue)
            }
        } content: {
            WidgetOptions(kind: kind, size: $size, window: $window)
        }
    }
}

// The size carousel, with the time range below it picked from a mini sheet.
private struct WidgetOptions: View {
    let kind: HealthWidgetKind
    @Binding var size: BrightWidgetSizeV5
    @Binding var window: BrightLineChartWidgetV5.Window

    @State private var isPickingWindow = false

    var body: some View {
        VStack(spacing: .spacing0x) {
            WidgetSizeCarousel(kind: kind, window: window, selection: $size)

            BrightRowGroupV5(color: .defaultSheetModalCards) {
                BrightRowV5("Time range", icon: .symbol("clock"), trailing: .value(window.title)) {
                    BrightHaptic.light.play()
                    isPickingWindow = true
                }
            }
            .padding([.horizontal, .bottom], .spacing3x)
        }
        .brightMiniSheetV5(isPresented: $isPickingWindow) {
            WidgetWindowPicker(selection: $window) {
                isPickingWindow = false
            }
        }
    }
}

private struct WidgetWindowPicker: View {
    @Binding var selection: BrightLineChartWidgetV5.Window
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightText("Time range", size: .heading)

            group("Rolling", windows: [.rolling1h, .rolling6h, .rolling12h])

            group("Fixed", windows: [.fixed6h, .fixed12h])
        }
        .padding([.top, .horizontal], .spacing4x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) {
            BrightRoundButton(systemImage: "xmark", size: .large, onTapCallback: onClose)
                .padding(.top, .spacing3x)
                .padding(.trailing, .spacing3x)
        }
    }

    private func group(_ header: String, windows: [BrightLineChartWidgetV5.Window]) -> some View {
        BrightRowGroupV5(header: header, color: .defaultSheetModalCards) {
            ForEach(windows) { window in
                BrightRowV5(window.span, trailing: .tick(window == selection)) {
                    BrightHaptic.light.play()
                    selection = window
                    onClose()
                }
            }
        }
    }
}

// Pages through a widget's sizes, each drawn at the size it takes on the grid.
private struct WidgetSizeCarousel: View {
    let kind: HealthWidgetKind
    let window: BrightLineChartWidgetV5.Window
    @Binding var selection: BrightWidgetSizeV5

    @State private var scrollPosition = ScrollPosition(idType: BrightWidgetSizeV5.self)
    @State private var containerWidth: CGFloat = 0

    var body: some View {
        let cellSize = HealthWidgetGridMetrics.cellSize(containerWidth: containerWidth)

        VStack(spacing: .spacing0x) {
            Spacer(minLength: .spacing0x)

            ScrollView(.horizontal) {
                HStack(spacing: .spacing0x) {
                    ForEach(kind.sizes, id: \.self) { size in
                        page(for: size, cellSize: cellSize)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition($scrollPosition)
            .scrollClipDisabled()
            .onScrollTargetVisibilityChange(idType: BrightWidgetSizeV5.self, threshold: Constants.visibilityThreshold) { visible in
                if let first = visible.first, first != selection {
                    selection = first
                }
            }

            Spacer(minLength: .spacing0x)

            BrightPageIndicatorV5(total: kind.sizes.count, activeIndex: selectedIndex)
                .padding(.bottom, .spacing5x)
        }
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { containerWidth = $0 }
        .onAppear {
            scrollPosition.scrollTo(id: selection)
        }
        .onChange(of: selection) { _, newSize in
            guard scrollPosition.viewID(type: BrightWidgetSizeV5.self) != newSize else { return }
            withAnimation(.brightSnappy) {
                scrollPosition.scrollTo(id: newSize)
            }
        }
    }

    private func page(for size: BrightWidgetSizeV5, cellSize: CGFloat) -> some View {
        let frame = HealthWidgetGridMetrics.frame(for: size, cellSize: cellSize)

        return VStack(spacing: .spacing3x) {
            HealthWidgetView(kind: kind, size: size, window: window)
                .frame(width: frame.width, height: frame.height)
                .allowsHitTesting(false)

            BrightText(size.title, size: .body1, color: .semiLightTextColor)
        }
        .containerRelativeFrame(.horizontal)
        .scrollTransition(.animated(.brightBouncy)) { content, phase in
            content
                .opacity(phase.isIdentity ? .opaque : .semiLowOpacity)
                .scaleEffect(phase.isIdentity ? 1 : Constants.offPageScale)
                .blur(radius: phase.isIdentity ? 0 : Constants.offPageBlur)
        }
        .id(size)
    }

    private var selectedIndex: Binding<Int?> {
        Binding {
            kind.sizes.firstIndex(of: selection)
        } set: { index in
            guard let index, kind.sizes.indices.contains(index) else { return }
            selection = kind.sizes[index]
        }
    }

    private enum Constants {
        static let visibilityThreshold: Double = 0.5
        static let offPageScale: CGFloat = 0.85
        static let offPageBlur: CGFloat = 2
    }
}
