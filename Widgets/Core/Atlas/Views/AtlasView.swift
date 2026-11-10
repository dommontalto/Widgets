//
//  AtlasView.swift
//  Widgets
//
//  Created by Dom Montalto on 10/11/2026.
//

import SwiftUI

struct AtlasView: View {
    @State private var type = BrightChartV5v2Type.bar
    @State private var range = BrightChartV5v2Range.day

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacing4x) {
                BrightChartV5v2(type: type, range: $range, tint: tint) { period in
                    BrightChartV5v2Demo.points(for: period, type: type)
                }
            }
            .padding(.bottom, .viewPaddingBottom)
        }
        .background(Color.defaultBackground.ignoresSafeArea())
        .navigationTitle("Atlas")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Type", selection: $type) {
                        ForEach(BrightChartV5v2Type.allCases) { type in
                            Label(type.title, systemImage: type.systemImage).tag(type)
                        }
                    }
                } label: {
                    Label(type.title, systemImage: type.systemImage)
                        .labelStyle(.iconOnly)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: type)
    }

    private var tint: Color {
        switch type {
        case .bar: .defaultGreen
        case .line: .defaultRed
        case .dotted: .defaultCyan
        }
    }
}

#Preview {
    NavigationStack {
        AtlasView()
    }
}
