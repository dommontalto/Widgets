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
struct BrightIslandIndicator<Content: View, Footer: View>: View {
    // Set to make the square itself tappable; everything around it still
    // lets touches through to the screen beneath.
    var onTap: (() -> Void)?
    @ViewBuilder var content: Content
    // Laid over the foot of the square rather than stacked under the
    // content, so adding it doesn't shift the content off centre.
    @ViewBuilder var footer: Footer

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
                .overlay(alignment: .bottom) {
                    footer
                        .padding(.bottom, .spacing2x)
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
                .contentShape(.rect(cornerRadius: CGFloat.cornerRadius44))
                .onTapGesture { onTap?() }

            Spacer(minLength: .spacing0x)
        }
        .padding(.top, .spacing2x)
        .ignoresSafeArea()
        .allowsHitTesting(onTap != nil)
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

extension BrightIslandIndicator where Footer == EmptyView {
    init(onTap: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.init(onTap: onTap, content: content, footer: { EmptyView() })
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
