//
//  LighthouseThinkingInline.swift
//  Widgets
//
//  Created by Dom Montalto on 25/9/2026.
//

import SwiftUI

struct LighthouseThinkingInline: View {
    let steps: [LighthouseThoughtStep]
    var thoughtSeconds: Int?
    // Steps arrive as they happen, so each shows at once instead of on the demo's beat.
    var isLive = false

    @State private var revealedCount = 0
    @State private var isExpanded = true
    @State private var toggleCount = 0
    @State private var openStepID: LighthouseThoughtStep.ID?
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
        .onChange(of: steps.count) { _, count in
            guard isLive else { return }
            withAnimation(.brightSpring) { revealedCount = count }
        }
        .onChange(of: isFinished) { _, isFinished in
            guard isFinished else { return }
            revealedCount = steps.count
            withAnimation(.brightSpring) { isExpanded = false }
        }
    }

    // While it thinks, one step at a time in the same spot, each new one replacing the last. Finished and opened,
    // every step it took, one under the other.
    private var stepList: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            Group {
                if isFinished {
                    VStack(alignment: .leading, spacing: .spacing1x) {
                        ForEach(steps.prefix(revealedCount)) { step in
                            chip(step, isCurrent: false)
                        }
                    }
                } else if let current = steps.prefix(revealedCount).last {
                    ZStack(alignment: .leading) {
                        chip(current, isCurrent: true)
                            .id(current.id)
                            .transition(.opacity.combined(with: .softBlur))
                    }
                    .animation(.brightSpring, value: current.id)
                }
            }
            .padding(.leading, Constants.iconInset)
            .padding(.trailing, .spacing3x)
            .padding(.vertical, .spacing1x)

            VStack(alignment: .leading, spacing: .spacing0x) {
                if let openStep {
                    detail(openStep)
                        .id(openStep.id)
                        .transition(.softDrop)
                }
            }
            .mask { detailMask }
            .padding(.leading, Constants.iconInset)
        }
    }

    private var openStep: LighthouseThoughtStep? {
        steps.prefix(revealedCount).first { $0.id == openStepID }
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
                        BrightSolvingGalaxyV5(state: .thinking, size: Constants.orbSize, ambientMotion: .off)
                            // Flattened into its own layer first, so a half-height glass sheet tints the finished
                            // image rather than blending into the shader's dark body and washing it out to white.
                            .drawingGroup()
                            .transition(.brightBurstOutV5)
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
        .brightHapticV5(.light, trigger: toggleCount)
        .brightHapticV5(.light, trigger: stepToggleCount)
    }

    private var thinkingTitle: some View {
        BrightText(Constants.thinkingTitle, size: .body1)
            .brightShimmerV5()
    }

    private func chip(_ step: LighthouseThoughtStep, isCurrent: Bool) -> some View {
        let isOpen = openStepID == step.id

        return Button {
            guard step.isExpandable else { return }
            stepToggleCount += 1
            withAnimation(.brightSpring) { openStepID = isOpen ? nil : step.id }
        } label: {
            HStack(spacing: .spacing105x) {
                Image(systemName: step.symbol)
                    .font(.standard(size: .body1, weight: .light))
                    .foregroundStyle(isCurrent || isOpen ? Color.textColor : Color.semiLightTextColor)
                    .frame(width: Constants.column, height: Constants.column)
                    .drawOnTransition()

                WidthCap(Constants.titleMaxWidth) {
                    BrightText(step.title, size: .body1, color: isCurrent || isOpen ? .textColor : .semiLightTextColor)
                        .lineLimit(1)
                        .brightTextRevealV5(isActive: !isFinished)
                }

                if let timing = step.timing {
                    BrightText(timing, size: .body1, color: .lightTextColor)
                        .monospacedDigit()
                        .fixedSize()
                }

                if step.isExpandable {
                    Image(systemName: "chevron.down")
                        .font(.standard(size: .body3, weight: .light))
                        .foregroundStyle(Color.lightTextColor)
                        .rotationEffect(.degrees(isOpen ? Constants.flippedChevronDegrees : 0))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .allowsHitTesting(step.isExpandable)
    }

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
            .background(Color.defaultCards, in: RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func reveal() async {
        if isLive {
            revealedCount = steps.count
            if isFinished { isExpanded = false }
            return
        }
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
        static let iconInset: CGFloat = (orbSize - column) / 2
        static let titleMaxWidth: CGFloat = .spacing7x * 4
        static let openChevronDegrees: Double = 90
        static let flippedChevronDegrees: Double = 180
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

// A scroll view offers its content unlimited width, so a long step title
// would run on forever. This hands the title at most `maxWidth` to truncate in.
private struct WidthCap: Layout {
    let maxWidth: CGFloat

    init(_ maxWidth: CGFloat) {
        self.maxWidth = maxWidth
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        subviews.first?.sizeThatFits(capped(proposal)) ?? .zero
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: capped(proposal))
    }

    private func capped(_ proposal: ProposedViewSize) -> ProposedViewSize {
        ProposedViewSize(width: min(proposal.width ?? maxWidth, maxWidth), height: proposal.height)
    }
}

private extension View {
    @ViewBuilder
    func drawOnTransition() -> some View {
        if #available(iOS 26, *) {
            transition(.symbolEffect(.drawOn))
        } else {
            transition(.opacity)
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
