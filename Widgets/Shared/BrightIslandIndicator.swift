//
//  BrightIslandIndicator.swift
//  Widgets
//
//  Created by Dom Montalto on 14/9/2026.
//

import SwiftUI

// A panel that grows out of the Dynamic Island and collapses back into it,
// rather than sliding in from off-screen. It blacks the notch out — solid for
// the top quarter, dissolving into the black glass beneath by its bottom edge
// — so the island and the panel read as one shape.
struct BrightIslandIndicator<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: .spacing0x) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.spacing3x)
                // A square, half the screen wide, with the content centred in it.
                .aspectRatio(1, contentMode: .fit)
                .containerRelativeFrame(.horizontal) { width, _ in
                    width * Constants.widthFraction
                }
                .background(wash)
                .clipShape(.rect(cornerRadius: CGFloat.cornerRadius44))
                .modifier(GlassEffect(
                    shape: .roundedRect,
                    cornerRadius: CGFloat.cornerRadius44,
                    tint: .black
                ))
                // The same hairline the side menu draws down the content's
                // edge, so the panel reads as a lifted plate over the chat.
                .overlay {
                    RoundedRectangle(cornerRadius: CGFloat.cornerRadius44)
                        .strokeBorder(Color.white.opacity(Constants.edgeLineOpacity), lineWidth: Constants.edgeLineWidth)
                }

            Spacer(minLength: .spacing0x)
        }
        .padding(.top, .spacing2x)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .transition(.scale(scale: Constants.growScale, anchor: .top).combined(with: .opacity))
    }

    private var wash: some View {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: Constants.washSolidEnd),
                .init(color: .black.opacity(.lowOpacity), location: Constants.washFadeStart),
                .init(color: .clear, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// Outside the struct: a generic type cannot hold static stored properties.
private enum Constants {
    static let widthFraction: CGFloat = 0.5
    static let edgeLineWidth: CGFloat = 0.5
    static let edgeLineOpacity: Double = .minimalOpacity
    static let growScale: CGFloat = 0.3
    static let washSolidEnd: CGFloat = 0.25
    static let washFadeStart: CGFloat = 0.6
}

#Preview {
    @Previewable @State var isShowing = true

    Color.defaultBackground
        .ignoresSafeArea()
        .overlay {
            if isShowing {
                BrightIslandIndicator {
                    BrightSolvingStars(state: .thinking, ambientMotion: .off)
                        .aspectRatio(1, contentMode: .fit)
                        .containerRelativeFrame(.horizontal) { width, _ in width * 0.25 }
                }
            }
        }
        .onTapGesture {
            withAnimation(.brightSnappy) { isShowing.toggle() }
        }
}
