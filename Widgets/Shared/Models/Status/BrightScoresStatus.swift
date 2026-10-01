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

    private var isNoData: Bool {
        status.displayTitle.uppercased() == "NO DATA"
    }

    var body: some View {
        ZStack {
            BrightText(
                status.displayTitle.uppercased(),
                size: .body3,
                color: isNoData ? .lightTextColor : status.color,
                
            )
            .padding(isNoData ? .zero : .spacing1x)
        }
        .background(
            isNoData ? Color.clear : status.color.opacity(0.15)
        )
        .clipShape(Capsule())
    }
}

#Preview {
    BrightScoresStatus(status: .good)
}

extension BrightScoresStatus {
    struct NoDataTile: View {
        var body: some View {
            BrightText(
                "NO DATA",
                size: .body3,
                color: .lightTextColor,
                
            )
            .padding(.spacing1x)
            .clipShape(Capsule())
        }
    }
}
