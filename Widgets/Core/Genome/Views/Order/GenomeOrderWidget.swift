//
//  GenomeOrderWidget.swift
//  Widgets
//

import SwiftUI

struct GenomeOrderWidget: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: .spacing2x) {
            GenomeOrderBadge()

            BrightText(Constants.title, size: .body1, color: .white)
                .lineLimit(1)

            Spacer(minLength: .spacing0x)

            BrightRoundButton(systemImage: "chevron.right", size: .small) {}
                .allowsHitTesting(false)
        }
        .padding(.horizontal, .spacing3x)
        .frame(maxWidth: .infinity)
        .frame(height: Constants.height)
        .background { background }
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))
    }

    // Slow drift on uneven periods so the motion never visibly loops.
    private var background: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate * Constants.speed
            Image(ImageNames.genomeOrderWidgetBackgroundV5)
                .resizable()
                .scaledToFill()
                .frame(width: Constants.imageSize.width, height: Constants.imageSize.height)
                .rotationEffect(.degrees(Constants.rotation + Constants.rotationSwing * sin(t / 11)))
                .offset(
                    x: Constants.imageOffset.width + Constants.drift * sin(t / 7),
                    y: Constants.imageOffset.height + Constants.drift * 0.6 * cos(t / 9)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blur(radius: Constants.blur, opaque: true)
        }
        .background(Color.black)
    }

    private enum Constants {
        static let title = "Order a DNA test today"
        static let height: CGFloat = 76
        static let imageSize = CGSize(width: 369.5, height: 461.9)
        static let imageOffset = CGSize(width: 4.5, height: 9.4)
        static let rotation: Double = -15
        static let rotationSwing: Double = 2
        static let speed: Double = 2
        static let drift: CGFloat = .spacing1x
        static let blur: CGFloat = 2.75
    }
}

#Preview {
    GenomeOrderWidget()
        .padding(.spacing3x)
        .background(Color.defaultBackground.ignoresSafeArea())
}
