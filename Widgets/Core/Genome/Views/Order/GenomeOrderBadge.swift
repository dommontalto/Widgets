//
//  GenomeOrderBadge.swift
//  Widgets
//

import SwiftUI

struct GenomeOrderBadge: View {
    var body: some View {
        Image(ImageNames.genomeOrderBadgeTextureV5)
            .resizable()
            .scaledToFill()
            .frame(width: Constants.textureSize, height: Constants.textureSize)
            .offset(Constants.textureOffset)
            .frame(width: Constants.size, height: Constants.size)
            .clipShape(shape)
            .overlay {
                shape
                    .fill(Color.black.opacity(.ultraLowOpacity))
                    .overlay {
                        shape.strokeBorder(
                            RadialGradient(
                                colors: [.black.opacity(.semiLowOpacity), .black.opacity(.finalBossLowOpacity)],
                                center: .center,
                                startRadius: 0,
                                endRadius: Constants.size / 2
                            ),
                            lineWidth: Constants.strokeWidth
                        )
                    }
            }
            .overlay {
                Image(ImageNames.genomeOrderBadgeDnaV5)
                    .resizable()
                    .frame(width: Constants.dnaSize, height: Constants.dnaSize)
                    .blendMode(.overlay)
            }
            .compositingGroup()
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: .squareCornerRadius, style: .continuous)
    }

    private enum Constants {
        static let size: CGFloat = 46
        static let textureSize: CGFloat = 236.4
        static let textureOffset = CGSize(width: 0.6, height: 73.5)
        static let dnaSize: CGFloat = 28.1
        static let strokeWidth: CGFloat = 0.8
    }
}

#Preview {
    GenomeOrderBadge()
        .padding(.spacing3x)
}
