//
//  BrightRevealV5.swift
//  Widgets
//
//  Created by Dom Montalto on 12/10/2026.
//

import SwiftUI

extension EnvironmentValues {
    // Bumping it plays every widget's reveal again.
    @Entry var brightRevealReplay = 0
}

// Turns `isRevealed` on with a bounce the first time a widget appears, so it can grow its
// readings from nothing: rings fill from empty, bars rise, lines draw. With reduce motion
// it's simply on.
private struct BrightRevealV5: ViewModifier {
    @Binding var isRevealed: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.brightRevealReplay) private var replay

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !isRevealed else { return }
                reveal()
            }
            .onChange(of: replay) {
                // Emptied without animating, then revealed on the next pass so it grows
                // from nothing rather than from where it was.
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    isRevealed = false
                }
                Task { @MainActor in
                    reveal()
                }
            }
    }

    private func reveal() {
        guard !reduceMotion else {
            isRevealed = true
            return
        }
        withAnimation(.brightReveal) {
            isRevealed = true
        }
    }
}

// Wipes the content in from the leading edge, so a line or a strip draws across. Given the
// line's points, from 0 to 1 across and down the content, the wipe spans just the line, so
// one that stops partway still takes the whole draw, and the selector rides its tip. The
// mask runs past the ends so marks that sit on them, like the latest reading's dot, aren't cut.
private struct BrightDrawRevealV5: ViewModifier, Animatable {
    var progress: Double
    let path: [CGPoint]

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .mask(alignment: .leading) {
                GeometryReader { geometry in
                    Rectangle()
                        .frame(width: max(maskWidth(in: geometry.size.width), 0))
                        .padding(.vertical, -Constants.overhang)
                        .offset(x: -Constants.overhang)
                }
            }
            .overlay {
                if progress > 0, progress < 1, !path.isEmpty {
                    GeometryReader { geometry in
                        if let tip = tip(in: geometry.size) {
                            BrightSelectorOverlayV5(point: tip)
                        }
                    }
                }
            }
    }

    // The line's ends in points, or the whole width when there's no line to follow.
    private func span(in width: CGFloat) -> ClosedRange<CGFloat> {
        guard let first = path.first, let last = path.last else { return 0 ... width }
        return first.x * width ... last.x * width
    }

    private func edge(in width: CGFloat) -> CGFloat {
        let span = span(in: width)
        return span.lowerBound + (span.upperBound - span.lowerBound) * progress
    }

    // Measured from the overhang before the leading edge; once drawn it covers everything.
    private func maskWidth(in width: CGFloat) -> CGFloat {
        if progress >= 1 {
            return width + Constants.overhang * 2
        }
        return progress > 0 ? edge(in: width) + Constants.overhang : 0
    }

    // Where the wipe's edge crosses the line, between the two points either side of it.
    private func tip(in size: CGSize) -> CGPoint? {
        guard size.width > 0 else { return nil }
        let x = edge(in: size.width) / size.width
        guard let after = path.firstIndex(where: { $0.x >= x }) else { return nil }
        let end = path[after]
        let start = after > 0 ? path[after - 1] : end
        let fraction = end.x > start.x ? (x - start.x) / (end.x - start.x) : 1
        return CGPoint(x: x * size.width, y: (start.y + (end.y - start.y) * fraction) * size.height)
    }

    private enum Constants {
        static let overhang: CGFloat = .spacing2x
    }
}

extension View {
    func brightRevealV5(_ isRevealed: Binding<Bool>) -> some View {
        modifier(BrightRevealV5(isRevealed: isRevealed))
    }

    func brightDrawRevealV5(_ isRevealed: Bool, following path: [CGPoint] = []) -> some View {
        modifier(BrightDrawRevealV5(progress: isRevealed ? 1 : 0, path: path))
            .animation(.brightDraw, value: isRevealed)
    }
}

extension String {
    // Every digit as a 0, so a number rolling up from zero keeps its width and nothing
    // beside it moves: "1,170" starts from "0,000".
    var zeroedDigits: String {
        String(map { $0.isNumber ? "0" : $0 })
    }
}
