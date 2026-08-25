//
//  ExerciseCalendarWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 25/8/2026.
//

import SwiftUI

struct ExerciseCalendarWidget: View {
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var showingCalendarSheet = false

    var body: some View {
        VStack(spacing: .spacing1x) {
            BrightCalendar(
                selectedDate: $selectedDate,
                backgroundColor: .clear,
                hasDot: { ExerciseCalendarDemo.session(on: $0) != nil }
            ) {
                BrightRoundButton(
                    systemImage: "arrow.up.left.and.arrow.down.right",
                    size: .medium
                ) {
                    showingCalendarSheet = true
                }
            }

            sessionView
                .padding(.horizontal, .spacing3x)
                .padding(.bottom, .spacing3x)
                .transaction { $0.animation = .brightEaseInOut }
                .animation(.brightEaseInOut, value: selectedDate)
        }
        .padding(.top, .spacing3x)
        .modifier(CardModifier())
        .sheet(isPresented: $showingCalendarSheet) {
            ExerciseCalendarSheet(selectedDate: $selectedDate)
        }
    }

    private var sessionView: some View {
        Group {
            if let session = ExerciseCalendarDemo.session(on: selectedDate) {
                sessionCard(session)
            } else {
                emptyCard
            }
        }
        .id(selectedDate)
        .transition(.blurReplace)
    }

    private func sessionCard(_ session: ExerciseCalendarSession) -> some View {
        HStack(spacing: .spacing105x) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(session.color)
                .frame(width: 2)

            VStack(alignment: .leading, spacing: .spacing05x) {
                HStack(spacing: .spacing05x) {
                    BrightText(session.name, size: .body2, color: session.color, weight: .regular)

                    Spacer()

                    Image(systemName: "stopwatch")
                        .font(.standard(size: .body2, weight: .light))
                        .foregroundStyle(session.color)
                    BrightText(session.duration, size: .body2, color: session.color)
                }

                BrightText(session.time, size: .body2, color: session.color)
                    .opacity(.lowOpacity)

                HStack(spacing: .spacing1x) {
                    ForEach(session.symbols, id: \.self) { symbol in
                        chip(symbol)
                    }
                }
                .padding(.top, .spacing105x)
            }
        }
        .padding(.spacing2x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            session.color.opacity(.ultraLowOpacity),
            in: RoundedRectangle(cornerRadius: .cornerRadius18, style: .continuous)
        )
    }

    private var emptyCard: some View {
        HStack(spacing: .spacing105x) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(Color.defaultGreen)
                .frame(width: 2, height: 35)

            BrightText("No sessions", size: .body2, color: .defaultGreen, weight: .regular)
        }
        .padding(.spacing2x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.defaultGreen.opacity(.ultraLowOpacity),
            in: RoundedRectangle(cornerRadius: .cornerRadius18, style: .continuous)
        )
    }

    private func chip(_ symbol: String) -> some View {
        Circle()
            .strokeBorder(Color.textColor.opacity(.minimalOpacity), lineWidth: 1)
            .frame(width: Constants.chipSize, height: Constants.chipSize)
            .overlay {
                Image(systemName: symbol)
                    .font(.standardSFPro(size: .subheading, weight: .light))
                    .foregroundStyle(Color.textColor)
            }
    }

    enum Constants {
        static let chipSize: CGFloat = 36
    }
}

#Preview {
    ExerciseCalendarWidget()
        .padding(.spacing4x)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.defaultBackground.ignoresSafeArea())
}
