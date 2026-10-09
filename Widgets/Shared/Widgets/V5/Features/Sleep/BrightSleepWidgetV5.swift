//
//  BrightSleepWidgetV5.swift
//  Widgets
//
//  Created by Dom Montalto on 9/10/2026.
//

import Charts
import SwiftUI

// Last night as a strip of its stages from bedtime to waking, under the night's totals
// and score, with resting heart rate and HRV along the bottom. Small keeps just the time in
// bed and the readings. Small and medium only.
//
// Holding picks out the stage under the finger and swaps the bottom row for its name
// and when it ran.
struct BrightSleepWidgetV5: View {
    enum Stage: Hashable {
        case awake
        case rem
        case core
        case deep

        var title: String {
            switch self {
            case .awake: "Awake"
            case .rem: "REM"
            case .core: "Core"
            case .deep: "Deep"
            }
        }

        var color: Color {
            switch self {
            case .awake: .defaultOrange
            case .rem: .defaultCyan
            case .core: .defaultSkyBlue
            case .deep: .defaultDeepBlue
            }
        }
    }

    struct Segment: Identifiable, Hashable {
        let stage: Stage
        let start: Date
        let end: Date

        var id: Date { start }
    }

    // In order, bedtime first.
    let segments: [Segment]
    let asleepMinutes: Int
    let inBedMinutes: Int
    let score: Int
    let restingHeartRate: Int
    let heartRateVariability: Int
    let size: BrightWidgetSizeV5
    var allowsSelection = true

    @State private var selectedSegment: Segment?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            BrightSleepSummaryV5(asleepMinutes: asleepMinutes, inBedMinutes: inBedMinutes, score: score, isCompact: size == .small)

            Spacer(minLength: .spacing2x)

            strip
                .overlay { touchLayer }
                .frame(height: Constants.stripHeight)

            Spacer(minLength: .spacing2x)

            ZStack {
                vitals
                    .opacity(selectedSegment == nil ? .opaque : .zero)

                heldStage
                    .opacity(selectedSegment == nil ? .zero : .opaque)
            }
        }
        .padding(.spacing205x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(BrightCardModifierV5(color: .defaultHomeCards))
        .onChange(of: allowsSelection) { _, allows in
            if !allows {
                selectedSegment = nil
            }
        }
        .animation(.brightEaseInOut, value: selectedSegment)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Sleep, \(asleepMinutes / 60) hours \(asleepMinutes % 60) minutes asleep, score \(score), resting heart rate \(restingHeartRate), HRV \(heartRateVariability)"
        )
    }

    // MARK: - Strip

    // Each stage as a block as wide as it lasted, with a hairline between them.
    private var strip: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            ForEach(segments) { segment in
                let x = xPosition(of: segment.start, width: width)
                let blockWidth = max(xPosition(of: segment.end, width: width) - x - Constants.stageGap, Constants.minimumStageWidth)

                RoundedRectangle(cornerRadius: Constants.stageCornerRadius)
                    .fill(segment.stage.color)
                    .frame(width: blockWidth, height: geometry.size.height)
                    .offset(x: x)
                    .opacity(selectedSegment == nil || selectedSegment == segment ? .opaque : .ultraLowOpacity)
            }
        }
    }

    // MARK: - Bottom row

    private var vitals: some View {
        HStack(spacing: .spacing0x) {
            vital(label: "RHR", systemImage: "heart.fill", value: restingHeartRate, unit: "BPM")

            Spacer(minLength: .spacing1x)

            vital(label: "HRV", systemImage: "waveform.path.ecg.rectangle.fill", value: heartRateVariability, unit: "ms")
        }
    }

    // "RHR ♥ 46 BPM": the name, its icon, then the reading in red. Small drops the name.
    private func vital(label: String, systemImage: String, value: Int, unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
            if size != .small {
                BrightText(label, size: .body2, color: .semiLightTextColor, weight: .regular)
            }

            Image(systemName: systemImage)
                .font(.standard(size: .subheading, weight: .light))
                .foregroundStyle(Color.defaultRed)

            HStack(alignment: .firstTextBaseline, spacing: .spacing025x) {
                BrightText("\(value)", size: .body2, color: .defaultRed, weight: .regular)
                    .monospacedDigit()

                BrightText(unit, size: .body2, color: .lightTextColor)
            }
        }
        .lineLimit(1)
    }

    // The held stage's name and length in its colour, and when it started and ended.
    private var heldStage: some View {
        HStack(spacing: .spacing0x) {
            if let selectedSegment {
                HStack(spacing: .spacing05x) {
                    BrightText(selectedSegment.stage.title, size: .body2, color: selectedSegment.stage.color, weight: .regular)
                        .contentTransition(.numericText())

                    if size != .small {
                        BrightText(duration(of: selectedSegment), size: .body2, color: selectedSegment.stage.color, weight: .regular)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                }

                Spacer(minLength: .spacing1x)

                // Small has no room for the times, so it gives how long the stage lasted.
                BrightText(
                    size == .small ? duration(of: selectedSegment) : Date.brightTimeRange(from: selectedSegment.start, to: selectedSegment.end),
                    size: .body2,
                    color: .semiLightTextColor
                )
                .monospacedDigit()
                .contentTransition(.numericText())
            }
        }
        .lineLimit(1)
    }

    // "53 m", or past an hour "1 h 27 m".
    private func duration(of segment: Segment) -> String {
        let minutes = Int((segment.end.timeIntervalSince(segment.start) / 60).rounded())
        return minutes < 60 ? "\(minutes) m" : "\(minutes / 60) h \(minutes % 60) m"
    }

    // MARK: - Holding

    // An empty chart laid over the strip, so holding it uses the same gesture as the
    // charts and the page still scrolls. Snaps to the stage under the finger.
    @ViewBuilder
    private var touchLayer: some View {
        if allowsSelection, let first = segments.first, let last = segments.last {
            Chart {
                PointMark(x: .value("Time", first.start), y: .value("Floor", 0))
                    .opacity(.zero)
            }
            .chartXScale(domain: first.start ... max(last.end, first.start.addingTimeInterval(1)))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .chartXSelection(value: selection)
        }
    }

    private var selection: Binding<Date?> {
        Binding {
            selectedSegment?.start
        } set: { date in
            let segment = date.flatMap { date in
                segments.last { $0.start <= date } ?? segments.first
            }
            guard segment != selectedSegment else { return }
            selectedSegment = segment
            if segment != nil {
                BrightHaptic.light.play()
            }
        }
    }

    // MARK: - Values

    private func xPosition(of date: Date, width: CGFloat) -> CGFloat {
        guard let first = segments.first, let last = segments.last else { return 0 }
        let span = last.end.timeIntervalSince(first.start)
        guard span > 0 else { return 0 }
        return width * date.timeIntervalSince(first.start) / span
    }

    private enum Constants {
        static let stageCornerRadius: CGFloat = 5
        static let stripHeight: CGFloat = 44
        static let stageGap: CGFloat = 1
        static let minimumStageWidth: CGFloat = 1
    }
}

#Preview {
    let bedtime = Calendar.current.startOfDay(for: .now).addingTimeInterval(-75 * 60)
    let stages: [(BrightSleepWidgetV5.Stage, Double)] = [
        (.awake, 11), (.rem, 26), (.core, 18), (.deep, 60), (.core, 80), (.rem, 27), (.deep, 69), (.core, 46), (.rem, 22), (.awake, 32),
    ]
    let segments = stages.indices.map { index in
        let start = bedtime.addingTimeInterval(stages[..<index].reduce(0) { $0 + $1.1 } * 60)
        return BrightSleepWidgetV5.Segment(stage: stages[index].0, start: start, end: start.addingTimeInterval(stages[index].1 * 60))
    }

    ScrollView {
        VStack(spacing: .spacing205x) {
            BrightSleepWidgetV5(segments: segments, asleepMinutes: 504, inBedMinutes: 525, score: 82, restingHeartRate: 46, heartRateVariability: 76, size: .small)
                .frame(width: 174, height: 174)

            BrightSleepWidgetV5(segments: segments, asleepMinutes: 504, inBedMinutes: 525, score: 82, restingHeartRate: 46, heartRateVariability: 76, size: .medium)
                .frame(width: 363, height: 174)
        }
        .padding(.spacing205x)
    }
    .background(Color.defaultBackground)
}
