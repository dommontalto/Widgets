//
//  BrightCalendarDropShadow.swift
//  Widgets
//
//  Created by Dom Montalto on 25/8/2026.
//

import SwiftUI

// Hangs below a pinned header so scrolled content reads as passing underneath.
// Attach to whatever sits lowest — the program banner, or the calendar itself
// when there is no banner.
struct BrightCalendarDropShadow: View {
    var progress: CGFloat

    var body: some View {
        LinearGradient(
            colors: [
                Color.defaultBlack.opacity(.ultraLowOpacity * min(max(progress, 0), 1)),
                .clear,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: Constants.height)
        .allowsHitTesting(false)
    }

    // Maps a scroll offset to the shadow's 0...1 strength over the first ramp
    // points of travel, so it darkens with the drag rather than switching on.
    static func progress(forOffset offset: CGFloat) -> CGFloat {
        min(max(offset / Constants.ramp, 0), 1)
    }

    enum Constants {
        static let height: CGFloat = .spacing2x
        static let ramp: CGFloat = .spacing8x
    }
}

extension View {
    func brightCalendarDropShadow(progress: CGFloat) -> some View {
        overlay(alignment: .bottom) {
            BrightCalendarDropShadow(progress: progress)
                .offset(y: BrightCalendarDropShadow.Constants.height)
        }
    }
}

#Preview {
    VStack(spacing: .spacing6x) {
        BrightText("Half scrolled", size: .body1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacing2x)
            .background(Color.defaultSheetBackground)
            .brightCalendarDropShadow(progress: 0.5)

        BrightText("Fully scrolled", size: .body1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacing2x)
            .background(Color.defaultSheetBackground)
            .brightCalendarDropShadow(progress: 1)
    }
    .frame(maxHeight: .infinity)
    .background(Color.defaultBackground.ignoresSafeArea())
}
