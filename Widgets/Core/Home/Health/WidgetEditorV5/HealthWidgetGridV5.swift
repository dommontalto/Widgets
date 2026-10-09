//
//  HealthWidgetGridV5.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import SwiftUI

struct HealthWidgetViewV5: View {
    let widget: HealthWidgetItemV5
    var allowsSelection = true

    var body: some View {
        switch (widget.kind, widget.style) {
        case (.heartRate, .heartLine):
            BrightLineChartWidgetV5(
                appearance: heartRateAppearance,
                samples: HealthWidgetDemoV5.heartRate,
                events: HealthWidgetDemoV5.heartRateEvents,
                range: widget.range,
                size: widget.size,
                allowsSelection: allowsSelection
            )
        case (.water, .waterNumber):
            BrightLeadingNumberWidgetV5(
                appearance: HealthWidgetDemoV5.water.appearance,
                value: HealthWidgetDemoV5.waterToday,
                latest: HealthWidgetDemoV5.anchor
            )
        case (.water, .waterRing) where widget.size == .small:
            BrightRingGroupWidgetV5(rings: [HealthWidgetDemoV5.waterRing], size: widget.size, allowsSelection: allowsSelection) {
                ringHeader(HealthWidgetDemoV5.water.appearance.title, systemImage: HealthWidgetDemoV5.water.appearance.systemImage, color: widget.kind.tint)
            }
        case (.water, .waterTank):
            BrightWaterWidgetV5(
                appearance: HealthWidgetDemoV5.water.appearance,
                drinks: HealthWidgetDemoV5.waterDrinks,
                goal: HealthWidgetDemoV5.waterGoal,
                yesterday: HealthWidgetDemoV5.water.yesterday,
                week: HealthWidgetDemoV5.water.weekBars.map(\.value),
                size: widget.size,
                allowsSelection: allowsSelection
            )
        case (.water, .waterRing):
            BrightRingGroupWidgetV5(rings: HealthWidgetDemoV5.waterRings, size: widget.size, allowsSelection: allowsSelection) {
                ringHeader(HealthWidgetDemoV5.water.appearance.title, systemImage: HealthWidgetDemoV5.water.appearance.systemImage, color: widget.kind.tint)
            }
        case (.water, _):
            barChart(HealthWidgetDemoV5.water)
        case (.weight, .weightNumber):
            BrightLeadingNumberWidgetV5(
                appearance: HealthWidgetDemoV5.weightAppearance,
                value: HealthWidgetDemoV5.weightPoints.last?.value ?? 0,
                latest: HealthWidgetDemoV5.weightPoints.last?.date ?? .now
            )
        case (.heartRate, .vo2Number):
            BrightLeadingNumberWidgetV5(
                appearance: HealthWidgetDemoV5.vo2MaxAppearance,
                value: HealthWidgetDemoV5.vo2MaxPoints.last?.value ?? 0,
                latest: HealthWidgetDemoV5.vo2MaxPoints.last?.date ?? .now
            )
        case (.weight, _):
            BrightDottedLineChartWidgetV5(
                appearance: HealthWidgetDemoV5.weightAppearance,
                subtitle: HealthWidgetDemoV5.anchor.formatted(.brightTimestamp),
                points: HealthWidgetDemoV5.weightPoints,
                trend: .init(systemImage: "arrow.down", text: "0.36kg Weekly AVG"),
                showsTrendLine: true,
                changes: HealthWidgetDemoV5.weightChanges,
                note: HealthWidgetDemoV5.weightNote,
                size: widget.size,
                allowsSelection: allowsSelection
            )
        case (.heartRate, .vo2Line):
            BrightDottedLineChartWidgetV5(
                appearance: HealthWidgetDemoV5.vo2MaxAppearance,
                subtitle: "Latest: \(HealthWidgetDemoV5.anchor.formatted(.brightTimestamp))",
                points: HealthWidgetDemoV5.vo2MaxPoints,
                size: widget.size,
                allowsSelection: allowsSelection
            )
        case (.menstrual, _):
            BrightMenstrualWidgetV5(
                cycle: HealthWidgetDemoV5.menstrualCycle,
                today: HealthWidgetDemoV5.menstrualToday,
                nextPeriod: HealthWidgetDemoV5.nextPeriod,
                daysUntilPeriod: HealthWidgetDemoV5.daysUntilPeriod,
                details: HealthWidgetDemoV5.menstrualDetails,
                size: widget.size,
                allowsSelection: allowsSelection
            )
        case (.heartRate, _):
            BrightLeadingNumberWidgetV5(
                appearance: heartRateAppearance,
                value: HealthWidgetDemoV5.heartRate.last?.value ?? 0,
                latest: HealthWidgetDemoV5.heartRate.last?.date ?? .now
            )
        case (.macros, .macroRings):
            BrightRingGroupWidgetV5(rings: HealthWidgetDemoV5.macroRings, size: widget.size, allowsSelection: allowsSelection) {
                ringHeader(widget.kind.rowTitle, color: widget.kind.tint)
            }
        case (.macros, .macroRing):
            BrightRingGroupWidgetV5(rings: [HealthWidgetDemoV5.macroRing(widget.macro)], size: widget.size, allowsSelection: allowsSelection) {
                ringHeader(widget.macro.title, color: HealthWidgetDemoV5.macroRing(widget.macro).color)
            }
        case (.intake, .intakeRing):
            BrightRingGroupWidgetV5(rings: [HealthWidgetDemoV5.intakeRing], size: widget.size, allowsSelection: allowsSelection) {
                ringHeader(widget.kind.title, color: widget.kind.tint)
            }
        case (.sleep, .sleepStages):
            BrightSleepWidgetV5(
                segments: HealthWidgetDemoV5.sleepSegments,
                asleepMinutes: HealthWidgetDemoV5.sleepAsleepMinutes,
                inBedMinutes: HealthWidgetDemoV5.sleepInBedMinutes,
                score: HealthWidgetDemoV5.sleepScore,
                restingHeartRate: HealthWidgetDemoV5.sleepRestingHeartRate,
                heartRateVariability: HealthWidgetDemoV5.sleepHeartRateVariability,
                size: widget.size,
                allowsSelection: allowsSelection
            )
        case (.sleep, .sleepVitals):
            BrightDottedRangeChartWidgetV5(
                appearance: HealthWidgetDemoV5.sleepVitalsAppearance,
                measures: HealthWidgetDemoV5.sleepVitals,
                size: widget.size,
                allowsSelection: allowsSelection
            )
        case (.sleep, _):
            BrightRingGroupWidgetV5(rings: HealthWidgetDemoV5.sleepRings, size: widget.size, allowsSelection: allowsSelection) {
                BrightSleepSummaryV5(
                    asleepMinutes: HealthWidgetDemoV5.sleepAsleepMinutes,
                    inBedMinutes: HealthWidgetDemoV5.sleepInBedMinutes,
                    score: HealthWidgetDemoV5.sleepScore
                )
            }
        case (.macros, _):
            BrightBarChartWidgetV5(
                appearance: HealthWidgetDemoV5.macrosAppearance,
                subtitle: HealthWidgetDemoV5.macrosYesterday,
                range: .week,
                bars: HealthWidgetDemoV5.macroWeek,
                headline: .split,
                size: widget.size,
                allowsSelection: allowsSelection
            )
        case (.intake, _):
            barChart(HealthWidgetDemoV5.intake)
        case (.wellbeing, _):
            BrightRingGroupWidgetV5(rings: HealthWidgetDemoV5.wellbeingRings(size: widget.size), size: widget.size, allowsSelection: allowsSelection) {
                ringHeader(widget.kind.title, systemImage: widget.kind.systemImage, color: widget.kind.tint)
            }
        case (.activity, .activeEnergyBars):
            barChart(HealthWidgetDemoV5.activeEnergy)
        case (.activity, .stepBars):
            barChart(HealthWidgetDemoV5.steps)
        case (.activity, _):
            barChart(HealthWidgetDemoV5.totalEnergy)
        }
    }

    // The icon-and-name header the single rings use; intake and macros keep the arrow.
    private func ringHeader(_ title: String, systemImage: String = "arrow.right", color: Color) -> some View {
        HStack(spacing: .spacing05x) {
            Image(systemName: systemImage)
                .font(.standard(size: .subheading, weight: .light))
                .foregroundStyle(color)

            BrightText(title, size: .body1, weight: .regular)
                .contentTransition(.numericText())
        }
        .lineLimit(1)
    }

    private var heartRateAppearance: BrightWidgetAppearanceV5 {
        BrightWidgetAppearanceV5(title: widget.kind.title, systemImage: widget.kind.systemImage, tint: widget.kind.tint, unit: "BPM")
    }

    // Small and medium weeks lead with the average; large leads with today and lists the week below.
    private func barChart(_ metric: HealthWidgetDemoV5.BarMetric) -> some View {
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

struct HealthWidgetGridV5: View {
    @Bindable var editor: HealthWidgetEditorV5
    var onOpen: (HealthWidgetItemV5) -> Void = { _ in }

    @State private var containerWidth: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0
    @State private var jigglePhase = false

    private var layout: HealthWidgetLayoutV5 {
        editor.layout
    }

    var body: some View {
        let cellSize = HealthWidgetGridMetricsV5.cellSize(containerWidth: containerWidth)

        ZStack(alignment: .topLeading) {
            ForEach(Array(layout.widgets.enumerated()), id: \.element.id) { index, widget in
                tile(widget, index: index, cellSize: cellSize)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(
            height: max(layout.height(cellSize: cellSize), cellSize + HealthWidgetGridMetricsV5.spacing * 2),
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
    private func tile(_ widget: HealthWidgetItemV5, index: Int, cellSize: CGFloat) -> some View {
        if let position = layout.positions[widget.id] {
            let drag = editor.dragging?.widgetID == widget.id ? editor.dragging : nil
            let isLifted = drag?.isLifted == true
            let frame = HealthWidgetGridMetricsV5.frame(for: widget.size, cellSize: cellSize)
            let origin = drag?.location ?? HealthWidgetGridMetricsV5.origin(of: position, cellSize: cellSize)

            HealthWidgetViewV5(widget: widget, allowsSelection: !editor.isEditing)
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
                .simultaneousGesture(openGesture(for: widget), isEnabled: !editor.isEditing)
                .gesture(editor.isEditing ? dragGesture(for: widget, cellSize: cellSize) : nil)
        }
    }

    private func openGesture(for widget: HealthWidgetItemV5) -> some Gesture {
        LongPressGesture(minimumDuration: Constants.openMaxPressDuration)
            .exclusively(before: TapGesture())
            .onEnded { value in
                guard case .second = value else { return }
                onOpen(widget)
            }
    }

    private func dragGesture(for widget: HealthWidgetItemV5, cellSize: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: Constants.dragMinimumDistance, coordinateSpace: .global)
            .onChanged { value in
                editor.dragChanged(value, widget: widget, cellSize: cellSize, viewportHeight: viewportHeight)
            }
            .onEnded { _ in
                editor.dragEnded(widget: widget, cellSize: cellSize)
            }
    }

    private func removeButton(for widget: HealthWidgetItemV5) -> some View {
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
        static let openMaxPressDuration: Double = 0.3
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
