//
//  ExerciseAddedPill.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

struct ExerciseAddedPill: View {
    @Environment(ExerciseBuilder.self) private var builder

    @State private var isShowingClear = false
    @State private var clearTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: .spacing05x) {
            Spacer(minLength: .spacing0x)

            BrightPillButton("Exercises: \(builder.count)", buttonSize: .small) {
                toggleClear()
            }
            .contentTransition(.numericText(value: Double(builder.count)))

            if isShowingClear {
                Button {
                    clearTask?.cancel()
                    isShowingClear = false
                    withAnimation(.brightBouncy) { builder.reset() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.standard(size: .standout3, weight: .light))
                        .foregroundStyle(Color.defaultRed)
                        .frame(width: Constants.clearTouchSize, height: Constants.clearTouchSize)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.brightSnappy, value: isShowingClear)
        .animation(.brightSnappy, value: builder.count)
    }

    private func toggleClear() {
        clearTask?.cancel()

        guard !isShowingClear else {
            isShowingClear = false
            return
        }

        isShowingClear = true
        clearTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            isShowingClear = false
        }
    }

    private enum Constants {
        static let clearTouchSize: CGFloat = 30
    }
}

#Preview {
    ExerciseAddedPill()
        .environment(ExerciseBuilder())
        .padding(.spacing3x)
}
