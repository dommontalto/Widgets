//
//  ScoreGradientWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 6/6/2026.
//

import SwiftUI

// Speedometer-style score gauge: an open arc whose red→green gradient is
// revealed up to the value, a white dot marker at the value, the rolling
// number in the centre and a tinted metric icon beneath it.
struct ScoreGradientWidget: View {
    // Single source of truth for this widget's card padding.
    static let cardPadding: CGFloat = .spacing2x + .spacing05x

    let score: Int?
    let icon: String
    let iconColor: Color
    var diameter: CGFloat = 88
    var lineWidth: CGFloat = .spacing2x + .spacing05x

    @State private var animatedProgress: CGFloat = 0

    // Portion of the circle left open at the bottom.
    private static let gapFraction: CGFloat = 0.25
    private var arcFraction: CGFloat { 1 - Self.gapFraction }

    // Rotates the trimmed arc so its opening is centred at the bottom.
    private var rotation: Double { (0.25 + Self.gapFraction / 2) * 360 }

    private var dotSize: CGFloat { lineWidth }

    private var progress: CGFloat {
        CGFloat(min(max(score ?? 0, 0), 100)) / 100
    }

    // Light/dark adaptive gradient stops (light value, dark value).
    private static let gradientStops: [Gradient.Stop] = [
        .init(color: Color(light: .defaultRed, dark: .defaultRed), location: 0.0),
        .init(color: Color(light: Color(hex: "#E63D00"), dark: Color(hex: "#E63D00")), location: 0.2),
        .init(color: Color(light: Color(hex: "#FFC814"), dark: Color(hex: "#FFCD29")), location: 0.4),
        .init(color: Color(light: Color(hex: "#90FF54"), dark: Color(hex: "#B0FF85")), location: 0.6),
        .init(color: Color(light: Color(hex: "#00DBEB"), dark: Color(hex: "#00EEFF")), location: 0.8),
        .init(color: Color(light: Color(hex: "#00D54F"), dark: Color(hex: "#00FF5F")), location: 1.0),
    ]

    private var gradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: Self.gradientStops),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(Double(arcFraction) * 360)
        )
    }

    var body: some View {
        ZStack {
            // Dim full-length track (faded gradient)
            Circle()
                .trim(from: 0, to: arcFraction)
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .opacity(.minimalOpacity)
                .rotationEffect(.degrees(rotation))

            // Gradient revealed up to the value
            Circle()
                .trim(from: 0, to: arcFraction * animatedProgress)
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(rotation))

            // Value marker
            Circle()
                .fill(Color.defaultBlackWhite)
                .overlay(Circle().fill(Color.textColor).padding(.spacing05x))
                .frame(width: dotSize, height: dotSize)
                .offset(y: -diameter / 2)
                .rotationEffect(.degrees(rotation + 90 + Double(arcFraction * animatedProgress) * 360))

            VStack(spacing: .spacing05x) {
                RollingNumberText(value: score ?? 0, size: .standout3, color: .textColor)
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(iconColor)
                    .frame(width: .spacing4x, height: .spacing4x)
                    .offset(y: .spacing3x)
            }
            .offset(y: .spacing2x)
        }
        .frame(width: diameter, height: diameter)
        .onAppear {
            animatedProgress = 0
            Task { @MainActor in
                withAnimation(.brightBouncy) { animatedProgress = progress }
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.brightBouncy) { animatedProgress = newValue }
        }
    }
}

#Preview {
    HStack(spacing: .spacing2x) {
        ScoreGradientWidget(score: 20, icon: ImageNames.recoveryV5, iconColor: .defaultGreen)
        ScoreGradientWidget(score: 77, icon: ImageNames.stressV5, iconColor: .defaultPurple)
        ScoreGradientWidget(score: 82, icon: ImageNames.strainV5, iconColor: .defaultRed)
    }
    .padding()
}
