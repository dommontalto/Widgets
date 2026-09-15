//
//  LighthouseConfigurationsSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 15/9/2026.
//

import SwiftUI

// The dashboard set-ups Lighthouse has put together, each one switchable and
// listing the widgets it lays out.
struct LighthouseConfigurationsSheet: View {
    @State private var configurations = LighthouseDemo.configurations

    var body: some View {
        BrightPageSheetView(
            trailing: {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {} label: {
                        Label("Settings", systemImage: "gear")
                            .labelStyle(.iconOnly)
                    }

                    Button {} label: {
                        Label("Add configuration", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    }
                }
            },
            content: {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: .spacing3x) {
                        header

                        ForEach($configurations) { $configuration in
                            card($configuration)
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
            Image(systemName: "rectangle.3.group.fill")
                .font(.standard(size: .standout2, weight: .light))
                .foregroundStyle(Color.textColor)

            BrightText(Constants.title, size: .standout3)
        }
        .padding(.horizontal, .spacing2x)
    }

    private func card(_ configuration: Binding<LighthouseConfiguration>) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(alignment: .top, spacing: .spacing2x) {
                VStack(alignment: .leading, spacing: .spacing1x) {
                    BrightText(configuration.wrappedValue.title, size: .body1, weight: .regular)

                    HStack(spacing: .spacing1x) {
                        Image(systemName: "clock")
                            .font(.standard(size: .body1, weight: .light))
                            .foregroundStyle(Color.semiLightTextColor)

                        BrightText(configuration.wrappedValue.created, size: .body1, color: .semiLightTextColor)
                    }
                }

                Spacer(minLength: .spacing2x)

                Toggle("", isOn: configuration.isOn)
                    .labelsHidden()
                    .tint(Color.defaultGreen)
                    .brightHaptic(.light, trigger: configuration.wrappedValue.isOn)
            }

            BrightDivider()

            BrightText(Constants.widgetsLabel, size: .body1, color: .lightTextColor)

            FlowLayout(spacing: .spacing1x) {
                ForEach(configuration.wrappedValue.widgets, id: \.self) { widget in
                    BrightChip(title: widget)
                }
            }
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
    }

    private enum Constants {
        static let title = "Configurations"
        static let widgetsLabel = "Widgets:"
    }
}

#Preview {
    LighthouseConfigurationsSheet()
}
