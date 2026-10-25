//
//  GenomeOrderWidget.swift
//  Widgets
//

import SwiftUI

struct GenomeOrderWidget: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 156)
            .background {
                background
            }
            .overlay {
                content
            }
            .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius))
            .contentShape(RoundedRectangle(cornerRadius: .cardCornerRadius))
            .modifier(BrightCardModifierV5(clipContent: false))
    }

    // Slow drift on uneven periods so the motion never visibly loops.
    private var background: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate * Constants.speed
            Image(ImageNames.genomeOrderBackgroundV5)
                .resizable()
                .scaledToFill()
                .scaleEffect(Constants.scale + Constants.scaleSwing * sin(t / 5))
                .rotationEffect(.degrees(Constants.rotation * sin(t / 11)))
                .offset(x: Constants.drift * sin(t / 7), y: Constants.drift * 0.6 * cos(t / 9))
                .blur(radius: 10, opaque: true)
                // The order sheet's fall-off: the waves sink into black towards the bottom.
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(.minimalOpacity), location: 0),
                            .init(color: .black.opacity(.veryLowOpacity), location: 0.5),
                            .init(color: .black, location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .background(Color.black)
    }

    private var content: some View {
        VStack(spacing: .spacing2x) {
            Image(ImageNames.genomeOrderDnaIconV5)

            BrightText(
                "Don’t have genetic data available?\nOrder your testing kit today.",
                size: .body1,
                color: .white
            )
            .multilineTextAlignment(.center)
        }
        .environment(\.colorScheme, .dark)
        .padding(.spacing4x)
    }

    private enum Constants {
        static let speed: Double = 2
        static let scale: CGFloat = 1.25
        static let scaleSwing: CGFloat = 0.08
        static let rotation: Double = 4
        static let drift: CGFloat = .spacing4x
    }
}

#Preview {
    GenomeOrderWidget()
        .padding(.spacing3x)
        .background(Color.defaultBackground.ignoresSafeArea())
}
