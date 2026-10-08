//
//  HealthWidgetGrid.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import SwiftUI

struct HealthWidgetView: View {
    let widget: HealthWidgetItem
    var allowsSelection = true

    var body: some View {
        switch (widget.kind, widget.style) {
        case (.heartRate, .lineChart):
            BrightLineChartWidgetV5(
                appearance: heartRateAppearance,
                samples: HealthWidgetDemo.heartRate,
                events: HealthWidgetDemo.heartRateEvents,
                range: widget.range,
                size: widget.size,
                allowsSelection: allowsSelection
            )
        case (.water, .leadingNumber):
            BrightLeadingNumberWidgetV5(
                appearance: HealthWidgetDemo.water.appearance,
                value: HealthWidgetDemo.waterToday,
                latest: HealthWidgetDemo.anchor
            )
        case (.water, .waterRing) where widget.size == .small:
            BrightRingGroupWidgetV5(rings: [HealthWidgetDemo.waterRing], size: widget.size, allowsSelection: allowsSelection) {
                ringHeader(HealthWidgetDemo.water.appearance.title, systemImage: HealthWidgetDemo.water.appearance.systemImage, color: widget.kind.tint)
            }
        case (.water, .waterRing):
            BrightRingGroupWidgetV5(rings: HealthWidgetDemo.waterRings, size: widget.size, allowsSelection: allowsSelection)
        case (.water, _):
            barChart(HealthWidgetDemo.water)
        case (.weight, .leadingNumber):
            BrightLeadingNumberWidgetV5(
                appearance: HealthWidgetDemo.weightAppearance,
                value: HealthWidgetDemo.weightPoints.last?.value ?? 0,
                latest: HealthWidgetDemo.weightPoints.last?.date ?? .now
            )
        case (.heartRate, .vo2Number):
            BrightLeadingNumberWidgetV5(
                appearance: HealthWidgetDemo.vo2MaxAppearance,
                value: HealthWidgetDemo.vo2MaxPoints.last?.value ?? 0,
                latest: HealthWidgetDemo.vo2MaxPoints.last?.date ?? .now
            )
        case (.weight, _):
            BrightDottedLineChartWidgetV5(
                appearance: HealthWidgetDemo.weightAppearance,
                subtitle: HealthWidgetDemo.anchor.formatted(.brightTimestamp),
                points: HealthWidgetDemo.weightPoints,
                trend: .init(systemImage: "arrow.down", text: "0.36kg Weekly AVG"),
                showsTrendLine: true,
                changes: HealthWidgetDemo.weightChanges,
                note: HealthWidgetDemo.weightNote,
                size: widget.size,
                allowsSelection: allowsSelection
            )
        case (.heartRate, .vo2Line):
            BrightDottedLineChartWidgetV5(
                appearance: HealthWidgetDemo.vo2MaxAppearance,
                subtitle: "Latest: \(HealthWidgetDemo.anchor.formatted(.brightTimestamp))",
                points: HealthWidgetDemo.vo2MaxPoints,
                size: widget.size,
                allowsSelection: allowsSelection
            )
        case (.heartRate, _):
            BrightLeadingNumberWidgetV5(
                appearance: heartRateAppearance,
                value: HealthWidgetDemo.heartRate.last?.value ?? 0,
                latest: HealthWidgetDemo.heartRate.last?.date ?? .now
            )
        case (.macros, .macroRings):
            BrightRingGroupWidgetV5(rings: HealthWidgetDemo.macroRings, size: widget.size, allowsSelection: allowsSelection)
        case (.macros, .macroRing):
            BrightRingGroupWidgetV5(rings: [HealthWidgetDemo.macroRing(widget.macro)], size: widget.size, allowsSelection: allowsSelection) {
                ringHeader(widget.macro.title, color: HealthWidgetDemo.macroRing(widget.macro).color)
            }
        case (.intake, .intakeRing):
            BrightRingGroupWidgetV5(rings: [HealthWidgetDemo.intakeRing], size: widget.size, allowsSelection: allowsSelection) {
                ringHeader(widget.kind.title, color: widget.kind.tint)
            }
        case (.sleep, _):
            BrightRingGroupWidgetV5(rings: HealthWidgetDemo.sleepRings, size: widget.size, allowsSelection: allowsSelection) {
                SleepRingsHeader()
            }
        case (.macros, _):
            BrightBarChartWidgetV5(
                appearance: HealthWidgetDemo.macrosAppearance,
                subtitle: HealthWidgetDemo.macrosYesterday,
                range: .week,
                bars: HealthWidgetDemo.macroWeek,
                headline: .split,
                size: widget.size,
                allowsSelection: allowsSelection
            )
        case (.intake, _):
            barChart(HealthWidgetDemo.intake)
        case (.activity, .activeEnergyBars):
            barChart(HealthWidgetDemo.activeEnergy)
        case (.activity, .stepBars):
            barChart(HealthWidgetDemo.steps)
        case (.activity, _):
            barChart(HealthWidgetDemo.totalEnergy)
        }
    }

    // The icon-and-name header the single rings use; intake and macros keep the arrow.
    private func ringHeader(_ title: String, systemImage: String = "arrow.right", color: Color) -> some View {
        HStack(spacing: .spacing05x) {
            Image(systemName: systemImage)
                .font(.standard(size: .subheading, weight: .light))
                .foregroundStyle(color)

            BrightText(title, size: .body1, weight: .regular)
        }
        .lineLimit(1)
    }

    private var heartRateAppearance: BrightWidgetAppearanceV5 {
        BrightWidgetAppearanceV5(title: widget.kind.title, systemImage: widget.kind.systemImage, tint: widget.kind.tint, unit: "BPM")
    }

    // Small and medium weeks lead with the average; large leads with today and lists the week below.
    private func barChart(_ metric: HealthWidgetDemo.BarMetric) -> some View {
        let range = widget.range
        let isLarge = widget.size == .large
        let headline: BrightBarChartWidgetV5.Headline = range.isWeek ? (isLarge ? .current : .average) : .total

        return BrightBarChartWidgetV5(
            appearance: metric.appearance,
            subtitle: metric.subtitle(for: range),
            range: range,
            bars: metric.bars(for: range),
            fill: metric.fill(for: range),
            target: metric.target(for: range),
            headline: headline,
            comparison: headline == .average ? nil : "Yesterday: \(metric.appearance.format(metric.yesterday))",
            summary: isLarge ? metric.summary : nil,
            size: widget.size,
            allowsSelection: allowsSelection
        )
    }
}

struct HealthWidgetGrid: View {
    @Bindable var editor: HealthWidgetEditor

    @State private var containerWidth: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0
    @State private var jigglePhase = false

    private var layout: HealthWidgetLayout {
        editor.layout
    }

    var body: some View {
        let cellSize = HealthWidgetGridMetrics.cellSize(containerWidth: containerWidth)

        ZStack(alignment: .topLeading) {
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
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.bounds(of: .scrollView)?.height ?? 0
        } action: {
            viewportHeight = $0
        }
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

            HealthWidgetView(widget: widget, allowsSelection: !editor.isEditing)
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
                editor.dragChanged(value, widget: widget, cellSize: cellSize, viewportHeight: viewportHeight)
            }
            .onEnded { _ in
                editor.dragEnded(widget: widget, cellSize: cellSize)
            }
    }

    private func removeButton(for widget: HealthWidgetItem) -> some View {
        BrightRoundButton(systemImage: "minus", size: .extraSmall, haptic: nil) {
            editor.remove(widget)
        }
        .offset(x: .spacing05x, y: -.spacing05x)
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
