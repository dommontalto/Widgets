//
//  ExerciseLiveIntervalStrip.swift
//  Widgets
//
//  Created by Dom Montalto on 24/8/2026.
//

import SwiftUI

// The run's plan as one proportional strip: covered legs sit solid, the
// current leg fills as it is run, and the marker over the fill edge names
// the leg above and counts it down below.
struct ExerciseLiveIntervalStrip: View {
    struct Segment: Identifiable {
        let id = UUID()
        let color: Color
        let weight: Double
    }

    let segments: [Segment]
    let currentIndex: Int?
    let progress: Double
    let label: String
    let detail: String

    var body: some View {
        GeometryReader { proxy in
            let widths = widths(fitting: proxy.size.width)
            let marker = markerX(widths: widths)

            ZStack(alignment: .topLeading) {
                bars(widths: widths)
                    .offset(y: Constants.captionHeight + .spacing1x)

                if let marker {
                    BrightText(label, size: .subheading2, weight: .regular)
                        .fixedSize()
                        .position(
                            x: clamp(marker, within: proxy.size.width),
                            y: Constants.captionHeight / 2
                        )

                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: Constants.markerSize))
                        .foregroundStyle(Color.textColor)
                        .position(x: marker, y: Constants.captionHeight + .spacing1x)

                    BrightText(detail, size: .subheading2, weight: .regular)
                        .monospacedDigit()
                        .fixedSize()
                        .position(
                            x: clamp(marker, within: proxy.size.width),
                            y: Constants.captionHeight + Constants.barHeight
                                + .spacing1x * 2 + Constants.captionHeight / 2
                        )
                }
            }
        }
        .frame(height: Constants.height)
    }

    private func bars(widths: [CGFloat]) -> some View {
        HStack(spacing: .spacing1x) {
            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                bar(segment, index: index, width: widths[index])
            }
        }
    }

    private func bar(_ segment: Segment, index: Int, width: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: .cornerRadius14, style: .continuous)
        // With no current leg the plan is spent, so every bar reads as done.
        let isDone = currentIndex.map { index < $0 } ?? true

        return shape
            .fill(segment.color.opacity(isDone ? .opaque : .minimalOpacity))
            .frame(width: width, height: Constants.barHeight)
            .overlay(alignment: .leading) {
                if index == currentIndex {
                    segment.color
                        .frame(width: width * clampedProgress)
                }
            }
            .clipShape(shape)
    }

    private var clampedProgress: CGFloat {
        CGFloat(min(1, max(0, progress)))
    }

    private func widths(fitting total: CGFloat) -> [CGFloat] {
        let totalWeight = segments.reduce(0) { $0 + max($1.weight, 0) }
        guard totalWeight > 0 else { return segments.map { _ in 0 } }

        let available = total - CGFloat(segments.count - 1) * .spacing1x
        return segments.map { available * CGFloat(max($0.weight, 0)) / CGFloat(totalWeight) }
    }

    private func markerX(widths: [CGFloat]) -> CGFloat? {
        guard let currentIndex, widths.indices.contains(currentIndex) else { return nil }

        let covered = widths.prefix(currentIndex).reduce(0, +)
        let gaps = CGFloat(currentIndex) * .spacing1x
        return covered + gaps + widths[currentIndex] * clampedProgress
    }

    // The captions track the marker but stop short of the edges, so a leg
    // ending near either end never clips its own name.
    private func clamp(_ x: CGFloat, within width: CGFloat) -> CGFloat {
        min(max(x, Constants.captionInset), width - Constants.captionInset)
    }

    private enum Constants {
        static let barHeight: CGFloat = 43
        static let captionHeight: CGFloat = 22
        static let markerSize: CGFloat = 10
        static let captionInset: CGFloat = 30
        static var height: CGFloat { captionHeight * 2 + barHeight + .spacing1x * 2 }
    }
}

#Preview {
    ExerciseLiveIntervalStrip(
        segments: [
            .init(color: .defaultYellow, weight: 500),
            .init(color: .defaultSkyBlueCyan, weight: 3000),
            .init(color: .defaultGreen, weight: 500),
            .init(color: .defaultSkyBlueCyan, weight: 1000),
        ],
        currentIndex: 1,
        progress: 0.45,
        label: "RUN",
        detail: "5:42"
    )
    .padding(.spacing4x)
    .frame(maxHeight: .infinity)
    .background(Color.defaultBackground.ignoresSafeArea())
}
