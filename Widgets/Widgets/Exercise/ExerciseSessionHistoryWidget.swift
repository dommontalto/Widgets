//
//  ExerciseSessionHistoryWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 21/7/2026.
//

import SwiftUI

struct ExerciseSessionHistoryWidget: View {
    @State private var sessions = ExerciseDemoData.sessionHistory

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText("Logs", size: .body1, color: .textColor)
                BrightText("Past 14 days", size: .body2, color: .lightTextColor)
            }

            VStack(spacing: .spacing0x) {
                ForEach(sessions.indices, id: \.self) { i in
                    HStack {
                        BrightText(sessions[i].name, size: .body2, color: .semiLightTextColor, weight: .regular)
                        Spacer(minLength: .spacing2x)
                        BrightText(sessions[i].timestamp, size: .body2, color: .lightTextColor)
                    }
                    .padding(.vertical, .spacing105x)

                    if i < sessions.count - 1 {
                        Rectangle()
                            .fill(Color.textColor.opacity(.ultraLowOpacity))
                            .frame(height: 1)
                    }
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier())
    }
}

#Preview {
    ExerciseSessionHistoryWidget()
        .padding(.spacing4x)
}
