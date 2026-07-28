//
//  ExerciseSessionLauncherWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import SwiftUI

/// Titled by the screen each one opens, so the prototype doubles as an index of
/// what's been built.
enum ExerciseSessionAction: String, Identifiable, CaseIterable {
    case liveCardio
    case liveWorkout
    case exerciseLibrary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .liveCardio: "ExerciseLiveCardioSheet"
        case .liveWorkout: "ExerciseLiveWorkoutSheet"
        case .exerciseLibrary: "ExerciseLibrarySheet"
        }
    }

    var systemImage: String {
        switch self {
        case .liveCardio, .liveWorkout: "play.fill"
        case .exerciseLibrary: "dumbbell.fill"
        }
    }

    /// Live sessions start something; the library just opens.
    var isLive: Bool {
        self == .liveCardio || self == .liveWorkout
    }
}

struct ExerciseSessionLauncherWidget: View {
    @State private var action: ExerciseSessionAction?
    @State private var isLoggingCardio = false

    var body: some View {
        VStack(spacing: .spacing2x) {
            ForEach(ExerciseSessionAction.allCases) { item in
                button(item)
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity)
        .modifier(CardModifier())
        .fullScreenCover(isPresented: $isLoggingCardio) {
            ExerciseLiveCardioSheet { isLoggingCardio = false }
        }
        .sheet(item: $action) { item in
            switch item {
            case .liveWorkout:
                ExerciseLiveWorkoutSheet()
            case .exerciseLibrary:
                ExerciseLibrarySheet()
            case .liveCardio:
                EmptyView()
            }
        }
    }

    private func button(_ item: ExerciseSessionAction) -> some View {
        Button {
            if item == .liveCardio {
                isLoggingCardio = true
            } else {
                action = item
            }
        } label: {
            HStack(spacing: .spacing2x) {
                Image(systemName: item.systemImage)
                    .font(.standardSFPro(size: .subheading2, weight: .light))
                    .foregroundStyle(Color.textColor)
                    .frame(width: Constants.iconWidth)

                BrightText(item.title, size: .body2, weight: .regular)

                Spacer(minLength: .spacing2x)
            }
            .padding(.horizontal, .spacing2x)
            .frame(height: Constants.buttonHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(CardModifier(color: .sheetModalCards, cornerRadius: .cornerRadius14))
        }
        .buttonStyle(.plain)
    }

    private enum Constants {
        static let iconWidth: CGFloat = 28
        static let buttonHeight: CGFloat = 52
    }
}

#Preview {
    ExerciseSessionLauncherWidget()
        .padding(.spacing3x)
        .background(Color.bG.ignoresSafeArea())
}
