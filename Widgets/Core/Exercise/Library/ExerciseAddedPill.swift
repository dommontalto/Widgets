//
//  ExerciseAddedPill.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

struct ExerciseAddedPill: View {
    @Environment(ExerciseSessionBuilder.self) private var builder

    @State private var isConfirmingReset = false
    @State private var resetTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: .spacing0x) {
            Spacer(minLength: .spacing0x)

            BrightPillButton(
                isConfirmingReset ? "Reset" : "Exercises: \(builder.count)",
                color: isConfirmingReset ? .defaultWarningRed : nil,
                buttonSize: .small
            ) {
                handleTap()
            }
            .contentTransition(.numericText(value: Double(builder.count)))
        }
        .animation(.brightSnappy, value: isConfirmingReset)
        .animation(.brightSnappy, value: builder.count)
    }

    private func handleTap() {
        resetTask?.cancel()

        guard !isConfirmingReset else {
            withAnimation(.brightBouncy) { builder.reset() }
            isConfirmingReset = false
            return
        }

        isConfirmingReset = true
        resetTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            isConfirmingReset = false
        }
    }
}

#Preview {
    ExerciseAddedPill()
        .environment(ExerciseSessionBuilder())
        .padding(.spacing3x)
}
