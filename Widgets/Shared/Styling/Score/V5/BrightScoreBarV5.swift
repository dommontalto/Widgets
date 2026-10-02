//
//  BrightScoreBarV5.swift
//  Widgets
//
//  Created by Dom Montalto on 12/5/2026.
//

import SwiftUI

struct BrightScoreBarV5<Bar: View, StatusTile: View>: View {
    let scoreLabel: String
    let score: Int?
    let unit: String
    let showsFooter: Bool
    let progressBar: Bar
    let statusTile: StatusTile
    let onScoreTapped: (() -> Void)?

    init(
        scoreLabel: String = "Score",
        score: Int?,
        unit: String = "%",
        showsFooter: Bool = true,
        onScoreTapped: (() -> Void)? = nil,
        @ViewBuilder progressBar: () -> Bar,
        @ViewBuilder statusTile: () -> StatusTile
    ) {
        self.scoreLabel = scoreLabel
        self.score = score
        self.unit = unit
        self.showsFooter = showsFooter
        self.onScoreTapped = onScoreTapped
        self.progressBar = progressBar()
        self.statusTile = statusTile()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing4x) {
            HStack(alignment: .center) {
                BrightText(
                    localized: scoreLabel,
                    size: .body1,
                    color: .semiLightTextColor
                )
                .padding(.leading, .spacing1x)
                Spacer()
                statusTile
            }

            VStack(alignment: .leading, spacing: .spacing1x) {
                HStack(alignment: .lastTextBaseline, spacing: .spacing05x) {
                    BrightText(
                        score.map { "\($0)" } ?? "-",
                        size: .huge,
                        color: score == nil ? .lightTextColor : .textColor
                    )
                    .contentTransition(.numericText())
                    .animation(.brightSnappy, value: score)

                    BrightText(unit, size: .body1, color: .lightTextColor)
                }
                .animation(.brightSnappy, value: score)
                progressBar
                if showsFooter {
                    HStack {
                        BrightText("0", size: .body1, color: .semiLightTextColor)
                        Spacer()
                        BrightText("100\(unit)", size: .body1, color: .semiLightTextColor)
                    }
                }
            }
        }
        .padding(.spacing3x)
        .modifier(BrightCardModifierV5())
        .contentShape(Rectangle())
        .onTapGesture {
            onScoreTapped?()
        }
        .padding(.top, .spacing3x)
    }
}

struct BrightScoreGradientBarV5: View {
    let percent: Int
    @State private var animatedScore: Double = 0
    @State private var progressBarWidth: CGFloat = 0

    static let height: CGFloat = 40

    var body: some View {
        ZStack(alignment: .leading) {
            Color.defaultMainGrey.opacity(.lowOpacity)
                .cornerRadius(.squareCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: .squareCornerRadius)
                        .stroke(Color.defaultMainGrey, lineWidth: 0.5)
                )

            LinearGradient(
                stops: [
                    .init(color: .defaultRed, location: 0),
                    .init(color: .defaultSkyBlue, location: 0.53),
                    .init(color: .defaultBrightGreen, location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: progressBarWidth)
            .mask(
                RoundedRectangle(cornerRadius: .squareCornerRadius.concentric(inset: .spacing05x))
                    .frame(width: progressBarWidth * (animatedScore / 100))
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
            .onAppear {
                animatedScore = 0
                withAnimation(.brightBouncy) {
                    animatedScore = Double(abs(percent))
                }
            }
            .onChange(of: percent) {
                let newScore = Double(abs(percent))
                withAnimation(newScore == 0 ? .brightSnappy : .brightBouncy) {
                    animatedScore = newScore
                }
            }
            .padding(.spacing05x)
        }
        .frame(height: Self.height)
        .modifier(SizeReader { size in
            progressBarWidth = size.width - .spacing1x
        })
    }
}
