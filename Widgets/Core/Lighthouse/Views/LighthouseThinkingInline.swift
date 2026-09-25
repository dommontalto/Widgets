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
    @State private var toggleCount = 0
    @State private var openStepIDs: Set<LighthouseThoughtStep.ID> = []
    @State private var stepToggleCount = 0

    @Environment(\.openURL) private var openURL

    private var isFinished: Bool {
        thoughtSeconds != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            header

            VStack(alignment: .leading, spacing: .spacing0x) {
                if isExpanded {
                    stepList
                        .transition(.softDrop)
                }
            }
            .mask {
                Rectangle()
                    .padding(isFinished ? .spacing0x : -Constants.landingOverscan)
            }
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
                let startX = index == 0 ? headerIconCenter : iconCenter(for: steps[index - 1])
                let endX = iconCenter(for: step)
                let height = startX == endX ? Constants.connectorHeight : Constants.bentConnectorHeight
                if index == 0, !isFinished {
                    Color.clear.frame(height: height)
                } else {
                    ThoughtConnector(
                        startX: startX,
                        endX: endX,
                        height: height,
                        cornerRadius: Constants.connectorCornerRadius,
                        drawsIn: !isFinished
                    )
                }

                row(step)
                    .transition(.offset(y: -.spacing1x).combined(with: .opacity).combined(with: .softBlur))
            }
        }
    }

    private var header: some View {
        Button {
            guard isFinished else { return }
            toggleCount += 1
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
        .brightHaptic(.light, trigger: toggleCount)
        .brightHaptic(.light, trigger: stepToggleCount)
    }

    private var thinkingTitle: some View {
        BrightText(Constants.thinkingTitle, size: .body1)
            .brightShimmer()
    }

    private func row(_ step: LighthouseThoughtStep) -> some View {
        let isOpen = openStepIDs.contains(step.id)

        return VStack(alignment: .leading, spacing: .spacing0x) {
            Button {
                guard step.isExpandable else { return }
                stepToggleCount += 1
                withAnimation(.brightSpring) {
                    if isOpen {
                        openStepIDs.remove(step.id)
                    } else {
                        openStepIDs.insert(step.id)
                    }
                }
            } label: {
                HStack(spacing: .spacing2x) {
                    Image(systemName: step.symbol)
                        .font(.standard(size: .body1, weight: .light))
                        .foregroundStyle(Color.semiLightTextColor)
                        .frame(width: Constants.column, height: Constants.column)
                        .transition(.symbolEffect(.drawOn))

                    BrightText(step.title, size: .body1, color: .semiLightTextColor)
                        .lineLimit(1)
                        .brightTextReveal(isActive: !isFinished)

                    if step.isExpandable {
                        Image(systemName: "chevron.forward")
                            .font(.standard(size: .body1, weight: .light))
                            .foregroundStyle(Color.lightTextColor)
                            .rotationEffect(.degrees(isOpen ? Constants.openChevronDegrees : 0))
                    }

                    Spacer(minLength: .spacing0x)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .allowsHitTesting(step.isExpandable)

            VStack(alignment: .leading, spacing: .spacing0x) {
                if isOpen {
                    detail(step)
                        .transition(.softDrop)
                }
            }
            .mask { detailMask }
        }
        .padding(.leading, Constants.iconInset + indent(for: step.depth))
    }

    // The tree line keeps running down the icon column beside the detail, so
    // the next step still hangs off this one.
    private func detail(_ step: LighthouseThoughtStep) -> some View {
        HStack(alignment: .top, spacing: .spacing2x) {
            Rectangle()
                .fill(Color.semiLightTextColor.opacity(.semiLowOpacity))
                .frame(width: 1)
                .frame(width: Constants.column)

            VStack(alignment: .leading, spacing: .spacing2x) {
                BrightText(step.detail, size: .body1, color: .lightTextColor)
                    .lineSpacing(.lineSpacingMedium)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(step.references) { reference in
                    referenceRow(reference)
                }
            }
            .padding(.vertical, .spacing105x)
        }
    }

    private var detailMask: some View {
        HStack(spacing: .spacing0x) {
            Rectangle()
                .frame(width: Constants.column + .spacing2x)

            VStack(spacing: .spacing0x) {
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                    .frame(height: Constants.featherHeight)

                Rectangle()

                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: Constants.featherHeight)
            }
            .padding(.trailing, -Constants.landingOverscan)
        }
    }

    private func referenceRow(_ reference: LighthouseThoughtReference) -> some View {
        Button {
            openURL(reference.url)
        } label: {
            HStack(alignment: .top, spacing: .spacing105x) {
                Image(systemName: "doc.text")
                    .font(.standard(size: .body1, weight: .light))
                    .foregroundStyle(Color.semiLightTextColor)

                VStack(alignment: .leading, spacing: .spacing025x) {
                    BrightText(reference.title, size: .body1, color: .semiLightTextColor)
                        .lineLimit(2)

                    BrightText(reference.source, size: .body1, color: .lightTextColor)
                        .lineLimit(1)
                }

                Spacer(minLength: .spacing0x)

                Image(systemName: "arrow.up.right")
                    .font(.standard(size: .body1, weight: .light))
                    .foregroundStyle(Color.lightTextColor)
            }
            .padding(.spacing2x)
            .background(Color.defaultCards, in: RoundedRectangle(cornerRadius: .cornerRadius18, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        static let orbSize: CGFloat = .spacing7x
        static let column: CGFloat = .spacing4x
        static let brainSize: CGFloat = column
        // Centres the step icons under the orb.
        static let iconInset: CGFloat = (orbSize - column) / 2
        static let indent: CGFloat = .spacing2x
        static let connectorHeight: CGFloat = .spacing2x
        static let bentConnectorHeight: CGFloat = .spacing3x
        static let connectorCornerRadius: CGFloat = .spacing1x
        static let openChevronDegrees: Double = 90
        static let revealEvery: TimeInterval = 1.1
        static let featherHeight: CGFloat = .spacing105x
        static let landingOverscan: CGFloat = .spacing6x
    }
}

private struct SoftBlur: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        content.blur(radius: radius)
    }
}

private extension AnyTransition {
    static let softBlur = AnyTransition.modifier(active: SoftBlur(radius: .spacing05x), identity: SoftBlur(radius: .spacing0x))
    static let softDrop = AnyTransition.move(edge: .top).combined(with: .opacity).combined(with: .softBlur)
}

// Drawn along its own length as it lands: down from the step above, and when
// the next one nests, round and across, then down again into its icon.
private struct ThoughtConnector: View {
    let startX: CGFloat
    let endX: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    var drawsIn = true

    @State private var isDrawn = false

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: startX, y: 0))
            if startX == endX {
                path.addLine(to: CGPoint(x: endX, y: height))
            } else {
                let middle = height / 2
                path.addLine(to: CGPoint(x: startX, y: middle - cornerRadius))
                path.addQuadCurve(
                    to: CGPoint(x: startX + cornerRadius, y: middle),
                    control: CGPoint(x: startX, y: middle)
                )
                path.addLine(to: CGPoint(x: endX - cornerRadius, y: middle))
                path.addQuadCurve(
                    to: CGPoint(x: endX, y: middle + cornerRadius),
                    control: CGPoint(x: endX, y: middle)
                )
                path.addLine(to: CGPoint(x: endX, y: height))
            }
        }
        .trim(from: 0, to: isDrawn ? 1 : 0)
        .stroke(Color.semiLightTextColor.opacity(.semiLowOpacity), style: StrokeStyle(lineWidth: 1, lineCap: .round))
        .frame(height: height)
        .onAppear {
            guard drawsIn else {
                isDrawn = true
                return
            }
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
