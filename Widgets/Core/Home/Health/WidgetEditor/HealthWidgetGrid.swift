//
//  HealthWidgetGrid.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import SwiftUI

struct HealthWidgetView: View {
    let kind: HealthWidgetKind
    let size: BrightWidgetSizeV5
    var allowsSelection = true

    var body: some View {
        switch kind {
        case .heartRate:
            BrightLineChartWidgetV5(
                title: kind.title,
                systemImage: kind.systemImage,
                tint: kind.tint,
                unit: "BPM",
                samples: HealthWidgetDemo.heartRate,
                events: HealthWidgetDemo.heartRateEvents,
                size: size,
                allowsSelection: allowsSelection
            )
        }
    }
}

struct HealthWidgetGrid: View {
    @Bindable var editor: HealthWidgetEditor

    @State private var containerWidth: CGFloat = 0
    @State private var jigglePhase = false

    private var layout: HealthWidgetLayout {
        editor.layout
    }

    var body: some View {
        let cellSize = HealthWidgetGridMetrics.cellSize(containerWidth: containerWidth)

        ZStack(alignment: .topLeading) {
            if layout.widgets.isEmpty {
                emptyState(cellSize: cellSize)
            }

            ForEach(Array(layout.widgets.enumerated()), id: \.element.id) { index, widget in
                tile(widget, index: index, cellSize: cellSize)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(
            height: max(layout.height(cellSize: cellSize), cellSize + HealthWidgetGridMetrics.spacing * 2),
            alignment: .top
        )
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { containerWidth = $0 }
        .task(id: isJiggling) {
            guard isJiggling else {
                withAnimation(.brightEaseInOut) {
                    jigglePhase = false
                }
                return
            }
            // Flips faster than the swing animation lasts, so each swing is cut off
            // mid-arc. That's what gives the iOS home-screen jitter rather than a sway.
            while !Task.isCancelled {
                try? await Task.sleep(for: Constants.jiggleInterval)
                jigglePhase.toggle()
            }
        }
    }

    private var isJiggling: Bool {
        editor.isEditing && !editor.isShowingSheet
    }

    @ViewBuilder
    private func tile(_ widget: HealthWidgetItem, index: Int, cellSize: CGFloat) -> some View {
        if let position = layout.positions[widget.id] {
            let drag = editor.dragging?.widgetID == widget.id ? editor.dragging : nil
            let isLifted = drag?.isLifted == true
            let frame = HealthWidgetGridMetrics.frame(for: widget.size, cellSize: cellSize)
            let origin = drag?.location ?? HealthWidgetGridMetrics.origin(of: position, cellSize: cellSize)

            HealthWidgetView(kind: widget.kind, size: widget.size, allowsSelection: !editor.isEditing)
                .frame(width: frame.width, height: frame.height)
                .contentShape(.rect(cornerRadius: .cardCornerRadius))
                .overlay(alignment: .topTrailing) {
                    if editor.isEditing {
                        removeButton(for: widget)
                    }
                }
                .modifier(HealthJiggleModifier(isEnabled: isJiggling, phase: jigglePhase, seed: index))
                .animation(.brightJigglePhase, value: jigglePhase)
                .scaleEffect(isLifted ? Constants.liftedScale : 1)
                .shadow(color: .black.opacity(isLifted ? .veryLowOpacity : .zero), radius: Constants.liftedShadowRadius)
                .offset(x: origin.x, y: origin.y)
                .zIndex(drag == nil ? 0 : 1)
                .animation(drag == nil ? .brightSpring : nil, value: position)
                .transition(.scale(scale: Constants.removedScale).combined(with: .opacity))
                .onTapGesture {
                    guard editor.isEditing, editor.dragging == nil else { return }
                    BrightHaptic.medium.play()
                    editor.editingWidget = widget
                }
                .gesture(editor.isEditing ? dragGesture(for: widget, cellSize: cellSize) : nil)
        }
    }

    private func dragGesture(for widget: HealthWidgetItem, cellSize: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: Constants.dragMinimumDistance, coordinateSpace: .global)
            .onChanged { value in
                editor.dragChanged(value, widget: widget, cellSize: cellSize, viewportHeight: UIScreen.main.bounds.height)
            }
            .onEnded { _ in
                editor.dragEnded(widget: widget, cellSize: cellSize)
            }
    }

    private func removeButton(for widget: HealthWidgetItem) -> some View {
        BrightRoundButton(systemImage: "minus", size: .small, fontSize: .body5, haptic: nil) {
            editor.remove(widget)
        }
        .offset(x: .spacing05x, y: -.spacing05x)
    }

    private func emptyState(cellSize: CGFloat) -> some View {
        BrightPillButton("Add widget", systemImage: "plus") {
            BrightHaptic.medium.play()
            editor.isShowingAddSheet = true
        }
        .frame(maxWidth: .infinity)
        .frame(height: cellSize)
        .padding(.top, HealthWidgetGridMetrics.spacing)
    }

    private enum Constants {
        static let liftedScale: CGFloat = 1.05
        static let removedScale: CGFloat = 0.92
        static let liftedShadowRadius: CGFloat = 10
        static let dragMinimumDistance: CGFloat = 5
        static let jiggleInterval: Duration = .milliseconds(100)
    }
}

// Each tile rocks with its own amplitude and direction, seeded by its index,
// so the grid doesn't sway in unison.
private struct HealthJiggleModifier: ViewModifier {
    let isEnabled: Bool
    let phase: Bool
    let seed: Int

    private var rotation: Double {
        Constants.baseRotation + Double(seed % 5) * Constants.rotationStep
    }

    private var offset: CGFloat {
        Constants.baseOffset + CGFloat((seed * 7) % 5) * Constants.offsetStep
    }

    func body(content: Content) -> some View {
        let isLeaning = seed.isMultiple(of: 2) ? !phase : phase
        content
            .rotationEffect(.degrees(isEnabled ? (isLeaning ? rotation : -rotation) : 0))
            .offset(x: isEnabled ? (isLeaning ? offset : -offset) : 0)
    }

    private enum Constants {
        static let baseRotation: Double = 0.4
        static let rotationStep: Double = 0.15
        static let baseOffset: CGFloat = 0.8
        static let offsetStep: CGFloat = 0.2
    }
}
