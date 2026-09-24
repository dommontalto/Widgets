//
//  LighthouseCheckInsSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 10/9/2026.
//

import SwiftUI

// The check-ins Lighthouse runs on a schedule, grouped by how often they
// repeat and each one switchable on its own.
struct LighthouseCheckInsSheet: View {
    @State private var checkIns = LighthouseDemo.checkIns
    @State private var editing: LighthouseCheckIn?

    var body: some View {
        BrightPageSheetView(
            content: {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: .spacing4x) {
                        header

                        ForEach(LighthouseCheckInFrequency.allCases) { frequency in
                            section(frequency)
                        }
                    }
                    .padding(.top, .spacing2x)
                    .padding(.bottom, .spacing4x)
                }
                .animation(.brightEaseInOut, value: checkIns)
                .sheet(item: $editing) { checkIn in
                    LighthouseWaypointSheet(checkIn: checkIn, onConfirm: save, onDelete: remove)
                }
            }
        )
    }

    private var header: some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: "person.badge.clock.fill")
                .font(.standard(size: .standout2, weight: .light))
                .foregroundStyle(Color.textColor)

            BrightText(Constants.title, size: .standout3)
        }
        .padding(.horizontal, .spacing2x)
    }

    @ViewBuilder
    private func section(_ frequency: LighthouseCheckInFrequency) -> some View {
        let group = indices(for: frequency)

        if !group.isEmpty {
            VStack(alignment: .leading, spacing: .spacing2x) {
                BrightText(frequency.title, size: .body1, color: .semiLightTextColor, weight: .regular)
                    .padding(.horizontal, .spacing2x)

                VStack(spacing: .spacing3x) {
                    ForEach(group, id: \.self) { index in
                        card($checkIns[index])
                    }
                }
            }
        }
    }

    private func card(_ checkIn: Binding<LighthouseCheckIn>) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing2x) {
                BrightText(checkIn.wrappedValue.title, size: .body1, weight: .regular)

                Spacer(minLength: .spacing2x)

                Toggle("", isOn: checkIn.isOn)
                    .labelsHidden()
                    .tint(Color.defaultGreen)
                    .brightHaptic(.light, trigger: checkIn.wrappedValue.isOn)
            }

            BrightDivider()

            BrightText(checkIn.wrappedValue.detail, size: .body1, color: .lightTextColor)
                .lineSpacing(.lineSpacingMedium)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
        .contentShape(Rectangle())
        .onTapGesture { editing = checkIn.wrappedValue }
    }

    private func indices(for frequency: LighthouseCheckInFrequency) -> [Int] {
        checkIns.indices.filter { checkIns[$0].frequency == frequency }
    }

    private func save(_ updated: LighthouseCheckIn) {
        guard let index = checkIns.firstIndex(where: { $0.id == updated.id }) else { return }
        checkIns[index] = updated
    }

    private func remove(_ checkIn: LighthouseCheckIn) {
        checkIns.removeAll { $0.id == checkIn.id }
    }

    private enum Constants {
        static let title = "Check-ins"
    }
}

#Preview {
    LighthouseCheckInsSheet()
}
