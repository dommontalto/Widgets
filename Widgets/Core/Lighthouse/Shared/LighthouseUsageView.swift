//
//  LighthouseUsageView.swift
//  Widgets
//

import SwiftUI

// How much of the plan's credits this period has used, on the intake gradient: the big percentage, the bar, and the
// allowance's two ends under it.
struct LighthouseUsageView: View {
    // 0 to 1.
    let used: Double
    var floorTitle = "0 credits"
    var ceilingTitle = "10 M"

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            VStack(alignment: .leading, spacing: .spacing1x) {
                HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                    BrightText("\(Int((used * 100).rounded()))", size: .standout2)
                        .monospacedDigit()
                    BrightText(Constants.usedTitle, size: .body1, color: .lightTextColor)
                }

                bar
            }

            HStack {
                BrightText(floorTitle, size: .body1, color: .lightTextColor)
                Spacer(minLength: .spacing2x)
                BrightText(ceilingTitle, size: .body1, color: .lightTextColor)
            }
        }
    }

    // The gradient runs the full track, so the filled part shows the colours for how far along it is; the warning
    // stripes cover the last tenth of the allowance.
    private var bar: some View {
        let gradient = LinearGradient(gradient: .brightIntake, startPoint: .leading, endPoint: .trailing)
        return GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(gradient)
                    .opacity(.minimalOpacity)

                Capsule()
                    .fill(gradient)
                    .mask(alignment: .leading) {
                        Capsule()
                            .frame(width: proxy.size.width * min(max(used, 0), 1))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                Image(ImageNames.lighthouseUsageHatchV5)
                    .resizable()
                    .frame(width: Constants.hatchArtWidth, height: Constants.hatchArtHeight)
                    .offset(Constants.hatchArtOffset)
                    .frame(width: proxy.size.width * Constants.warningShare, height: Constants.barHeight - Constants.hatchInset * 2)
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, Constants.hatchInset)
            }
        }
        .frame(height: Constants.barHeight)
    }

    private enum Constants {
        static let usedTitle = "% used"
        static let barHeight: CGFloat = .spacing2x
        static let warningShare = 0.1
        static let hatchInset: CGFloat = 1
        // The stripes are drawn on a larger sheet and only a sliver of it shows through the end of the bar.
        static let hatchArtWidth: CGFloat = 243.8
        static let hatchArtHeight: CGFloat = 149
        static let hatchArtOffset = CGSize(width: 93.2, height: -3.2)
    }
}

#Preview {
    LighthouseUsageView(used: 0.34)
        .padding(.spacing3x)
        .background(Color.defaultBackground)
}
