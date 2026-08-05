//
//  ExerciseUpcomingWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 21/7/2026.
//

import SwiftUI

struct ExerciseUpcomingWidget: View {
    var sessions: [ExerciseUpcomingSession] = []
    var onQuickWorkout: (ExerciseQuickSession) -> Void = { _ in }

    @Environment(ExerciseSessionBuilder.self) private var builder

    @State private var selectedIndex: Int?

    var body: some View {
        Group {
            if sessions.isEmpty {
                emptyState
            } else {
                todayState
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
        .brightMiniSheet(isPresented: sheetBinding) {
            if let selectedIndex {
                ExerciseSessionMiniSheet(session: sessions[selectedIndex]) {
                    withAnimation(.brightEaseInOut) { self.selectedIndex = nil }
                }
            }
        }
    }

    private var sheetBinding: Binding<Bool> {
        Binding(
            get: { selectedIndex != nil },
            set: { if !$0 { withAnimation(.brightEaseInOut) { selectedIndex = nil } } }
        )
    }

    private var todayState: some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            BrightText("Today", size: .body1)

            VStack(spacing: .spacing1x) {
                ForEach(sessions.indices, id: \.self) { i in
                    sessionRow(sessions[i], isSelected: selectedIndex == i) {
                        withAnimation(.brightEaseInOut) { selectedIndex = i }
                    }
                }
            }
        }
        .padding(.spacing3x)
    }

    private func sessionRow(_ session: ExerciseUpcomingSession, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        let color = color(for: session.type)
        return Button(action: onTap) {
            HStack(spacing: .spacing105x) {
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(color)
                    .frame(width: 2, height: 35)

                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(session.name, size: .body2, color: color, weight: .regular)
                    BrightText(session.time, size: .body2, color: color)
                }
            }
            .padding(.horizontal, .spacing105x)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 59)
            .background(
                color.opacity(.ultraLowOpacity),
                in: RoundedRectangle(cornerRadius: .cornerRadius14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadius14, style: .continuous)
                    .strokeBorder(color, lineWidth: 1)
                    .opacity(isSelected ? .opaque : 0)
            }
        }
        .buttonStyle(.plain)
    }

    private func color(for type: ExerciseDayType) -> Color {
        switch type {
        case .cardio: .defaultSkyBlue
        default: .defaultPurple
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightText("No workouts today", size: .body1)

            quickWorkoutMenu
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, .spacing3x)
        .padding(.top, .spacing3x)
        .padding(.bottom, .spacing4x)
    }

    private var quickWorkoutMenu: some View {
        Menu {
            Section("Saved Workouts") {
                ForEach(builder.saved) { session in
                    Button(session.name, systemImage: session.symbol) {
                        onQuickWorkout(session)
                    }
                }
            }
        } label: {
            BrightPillButton("Quick workout", buttonSize: .large) {}
            // The pill is only the label — let the Menu take the tap.
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Supporting Views

struct ExerciseSessionMiniSheet: View {
    let session: ExerciseUpcomingSession
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            HStack {
                HStack(spacing: .spacing105x) {
                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .fontWeight(.light)
                        .frame(width: 40, height: 40)
                        .foregroundStyle(Color.textColor)
                        .contentTransition(.symbolEffect(.replace))
                    BrightText(session.name, size: .standout1)
                        .contentTransition(.numericText())
                }
                Spacer()
                BrightRoundButton(systemImage: "xmark", size: .large, onTapCallback: onClose)
            }

            VStack(alignment: .leading, spacing: .spacing3x) {
                BrightText("Workout Goals", size: .body1, color: .semiLightTextColor)

                HStack(spacing: .spacing3x) {
                    ForEach(session.goals.indices, id: \.self) { i in
                        if i > 0 {
                            Rectangle()
                                .fill(Color.textColor.opacity(.minimalOpacity))
                                .frame(width: 1)
                        }
                        goalColumn(session.goals[i])
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }

            BrightText(session.note, size: .body2, color: .semiLightTextColor)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.numericText())
                .padding(.vertical, .spacing2x)

            BrightPillButton("Start workout", color: .defaultGreen, buttonSize: .large) {}
                .frame(maxWidth: .infinity)
                .padding(.top, .spacing1x)
        }
        .animation(.brightBouncy, value: session.name)
        .padding([.top, .horizontal], .spacing4x)
        .padding(.bottom, .spacing1x)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func goalColumn(_ goal: ExerciseSessionGoal) -> some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            HStack(spacing: .spacing1x) {
                Image(systemName: goal.icon)
                    .font(.standard(size: .body1, weight: .light))
                    .foregroundStyle(goal.iconColor)
                BrightText(goal.label, size: .body1)
                    .contentTransition(.numericText())
            }
            BrightText(goal.value, size: .standout1)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
    }

    private var icon: String {
        session.type == .cardio ? "figure.run" : "dumbbell"
    }
}

#Preview {
    ExerciseUpcomingWidget()
        .padding(.spacing4x)
        .environment(ExerciseSessionBuilder())
}
