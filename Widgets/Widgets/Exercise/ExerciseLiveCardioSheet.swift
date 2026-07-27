//
//  ExerciseLiveCardioSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import SwiftUI

struct ExerciseLiveCardioSheet: View {
    var session: ExerciseLiveSession = ExerciseDemoData.liveSession
    var onStop: () -> Void = {}

    @State private var stripWidth: CGFloat = 0

    var body: some View {
        VStack(spacing: .spacing0x) {
            badge

            metric(label: "DISTANCE", value: session.distance, color: .defaultYellow)

            hairline

            metric(label: "TIME ELAPSED", value: session.timeElapsed, color: .textColor)

            hairline

            paceRow

            hairline

            intervalSection

            Spacer(minLength: .spacing4x)

            stopButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.bG.ignoresSafeArea())
        .presentationBackground(Color.bG)
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Header

    private var badge: some View {
        Image(systemName: session.icon)
            .font(.standard(size: .standout1, weight: .light))
            .foregroundStyle(Color.textColor)
            .frame(width: Constants.badgeSize, height: Constants.badgeSize)
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadius14, style: .continuous)
                    .strokeBorder(
                        Color.textColor.opacity(.veryLowOpacity),
                        lineWidth: Constants.hairline
                    )
            }
            .padding(.top, .spacing8x)
            .padding(.bottom, .spacing1x)
    }

    // MARK: - Stat blocks

    private func metric(label: String, value: String, color: Color) -> some View {
        VStack(spacing: .spacing05x) {
            BrightText(label, size: .body1, color: color.opacity(.mediumOpacity))
            BrightText(value, size: .enormous, color: color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacing3x)
    }

    private var paceRow: some View {
        HStack(spacing: .spacing0x) {
            paceColumn("AVG PACE", value: session.averagePace, color: .defaultSkyBlue)

            Rectangle()
                .fill(Color.textColor.opacity(.minimalOpacity))
                .frame(width: Constants.hairline)

            paceColumn("SPLIT PACE", value: session.splitPace, color: .defaultGreen)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func paceColumn(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: .spacing05x) {
            BrightText(label, size: .body1, color: .semiLightTextColor)
            BrightText(value, size: .giant, color: color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacing4x)
    }

    private var hairline: some View {
        Rectangle()
            .fill(Color.textColor.opacity(.minimalOpacity))
            .frame(height: Constants.hairline)
    }

    // MARK: - Interval section

    private var intervalSection: some View {
        VStack(spacing: .spacing0x) {
            HStack(spacing: .spacing0x) {
                BrightText(
                    "SECTION \(session.sectionNumber)",
                    size: .body1,
                    color: .semiLightTextColor
                )

                Spacer(minLength: .spacing2x)

                BrightText(
                    "REMAINING",
                    size: .body1,
                    color: .semiLightTextColor
                )
            }
            .padding(.horizontal, .spacing9x)

            BrightText(session.sectionRemaining, size: .giant, color: .defaultOrange)
                .monospacedDigit()
                .padding(.top, .spacing4x)

            intervalStrip
                .padding(.horizontal, .spacing4x)
                .padding(.top, .spacing2x)
        }
        .padding(.top, .spacing4x)
    }

    private var intervalStrip: some View {
        VStack(spacing: .spacing0x) {
            centered(at: markerX) {
                Image(systemName: "triangle.fill")
                    .font(.standard(size: .body1, weight: .medium))
                    .foregroundStyle(Color.textColor)
                    .rotationEffect(.degrees(180))
            }
            .frame(height: Constants.markerHeight)

            segmentBar

            centered(at: markerX) {
                BrightText(
                    session.currentIntervalName,
                    size: .subheading,
                    color: session.currentIntervalColor
                )
            }
            .padding(.top, .spacing105x)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { stripWidth = $0 }
    }

    private var segmentBar: some View {
        HStack(spacing: Constants.segmentGap) {
            ForEach(session.segments) { segment in
                RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous)
                    .fill(segment.kind.color.opacity(.veryLowOpacity))
                    .frame(width: width(of: segment))
            }
        }
        .frame(height: Constants.barHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            centered(at: markerX) {
                RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous)
                    .fill(session.currentIntervalColor)
                    .frame(width: Constants.progressMarkerWidth, height: Constants.progressMarkerHeight)
            }
        }
    }

    private var markerX: CGFloat { stripWidth * session.progress }

    private func width(of segment: ExerciseIntervalSegment) -> CGFloat {
        let gaps = Constants.segmentGap * CGFloat(max(session.segments.count - 1, 0))
        let available = max(stripWidth - gaps, 0)
        let totalWeight = session.segments.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return 0 }
        return available * segment.weight / totalWeight
    }

    /// Pins `content` so its horizontal centre lands on `x`, measured from the leading edge.
    /// The zero-width frame lets the content overflow evenly on both sides.
    private func centered<Content: View>(at x: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: .spacing0x) {
            content()
                .fixedSize()
                .frame(width: 0)
                .offset(x: x)

            Spacer(minLength: .spacing0x)
        }
    }

    // MARK: - Stop

    private var stopButton: some View {
        Button(action: onStop) {
            HStack(spacing: .spacing1x) {
                Image(systemName: "stop.fill")
                    .font(.standard(size: .heading, weight: .regular))
                    .foregroundStyle(Color.defaultWarningRed)

                BrightText("STOP", size: .standout4, color: .defaultWarningRed)
            }
            .padding(.horizontal, .spacing2x)
            .frame(height: .spacing8x)
            .background(Color.defaultWarningRed.opacity(.veryLowOpacity), in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.bottom, .spacing4x)
    }

    private enum Constants {
        static let badgeSize: CGFloat = 50
        static let hairline: CGFloat = 1
        static let markerHeight: CGFloat = 20
        static let barHeight: CGFloat = 35
        static let segmentGap: CGFloat = 3
        static let progressMarkerWidth: CGFloat = 3
        static let progressMarkerHeight: CGFloat = 23
    }
}

#Preview {
    Color.bG
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ExerciseLiveCardioSheet()
        }
}
