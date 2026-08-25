//
//  ExerciseCompleteHeartRateDropWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import Charts
import SwiftUI

struct ExerciseCompleteHeartRateDropWidget: View {
    let data: ExercisePostHeartGraphPayload

    @State private var selectedBar: String?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            BrightText(title, size: .body1)
                .contentTransition(.opacity)
                .animation(.brightEaseInOut, value: title)

            HStack(spacing: .spacing1x) {
                Image(ImageNames.heartRedDownV5)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 21, height: 21)

                HStack(alignment: .lastTextBaseline, spacing: .spacing05x) {
                    BrightText(
                        readingValue,
                        size: .huge,
                        color: .textColor
                    )
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.brightEaseInOut, value: readingValue)

                    BrightText(
                        "BPM",
                        size: .body1,
                        color: .textColor.opacity(.lowOpacity)
                    )
                }
            }
            .padding(.top, .spacing3x)

            ZStack(alignment: .top) {
                chartBorderLayout
                    .frame(height: Constants.graphLayoutHeight)
                    .padding(.trailing, Constants.yAxisWidth + .spacing105x)

                HStack(spacing: .spacing105x) {
                    chart
                        .frame(height: Constants.graphHeight)

                    VStack(alignment: .leading) {
                        BrightText(
                            String(data.yTicks?.last ?? 100),
                            size: .body1,
                            color: .semiLightTextColor
                        )
                        Spacer()
                        BrightText(
                            String(data.yTicks?.first ?? 70),
                            size: .body1,
                            color: .semiLightTextColor
                        )
                    }
                    .frame(width: Constants.yAxisWidth, height: Constants.graphHeight, alignment: .leading)
                }
            }
            .padding(.top, .spacing1x)

            if (data.xDatesDisplay ?? []).count >= 3 {
                HStack(spacing: .spacing0x) {
                    BrightText(
                        (data.xDates?.first ?? "").isoStringToDate().formatted(.brightTime),
                        size: .body1,
                        color: .lightTextColor
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, .spacing05x)
                    BrightText(
                        data.xDatesDisplay![1],
                        size: .body1,
                        color: .lightTextColor
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, .spacing05x)
                    BrightText(
                        data.xDatesDisplay![2],
                        size: .body1,
                        color: .lightTextColor
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, .spacing05x)
                }
                // Same inset the chart takes for the y-axis, so these columns
                // divide the same width as the BPM readings above them.
                .padding(.trailing, Constants.yAxisWidth + .spacing105x)
            }
        }

        .padding(.spacing3x)
        .modifier(CardModifier(
            color: .defaultSheetModalCards
        ))
    }

    var chart: some View {
        let start = Double(data.yTicks?.first ?? 30)

        let end = Double(data.yTicks?.last ?? 30)

        return Chart {
            ForEach((data.data ?? []).indices, id: \.self) { index in
                let heartData = data.data![index]

                BarMark(
                    x: .value("State", "\(index)"),
                    yStart: .value("Heart Rate", heartData.min ?? 0),
                    yEnd: .value("Heart Rate", heartData.max ?? 0),
                    width: MarkDimension(floatLiteral: Constants.barMarkWidth)
                )
                .foregroundStyle(Color.defaultRed.opacity(barOpacity(at: index)))
                .cornerRadius(.cornerRadius8)
            }
        }
        .chartYScale(domain: start ... end)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartXSelection(value: selectionBinding)
        .animation(.brightEaseInOut, value: selectedIndex)
        .chartOverlay { _ in
            GeometryReader { geometry in
                Path { path in
                    let midY = geometry.size.height / 2
                    path.move(to: CGPoint(x: 0, y: midY))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: midY))
                }
                .stroke(
                    Color.textColor.opacity(.veryLowOpacity),
                    style: StrokeStyle(lineWidth: 0.5, dash: [6, 4])
                )
            }
        }
    }

    private var title: String {
        selectedBpm == nil ? "Post-Session Heart Rate Drop" : "Post-Session Heart Rate"
    }

    private var readingValue: String {
        if let selectedBpm { return String(selectedBpm) }
        return String(data.bpmDrop ?? 0)
    }

    private var selectedIndex: Int? {
        guard let selectedBar,
              let index = Int(selectedBar),
              (data.data ?? []).indices.contains(index)
        else { return nil }

        return index
    }

    // The rate at the bar being held. With nothing held the widget reads the
    // session's total drop instead.
    private var selectedBpm: Int? {
        guard let selectedIndex else { return nil }

        return bpm(at: selectedIndex)
    }

    private func bpm(at index: Int) -> Int? {
        guard let sample = (data.data ?? [])[safe: index] else { return nil }

        if let avg = sample.avg, avg != 0 { return Int(avg.rounded()) }
        if let min = sample.min, let max = sample.max { return Int(((min + max) / 2).rounded()) }
        return nil
    }

    private func barOpacity(at index: Int) -> CGFloat {
        guard let selectedIndex else { return 1 }
        return index == selectedIndex ? 1 : Double.veryLowOpacity
    }

    private var selectionBinding: Binding<String?> {
        Binding(
            get: { selectedBar },
            set: { newValue in
                if let newValue, newValue != selectedBar {
                    BrightHaptic.light.play()
                }
                selectedBar = newValue
            }
        )
    }

    var chartBorderLayout: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                gradient: Gradient(colors: [Color.defaultRed.opacity(0.10), .clear]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: Constants.chartGradientHeight)

            if (data.data ?? []).count >= 15 {
                BrightDivider(color: Color.defaultRed)
                HStack(alignment: .top) {
                    BrightVerticalDivider(height: Constants.graphLayoutHeight)
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(height: Constants.graphLayoutHeight)
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(height: Constants.graphLayoutHeight)
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(
                        color: Color.defaultRed,
                        height: Constants.graphHeight
                    )
                    Spacer()
                    BrightVerticalDivider(height: Constants.graphLayoutHeight)
                }
            }

            if (data.xDatesDisplay ?? []).count >= 3 {
                VStack {
                    Spacer()
                    HStack(spacing: .spacing0x) {
                        XAxisText(value: data.xBpm![0])
                        XAxisText(value: data.xBpm![1])
                        XAxisText(value: data.xBpm![2])
                    }
                }
            }
        }
    }

    struct XAxisText: View {
        let value: Int?
        var body: some View {
            if let value, value != 0 {
                BrightText(
                    String(value) + " BPM",
                    size: .body1,
                    color: .defaultRed
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, .spacing05x)
            } else {
                BrightText(
                    "- BPM",
                    size: .body1,
                    color: .defaultRed
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, .spacing05x)
            }
        }
    }

    private class Constants {
        static let yAxisWidth: CGFloat = 25
        static let graphHeight: CGFloat = 86
        static let graphLayoutHeight: CGFloat = 101
        static let barMarkWidth: CGFloat = 4
        static let chartGradientHeight: CGFloat = 57
    }
}

#Preview {
    ExerciseCompleteHeartRateDropWidget(
        data: ExercisePostHeartGraphPayload()
    )
}
