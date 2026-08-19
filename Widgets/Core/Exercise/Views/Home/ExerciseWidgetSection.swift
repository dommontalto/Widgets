//
//  ExerciseWidgetSection.swift
//  Widgets
//
//  Created by Dom Montalto on 19/8/2026.
//

import SwiftUI

struct ExerciseWidgetSection<Content: View>: View {
    enum HeaderIcon {
        case asset(String)
        case symbol(String)
    }

    let icon: HeaderIcon
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            HStack(spacing: .spacing1x) {
                iconView
                    .frame(width: Constants.iconSize, height: Constants.iconSize)

                BrightText(title, size: .body1)
            }
            .padding(.leading, .spacing2x)

            content
        }
    }

    @ViewBuilder private var iconView: some View {
        switch icon {
        case let .asset(name):
            Image(name)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.textColor)
        case let .symbol(name):
            Image(systemName: name)
                .font(.standardSFPro(size: .subheading2, weight: .regular))
                .foregroundStyle(Color.textColor)
        }
    }
}

private class Constants {
    static let iconSize: CGFloat = 24
}

#Preview {
    ExerciseWidgetSection(icon: .symbol("trophy.fill"), title: "Personal Records") {
        ExercisePersonalRecordsWidget(records: ExerciseDemoComplete.cardio.records)
    }
    .padding(.spacing3x)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.defaultSheetBackground.ignoresSafeArea())
}
