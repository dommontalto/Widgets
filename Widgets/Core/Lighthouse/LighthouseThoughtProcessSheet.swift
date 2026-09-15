//
//  LighthouseThoughtProcessSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 14/9/2026.
//

import SwiftUI

// The reasoning behind a reply, drawn as a tree: each step under the one
// before it, nesting as the work narrows, and ending at the waypoint it set
// out to reach. The steps land one after another, as if being thought again,
// and each one opens in place to show what the model was doing.
struct LighthouseThoughtProcessSheet: View {
    let steps: [LighthouseThoughtStep]

    @State private var revealedCount = 0
    @State private var expandedStepIDs: Set<LighthouseThoughtStep.ID> = []
    @State private var waypointProgress: CGFloat = 0

    var body: some View {
        BrightPageSheetView(
            trailing: {
                ToolbarItem(placement: .principal) {
                    title
                }
            },
            content: {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: .spacing0x) {
                        ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                            if index < revealedCount {
                                if index > 0 {
                                    connector(from: steps[index - 1], to: step)
                                }

                                row(step, isLatest: index == revealedCount - 1)
                                    .transition(.offset(y: -.spacing1x).combined(with: .opacity))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, .spacing3x)
                    .padding(.bottom, .spacing12x)
                }
            }
        )
        .task { await reveal() }
    }

    private var title: some View {
        HStack(spacing: .spacing105x) {
            Image(systemName: "brain")
                .font(.standard(size: .body1, weight: .regular))
                .foregroundStyle(Color.textColor)

            BrightText(Constants.title, size: .body1, weight: .regular)
        }
    }

    private var isRevealing: Bool {
        revealedCount < steps.count
    }

    // MARK: - Rows

    private func row(_ step: LighthouseThoughtStep, isLatest: Bool) -> some View {
        let isExpanded = expandedStepIDs.contains(step.id)

        return VStack(alignment: .leading, spacing: .spacing0x) {
            Button {
                withAnimation(.brightSpring) {
                    if isExpanded {
                        expandedStepIDs.remove(step.id)
                    } else {
                        expandedStepIDs.insert(step.id)
                    }
                }
            } label: {
                HStack(spacing: .spacing2x) {
                    if step.isWaypoint {
                        waypointRing
                    } else {
                        Image(systemName: step.symbol)
                            .font(.standard(size: .heading, weight: .light))
                            .foregroundStyle(Color.semiLightTextColor)
                            .frame(width: Constants.iconSize, height: Constants.iconSize)
                            .symbolEffect(.pulse, isActive: isLatest && isRevealing)
                            .symbolEffect(.bounce, value: isExpanded)
                            .transition(.symbolEffect(.drawOn))
                    }

                    BrightText(step.title, size: .body2, color: .semiLightTextColor)
                        .lineLimit(1)

                    Spacer(minLength: .spacing2x)

                    Image(systemName: "chevron.forward")
                        .font(.standard(size: .body2, weight: .light))
                        .foregroundStyle(Color.semiLightTextColor)
                        .rotationEffect(.degrees(isExpanded ? Constants.openChevronDegrees : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(spacing: .spacing0x) {
                if isExpanded {
                    detail(step)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .clipped()
        }
        .padding(.leading, indent(for: step.depth))
    }

    // The detail sits beside the icon column, and the tree line keeps running
    // down that column so the next step still hangs off this one.
    private func detail(_ step: LighthouseThoughtStep) -> some View {
        HStack(alignment: .top, spacing: .spacing2x) {
            Rectangle()
                .fill(step.isWaypoint ? Color.clear : Color.semiLightTextColor)
                .frame(width: 1)
                .frame(width: iconWidth(for: step))

            BrightText(step.detail, size: .body4, color: .lightTextColor)
                .lineSpacing(.lineSpacingMedium)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, .spacing105x)
                .padding(.trailing, .spacing3x)
        }
    }

    private var waypointRing: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.defaultCyan.opacity(.veryMinimalOpacity),
                    style: StrokeStyle(lineWidth: Constants.ringLineWidth, lineCap: .round)
                )

            Circle()
                .trim(from: 0, to: waypointProgress)
                .stroke(
                    Color.defaultCyan,
                    style: StrokeStyle(lineWidth: Constants.ringLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(Constants.ringStart))

            Image(systemName: "arrow.up")
                .font(.standard(size: .standout3, weight: .medium))
                .foregroundStyle(Color.textColor)
                .transition(.symbolEffect(.drawOn))
        }
        .padding(Constants.ringLineWidth / 2)
        .frame(width: Constants.ringSize, height: Constants.ringSize)
        .onAppear {
            withAnimation(.brightChartReveal) { waypointProgress = 1 }
        }
    }

    // MARK: - Connectors

    // A straight drop between siblings; a step that nests curves out of its
    // parent's icon column into its own.
    private func connector(from parent: LighthouseThoughtStep, to child: LighthouseThoughtStep) -> some View {
        ThoughtConnector(
            startX: iconCenter(for: parent),
            endX: iconCenter(for: child),
            height: child.isWaypoint ? Constants.waypointConnectorHeight : Constants.connectorHeight,
            cornerRadius: Constants.connectorCornerRadius
        )
    }

    private func indent(for depth: Int) -> CGFloat {
        CGFloat(depth) * Constants.indent
    }

    private func iconWidth(for step: LighthouseThoughtStep) -> CGFloat {
        step.isWaypoint ? Constants.ringSize : Constants.iconSize
    }

    private func iconCenter(for step: LighthouseThoughtStep) -> CGFloat {
        indent(for: step.depth) + iconWidth(for: step) / 2
    }

    // MARK: - Reveal

    private func reveal() async {
        revealedCount = 0
        for _ in steps {
            do {
                try await Task.sleep(for: .seconds(Constants.revealEvery))
            } catch {
                return
            }
            withAnimation(.brightSpring) { revealedCount += 1 }
        }
    }

    private enum Constants {
        static let title = "Thought Process"
        static let iconSize: CGFloat = .spacing5x
        static let indent: CGFloat = .spacing2x
        static let connectorHeight: CGFloat = .spacing4x
        static let waypointConnectorHeight: CGFloat = .spacing7x
        static let connectorCornerRadius: CGFloat = .spacing1x
        static let ringSize: CGFloat = .spacing9x
        static let ringLineWidth: CGFloat = .spacing05x
        static let ringStart: Double = -90
        static let openChevronDegrees: Double = 90
        static let revealEvery: TimeInterval = 0.9
    }
}

// The line is drawn along its own length as it lands, so it runs down from
// the step above and round into the next one rather than sweeping in from
// the side.
private struct ThoughtConnector: View {
    let startX: CGFloat
    let endX: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    @State private var isDrawn = false

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: startX, y: 0))
            if startX == endX {
                path.addLine(to: CGPoint(x: endX, y: height))
            } else {
                path.addLine(to: CGPoint(x: startX, y: height - cornerRadius))
                path.addQuadCurve(
                    to: CGPoint(x: startX + cornerRadius, y: height),
                    control: CGPoint(x: startX, y: height)
                )
                path.addLine(to: CGPoint(x: endX, y: height))
            }
        }
        .trim(from: 0, to: isDrawn ? 1 : 0)
        .stroke(Color.semiLightTextColor, style: StrokeStyle(lineWidth: 1, lineCap: .round))
        .frame(height: height)
        .onAppear {
            withAnimation(.brightSpring) { isDrawn = true }
        }
    }
}

#Preview {
    LighthouseThoughtProcessSheet(steps: LighthouseDemo.thoughtSteps)
}
