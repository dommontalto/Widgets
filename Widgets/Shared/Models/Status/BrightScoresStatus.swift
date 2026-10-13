//
//  BrightScoresStatus.swift
//  Widgets
//
//  Created by Gangajaliya Sandeep on 24/7/2024.
//

import SwiftUI

struct BrightScoresStatus: View {
    let status: ScoresStatus
    var withStroke = false

    var body: some View {
        BrightText(
            status.displayTitle.uppercased(),
            size: .body3,
            color: status.color
        )
        .padding(.spacing1x)
        .background(status.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

#Preview {
    BrightScoresStatus(status: .optimal)
}
