//
//  LighthouseChatResponse.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

nonisolated struct LighthouseStoryItem: Identifiable, Equatable {
    let id = UUID()
    let text: String
}

// A Lighthouse answer inside the chat thread: the opening line, then each
// insight as its own paragraph.
struct LighthouseChatResponse: View {
    let text: String
    let items: [LighthouseStoryItem]

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing5x) {
            BrightText(text, size: .body1)
                .lineSpacing(.lineSpacingMedium)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(items) { item in
                BrightText(item.text, size: .body1, color: .lightTextColor)
                    .lineSpacing(.lineSpacingMedium)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ScrollView {
        LighthouseChatResponse(
            text: LighthouseDemo.sleepPartOne,
            items: LighthouseDemo.sleepItems
        )
        .padding(.spacing3x)
    }
    .background(Color.defaultBackground)
}
