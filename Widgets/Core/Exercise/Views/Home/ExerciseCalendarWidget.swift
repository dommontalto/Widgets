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
                dotStyle: { ExerciseCalendarDemo.dotStyle(on: $0) }
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

    // A session holding more than one discipline wears the both gradient: the
    // accent line runs the blend along its own height, and the body is masked
    // by a gradient that reaches blue by mid-card — the swatch spread would
    // stay purple for most of a card this wide.
    private func sessionCard(_ session: ExerciseCalendarSession) -> some View {
        let isMixed = session.symbols.count > 1

        return HStack(spacing: .spacing105x) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(isMixed
                    ? AnyShapeStyle(ExerciseDayType.bothGradient)
                    : AnyShapeStyle(session.color))
                .frame(width: 2)

            sessionBody(session)
                .overlay {
                    if isMixed {
                        cardGradient
                            .mask(sessionBody(session))
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding(.spacing2x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isMixed
                ? AnyShapeStyle(cardGradient.opacity(.ultraLowOpacity))
                : AnyShapeStyle(session.color.opacity(.ultraLowOpacity)),
            in: RoundedRectangle(cornerRadius: .cornerRadius18, style: .continuous)
        )
    }

    private var cardGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .defaultPurple, location: 0),
                .init(color: .defaultSkyBlueCyan, location: Constants.cardBlueStop),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func sessionBody(_ session: ExerciseCalendarSession) -> some View {
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
        // Where the mixed card's gradient lands fully on blue.
        static let cardBlueStop: Double = 0.55
    }
}

#Preview {
    ExerciseCalendarWidget()
        .padding(.spacing4x)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.defaultBackground.ignoresSafeArea())
}
