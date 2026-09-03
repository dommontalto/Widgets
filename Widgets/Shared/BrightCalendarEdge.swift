//
//  BrightCalendarEdge.swift
//  Widgets
//
//  Created by Dom Montalto on 25/8/2026.
//

import SwiftUI

struct BrightCalendarEdge: View {
    var progress: CGFloat

    var body: some View {
        Rectangle()
            .fill(Color.textColor.opacity(.ultraLowOpacity))
            .frame(height: Constants.lineHeight)
            .opacity(min(max(progress, 0), 1))
            .allowsHitTesting(false)
    }

    static func progress(forOffset offset: CGFloat) -> CGFloat {
        min(max(offset / Constants.ramp, 0), 1)
    }

    enum Constants {
        static let lineHeight: CGFloat = 1
        static let ramp: CGFloat = .spacing8x
    }
}

extension View {
    func brightCalendarEdge(progress: CGFloat) -> some View {
        overlay(alignment: .bottom) {
            BrightCalendarEdge(progress: progress)
                .offset(y: BrightCalendarEdge.Constants.lineHeight)
        }
    }
}

#Preview {
    VStack(spacing: .spacing6x) {
        BrightText("Half scrolled", size: .body1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacing2x)
            .background(Color.defaultSheetBackground)
            .brightCalendarEdge(progress: 0.5)

        BrightText("Fully scrolled", size: .body1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacing2x)
            .background(Color.defaultSheetBackground)
            .brightCalendarEdge(progress: 1)
    }
    .frame(maxHeight: .infinity)
    .background(Color.defaultBackground.ignoresSafeArea())
}
