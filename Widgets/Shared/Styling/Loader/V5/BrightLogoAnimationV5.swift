//
//  BrightLogoAnimationV5.swift
//  Bright
//
//  Created by Vinh Tran on 11/3/2026.
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import SwiftUI

private struct BrightSpinningLoaderV5: ViewModifier {
    @Binding var isLoading: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    let globalFrame = proxy.frame(in: .global)
                    ZStack {
                        if isLoading {
                            BrightLogoAnimationV5(size: 60)
                                .position(
                                    x: UIScreen.main.bounds.midX - globalFrame.minX,
                                    y: UIScreen.main.bounds.midY - globalFrame.minY
                                )
                        }
                    }
                    .animation(.brightEaseInOut, value: isLoading)
                }
            }
    }
}

struct BrightLogoAnimationV5: View {
    let size: CGFloat
    var cycleCompleted: (() -> Void)?
    private let barCount = 28

    @State private var filledIndexes: Set<Int> = []
    @State private var activeIndex = 0
    @State private var isFilling = true
    @State private var isAnimating = true
    @State private var hasAppeared = false

    private var innerRadiusWidth: CGFloat {
        size * 0.88
    }
    private var cornerRadius: CGFloat {
        size * 0.25
    }
    private var barWidth: CGFloat {
        (size / 100.0) * 3.3
    }

    var body: some View {
        ZStack {
            ForEach(0 ..< barCount, id: \.self) { index in
                let color = if filledIndexes.contains(index) {
                    Color.defaultWhiteBlack
                } else {
                    Color.gray.opacity(0.3)
                }
                Rectangle()
                    .fill(color)
                    .frame(width: barWidth)
                    .offset(y: -innerRadiusWidth)
                    .rotationEffect(.degrees(Double(index) / Double(barCount) * 360))
                    .animation(.easeInOut(duration: 0.1), value: filledIndexes)
            }
        }
        .frame(width: size, height: size)
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.4)
        .animation(.smooth(duration: 0.5), value: hasAppeared)
        .onAppear {
            startAnimation()
            hasAppeared = true
        }
        .onDisappear {
            stopAnimation()
            hasAppeared = false
        }
    }

    private func startAnimation() {
        isAnimating = true
        activeIndex = 0
        filledIndexes = []
        isFilling = true

        animateLoader()
    }

    private func animateLoader() {
        guard isAnimating else { return }
        var speed = 0.07
        if filledIndexes.count >= 7, filledIndexes.count <= 21 {
            speed = 0.025
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(speed))
            guard isAnimating else { return }
            if isFilling {
                filledIndexes.insert(activeIndex)
            } else {
                filledIndexes.remove(activeIndex)
            }
            activeIndex = (activeIndex + 1) % barCount

            if activeIndex == 0 {
                isFilling.toggle()
                cycleCompleted?()
            }
            animateLoader()
        }
    }

    private func stopAnimation() {
        isAnimating = false
    }
}

extension View {
    func brightLogoAnimationV5(isLoading: Binding<Bool>, isSubview: Bool = false) -> some View {
        modifier(BrightSpinningLoaderV5(isLoading: isLoading))
    }
}
