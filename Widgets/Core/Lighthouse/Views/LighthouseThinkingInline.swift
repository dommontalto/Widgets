//
//  LighthouseThinkingInline.swift
//  Widgets
//
//  Created by Dom Montalto on 25/9/2026.
//

import SwiftUI

// The thought process in the thread: the orb and "Thinking…" with each step
// hanging off it as it arrives, then, once the answer lands, condensed into
// "Thought for…" that opens back out to the steps.
struct LighthouseThinkingInline: View {
    let steps: [LighthouseThoughtStep]
    // Nil while the reply is still being worked out.
    var thoughtSeconds: Int?

    @State private var revealedCount = 0
    @State private var isExpanded = true

    private var isFinished: Bool {
        thoughtSeconds != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            header

            VStack(alignment: .leading, spacing: .spacing0x) {
                if isExpanded {
                    stepList
                        .transition(.move(edge: .top))
                }
            }
            .clipped()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task { await reveal() }
        .onChange(of: isFinished) { _, isFinished in
            guard isFinished else { return }
            revealedCount = steps.count
            withAnimation(.brightSpring) { isExpanded = false }
        }
    }

    private var stepList: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            ForEach(Array(steps.prefix(revealedCount).enumerated()), id: \.element.id) { index, step in
                ThoughtConnector(
                    startX: index == 0 ? headerIconCenter : iconCenter(for: steps[index - 1]),
                    endX: iconCenter(for: step),
                    height: Constants.connectorHeight,
                    cornerRadius: Constants.connectorCornerRadius
                )

                row(step, isLatest: index == revealedCount - 1)
                    .transition(.offset(y: -.spacing1x).combined(with: .opacity))
            }
        }
    }

    private var header: some View {
        Button {
            guard isFinished else { return }
            withAnimation(.brightSpring) { isExpanded.toggle() }
        } label: {
            HStack(spacing: isFinished ? .spacing105x : .spacing2x) {
                ZStack {
                    if isFinished {
                        Image(systemName: "brain")
                            .font(.standard(size: .body1, weight: .light))
                            .foregroundStyle(Color.semiLightTextColor)
                            .transition(.opacity)
                    } else {
                        BrightSolvingStars(state: .thinking, size: Constants.orbSize, ambientMotion: .off)
                            .transition(.brightBurstOut)
                    }
                }
                .frame(
                    width: isFinished ? Constants.brainSize : Constants.orbSize,
                    height: isFinished ? Constants.brainSize : Constants.orbSize
                )

                if let thoughtSeconds {
                    BrightText("Thought for \(thoughtSeconds) seconds", size: .body1, color: .semiLightTextColor)
                        .monospacedDigit()
                        .transition(.opacity)
                } else {
                    thinkingTitle
                        .transition(.opacity)
                }

                Image(systemName: "chevron.forward")
                    .font(.standard(size: .body1, weight: .light))
                    .foregroundStyle(Color.semiLightTextColor)
                    .rotationEffect(.degrees(isExpanded ? Constants.openChevronDegrees : 0))

                Spacer(minLength: .spacing0x)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .brightHaptic(.light, trigger: isExpanded)
    }

    private var thinkingTitle: some View {
        BrightText(Constants.thinkingTitle, size: .body1)
            .phaseAnimator([false, true]) { title, isLit in
                title
                    .opacity(isLit ? .opaque : .semiLowOpacity)
                    .shadow(color: Color.textColor.opacity(isLit ? .semiLowOpacity : 0), radius: Constants.glowRadius)
            } animation: { _ in
                .easeInOut(duration: Constants.glowDuration)
            }
    }

    private func row(_ step: LighthouseThoughtStep, isLatest: Bool) -> some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: step.symbol)
                .font(.standard(size: .body1, weight: .light))
                .foregroundStyle(Color.semiLightTextColor)
                .frame(width: Constants.column, height: Constants.column)
                .symbolEffect(.pulse, isActive: isLatest && !isFinished)
                .transition(.symbolEffect(.drawOn))

            BrightText(step.title, size: .body1, color: .semiLightTextColor)
                .lineLimit(1)

            Spacer(minLength: .spacing0x)
        }
        .padding(.leading, Constants.iconInset + indent(for: step.depth))
    }

    private var headerIconCenter: CGFloat {
        (isFinished ? Constants.brainSize : Constants.orbSize) / 2
    }

    private func indent(for depth: Int) -> CGFloat {
        CGFloat(depth) * Constants.indent
    }

    private func iconCenter(for step: LighthouseThoughtStep) -> CGFloat {
        Constants.iconInset + indent(for: step.depth) + Constants.column / 2
    }

    private func reveal() async {
        guard !isFinished else {
            revealedCount = steps.count
            isExpanded = false
            return
        }
        for _ in steps {
            do {
                try await Task.sleep(for: .seconds(Constants.revealEvery))
            } catch {
                return
            }
            guard !isFinished else { return }
            withAnimation(.brightSpring) { revealedCount += 1 }
        }
    }

    private enum Constants {
        static let thinkingTitle = "Thinking…"
        static let orbSize: CGFloat = .spacing8x
        static let column: CGFloat = .spacing4x
        static let brainSize: CGFloat = column
        // Centres the step icons under the orb.
        static let iconInset: CGFloat = (orbSize - column) / 2
        static let indent: CGFloat = .spacing2x
        static let connectorHeight: CGFloat = .spacing2x
        static let connectorCornerRadius: CGFloat = .spacing1x
        static let openChevronDegrees: Double = 90
        static let glowRadius: CGFloat = .spacing1x
        static let glowDuration: TimeInterval = 0.9
        static let revealEvery: TimeInterval = 1.1
    }
}

// Drawn along its own length as it lands, so it runs down from the step above
// and round into the next one rather than sweeping in from the side.
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
        .stroke(Color.semiLightTextColor.opacity(.semiLowOpacity), style: StrokeStyle(lineWidth: 1, lineCap: .round))
        .frame(height: height)
        .onAppear {
            withAnimation(.brightSpring) { isDrawn = true }
        }
    }
}

#Preview {
    @Previewable @State var thoughtSeconds: Int?

    LighthouseThinkingInline(steps: LighthouseDemo.thoughtSteps, thoughtSeconds: thoughtSeconds)
        .padding(.spacing3x)
        .frame(maxHeight: .infinity, alignment: .top)
        .background { LighthouseChatBackground() }
        .task {
            try? await Task.sleep(for: .seconds(10))
            withAnimation(.brightSnappy) { thoughtSeconds = 10 }
        }
}
