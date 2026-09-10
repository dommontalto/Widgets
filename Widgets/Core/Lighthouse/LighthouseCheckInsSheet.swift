//
//  LighthouseCheckInsSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 10/9/2026.
//

import SwiftUI

// The check-ins Lighthouse runs on a schedule, each one switchable on its own.
struct LighthouseCheckInsSheet: View {
    @State private var checkIns = LighthouseDemo.checkIns

    var body: some View {
        BrightPageSheetView(
            trailing: {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {} label: {
                        Label("Settings", systemImage: "gear")
                            .labelStyle(.iconOnly)
                    }

                    Button {} label: {
                        Label("Add check-in", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    }
                }
            },
            content: {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: .spacing3x) {
                        header

                        ForEach($checkIns) { $checkIn in
                            card($checkIn)
                        }
                    }
                    .padding(.top, .spacing2x)
                    .padding(.bottom, .spacing12x)
                }
                .overlay(alignment: .bottomTrailing) {
                    BrightRoundButton(systemImage: "magnifyingglass", size: .large) {}
                        .padding(.bottom, .spacing2x)
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

    private func card(_ checkIn: Binding<LighthouseCheckIn>) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(alignment: .top, spacing: .spacing2x) {
                VStack(alignment: .leading, spacing: .spacing1x) {
                    BrightText(checkIn.wrappedValue.title, size: .body1, weight: .regular)

                    HStack(spacing: .spacing1x) {
                        Image(systemName: "person.badge.clock.fill")
                            .font(.standard(size: .body2, weight: .light))
                            .foregroundStyle(Color.semiLightTextColor)

                        BrightText(checkIn.wrappedValue.repeats, size: .body2, color: .semiLightTextColor)
                    }
                }

                Spacer(minLength: .spacing2x)

                Toggle("", isOn: checkIn.isOn)
                    .labelsHidden()
                    .tint(Color.defaultGreen)
                    .brightHaptic(.light, trigger: checkIn.wrappedValue.isOn)
            }

            BrightDivider()

            BrightText(checkIn.wrappedValue.detail, size: .body2, color: .lightTextColor)
                .lineSpacing(.lineSpacingMedium)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
    }

    private enum Constants {
        static let title = "Check-ins"
    }
}

#Preview {
    LighthouseCheckInsSheet()
}
