//
//  ExploreAgentCallCard.swift
//  Widgets
//
//  Created by Dom Montalto on 24/9/2026.
//

import SwiftUI

struct ExploreAgentCallCard: View {
    let agent: ExploreAgent
    let query: String
    let isFinished: Bool
    let onFinish: () -> Void

    @State private var stepIndex = 0

    private var shownSteps: Int {
        isFinished ? agent.steps.count : min(stepIndex + 1, agent.steps.count)
    }

    var body: some View {
        card
            .animation(.brightSnappy, value: stepIndex)
            .animation(.brightSnappy, value: isFinished)
            .brightHaptic(.light, trigger: stepIndex)
            .task { await run() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            header

            if !isFinished {
                ExploreAgentAnimation(style: agent.animation, tint: agent.tint)
                    .transition(.opacity.combined(with: .scale(scale: Constants.panelShrink, anchor: .top)))
            }

            steps
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(cornerRadius: .cornerRadius24))
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            ForEach(0 ..< shownSteps, id: \.self) { index in
                stepRow(agent.steps[index], state: state(at: index))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.leading, Constants.stepIndent)
    }

    private func run() async {
        guard !isFinished else { return }
        for index in agent.steps.indices {
            do {
                try await Task.sleep(for: .seconds(Constants.stepDuration))
            } catch {
                return
            }
            stepIndex = index + 1
        }
        onFinish()
    }

    private var title: String {
        isFinished ? "Created \(agent.name)" : "Creating \(agent.name)"
    }

    private var header: some View {
        HStack(spacing: .spacing2x) {
            mark
                .frame(width: BrightButtonSizes.large.rawValue, height: BrightButtonSizes.large.rawValue)
                .background(agent.tint.opacity(.minimalOpacity), in: Circle())

            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(title, size: .body1, weight: .regular)
                    .contentTransition(.opacity)
                    .frame(maxWidth: .infinity, alignment: .leading)

                BrightText("“\(query)”", size: .body1, color: .lightTextColor)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var mark: some View {
        switch agent.mark {
        case let .asset(name):
            Image(name)
                .resizable()
                .scaledToFit()
                .padding(.spacing105x)
                .foregroundStyle(agent.tint)
        case let .symbol(name):
            Image(systemName: name)
                .font(.standardSFPro(size: .subheading2, weight: .regular))
                .foregroundStyle(agent.tint)
        }
    }

    private func state(at index: Int) -> StepState {
        if isFinished || index < stepIndex { return .done }
        return .active
    }

    private func stepRow(_ step: String, state: StepState) -> some View {
        HStack(spacing: .spacing105x) {
            Group {
                switch state {
                case .done:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(agent.tint)
                case .active:
                    Image(systemName: "circle.dotted")
                        .foregroundStyle(Color.semiLightTextColor)
                        .symbolEffect(.rotate, options: .repeat(.continuous))
                }
            }
            .font(.standardSFPro(size: .body1, weight: .regular))
            .contentTransition(.symbolEffect(.replace))

            BrightText(step, size: .body1, color: state == .done ? .lightTextColor : .semiLightTextColor)
        }
    }

    private enum StepState {
        case done
        case active
    }

    private enum Constants {
        static let stepDuration: TimeInterval = 2.4
        static let stepIndent: CGFloat = .spacing1x
        static let panelShrink: CGFloat = 0.9
    }
}
