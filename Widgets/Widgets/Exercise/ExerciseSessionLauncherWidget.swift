//
//  ExerciseSessionLauncherWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import SwiftUI

enum ExerciseSessionAction: String, Identifiable {
    case startWorkout
    case startCardio
    case viewWorkout
    case viewCardio

    var id: String { rawValue }

    var title: String {
        switch self {
        case .startWorkout: "Start workout"
        case .startCardio: "Start cardio"
        case .viewWorkout: "View workout"
        case .viewCardio: "View cardio"
        }
    }

    var systemImage: String {
        switch self {
        case .startWorkout: "dumbbell"
        case .startCardio: "figure.run"
        case .viewWorkout: "list.bullet"
        case .viewCardio: "chart.xyaxis.line"
        }
    }

    var color: Color? {
        switch self {
        case .startWorkout: .defaultBrightGreen
        case .startCardio: .defaultSkyBlue
        case .viewWorkout, .viewCardio: nil
        }
    }

}

struct ExerciseSessionLauncherWidget: View {
    @State private var action: ExerciseSessionAction?
    @State private var isLoggingCardio = false

    private let rows: [[ExerciseSessionAction]] = [
        [.startWorkout, .startCardio],
        [.viewWorkout, .viewCardio],
    ]

    var body: some View {
        VStack(spacing: .spacing2x) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: .spacing2x) {
                    ForEach(rows[row]) { item in
                        BrightPillButton(
                            item.title,
                            systemImage: item.systemImage,
                            color: item.color,
                            buttonSize: .large
                        ) {
                            if item == .startCardio {
                                isLoggingCardio = true
                            } else {
                                action = item
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
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
            case .viewCardio:
                HeartWorkoutSummarySheet(workout: HeartDemoData.workout)
            case .startWorkout, .startCardio, .viewWorkout:
                BrightPageSheetView(title: item.title) {
                    BrightPlaceholderView(
                        systemImage: item.systemImage,
                        title: item.title,
                        subtitle: "This screen hasn\u{2019}t been designed yet."
                    )
                }
            }
        }
    }
}

#Preview {
    ExerciseSessionLauncherWidget()
        .padding(.spacing3x)
        .background(Color.bG.ignoresSafeArea())
}
