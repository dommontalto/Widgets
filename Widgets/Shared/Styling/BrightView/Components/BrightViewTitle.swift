//
//  BrightViewTitle.swift
//  Widgets
//
//  Created by Zoe Friedman on 6/10/2023.
//

import SwiftUI

struct BrightViewTitle: View {
    let title: String?
    let size: FontSizes
    let color: Color
    let isSheet: Bool

    init(
        _ title: String?,
        size: FontSizes = .subheading2,
        color: Color = .textColor,
        isSheet: Bool = false
    ) {
        self.title = title
        self.size = size
        self.color = color
        self.isSheet = isSheet
    }

    class Constants {
        static let lineLimit = 1
        static let buttonSize: CGFloat = 34
        static let buttonInset: CGFloat = 30
        static let buttonSpacing: CGFloat = .spacing1x
        static let titleTopPadding: CGFloat = .spacing2x
        static let titleSheetTopPadding: CGFloat = .spacing4x
        static let titleBottomPadding: CGFloat = 14
    }

    var body: some View {
        BrightText(
            title ?? "",
            size: size,
            color: color,
            weight: .medium
        )
        .multilineTextAlignment(.center)
        .lineLimit(Constants.lineLimit)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(
            .horizontal,
            Constants.buttonInset + Constants.buttonSize + Constants.buttonSpacing
        )
        .padding(
            .top,
            isSheet ? Constants.titleSheetTopPadding : Constants.titleTopPadding
        )
        .padding(.bottom, Constants.titleBottomPadding)
    }
}

#Preview {
    BrightViewTitle("Hello World")
}
