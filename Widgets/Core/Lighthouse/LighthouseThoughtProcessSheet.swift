//
//  LighthouseThoughtProcessSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 14/9/2026.
//

import SwiftUI

// The reasoning behind a reply, drawn as a tree: each step under the one
// before it, nesting as the work narrows, and ending at the waypoint it set
// out to reach. The steps land one after another, as if being thought again.
struct LighthouseThoughtProcessSheet: View {
    let steps: [LighthouseThoughtStep]

    @State private var revealedCount = 0
    @State private var selectedStep: LighthouseThoughtStep?

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
                                        .transition(.scale(scale: 0, anchor: .top).combined(with: .opacity))
                                }

                                row(step)
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
        .brightMiniSheet(isPresented: Binding(
            get: { selectedStep != nil },
            set: { if !$0 { selectedStep = nil } }
        )) {
            if let selectedStep {
                LighthouseThoughtStepMiniSheet(step: selectedStep) { self.selectedStep = nil }
            }
        }
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

    // MARK: - Rows

    private func row(_ step: LighthouseThoughtStep) -> some View {
        Button {
            selectedStep = step
        } label: {
            HStack(spacing: .spacing2x) {
                if step.isWaypoint {
                    waypointRing
                } else {
                    Image(systemName: step.symbol)
                        .font(.standard(size: .body1, weight: .light))
                        .foregroundStyle(Color.semiLightTextColor)
                        .frame(width: Constants.iconSize, height: Constants.iconSize)
                }

                BrightText(step.title, size: .body2, color: .semiLightTextColor)
                    .lineLimit(1)

                Spacer(minLength: .spacing2x)

                Image(systemName: "chevron.forward")
                    .font(.standard(size: .body2, weight: .light))
                    .foregroundStyle(Color.semiLightTextColor)
            }
            .padding(.leading, indent(for: step.depth))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var waypointRing: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.defaultCyan.opacity(.veryMinimalOpacity),
                    style: StrokeStyle(lineWidth: Constants.ringLineWidth, lineCap: .round)
                )

            Circle()
                .trim(from: 0, to: Constants.ringProgress)
                .stroke(
                    Color.defaultCyan,
                    style: StrokeStyle(lineWidth: Constants.ringLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(Constants.ringStart))

            Image(systemName: "arrow.up")
                .font(.standard(size: .heading, weight: .medium))
                .foregroundStyle(Color.textColor)
        }
        .frame(width: Constants.ringSize, height: Constants.ringSize)
    }

    // MARK: - Connectors

    // A straight drop between siblings; a step that nests curves out of its
    // parent's icon column into its own.
    private func connector(from parent: LighthouseThoughtStep, to child: LighthouseThoughtStep) -> some View {
        let height = child.isWaypoint ? Constants.waypointConnectorHeight : Constants.connectorHeight
        let startX = iconCenter(for: parent)
        let endX = iconCenter(for: child)

        return Path { path in
            path.move(to: CGPoint(x: startX, y: 0))
            if startX == endX {
                path.addLine(to: CGPoint(x: endX, y: height))
            } else {
                let corner = height - Constants.connectorCornerRadius
                path.addLine(to: CGPoint(x: startX, y: corner))
                path.addQuadCurve(
                    to: CGPoint(x: startX + Constants.connectorCornerRadius, y: height),
                    control: CGPoint(x: startX, y: height)
                )
                path.addLine(to: CGPoint(x: endX, y: height))
            }
        }
        .stroke(Color.semiLightTextColor, style: StrokeStyle(lineWidth: 1, lineCap: .round))
        .frame(height: height)
    }

    private func indent(for depth: Int) -> CGFloat {
        CGFloat(depth) * Constants.indent
    }

    private func iconCenter(for step: LighthouseThoughtStep) -> CGFloat {
        let width = step.isWaypoint ? Constants.ringSize : Constants.iconSize
        return indent(for: step.depth) + width / 2
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
            withAnimation(.brightEaseInOut) { revealedCount += 1 }
        }
    }

    private enum Constants {
        static let title = "Thought Process"
        static let iconSize: CGFloat = .spacing4x
        static let indent: CGFloat = .spacing2x
        static let connectorHeight: CGFloat = .spacing3x
        static let waypointConnectorHeight: CGFloat = .spacing6x
        static let connectorCornerRadius: CGFloat = .spacing1x
        static let ringSize: CGFloat = .spacing9x
        static let ringLineWidth: CGFloat = .spacing05x
        static let ringProgress: CGFloat = 0.3
        static let ringStart: Double = -90
        static let revealEvery: TimeInterval = 0.3
    }
}

// One step opened up: its title, and what the model was doing at the time.
struct LighthouseThoughtStepMiniSheet: View {
    let step: LighthouseThoughtStep
    var onClose: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            header

            BrightText(step.detail, size: .body1, color: .semiLightTextColor)
                .lineSpacing(.lineSpacingMedium)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // The close button holds the leading edge; the title sits centred over
    // the whole width, as in the design.
    private var header: some View {
        BrightText(step.title, size: .subheading, weight: .regular)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                BrightRoundButton(systemImage: "xmark", size: .large, onTapCallback: onClose)
            }
    }
}

#Preview {
    LighthouseThoughtProcessSheet(steps: LighthouseDemo.thoughtSteps)
}

#Preview("Step") {
    Color.defaultBackground
        .ignoresSafeArea()
        .brightMiniSheet(isPresented: .constant(true)) {
            LighthouseThoughtStepMiniSheet(step: LighthouseDemo.thoughtSteps[3])
        }
}
