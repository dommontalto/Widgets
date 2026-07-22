//
//  BrightPlaceholderView.swift
//  Widgets
//

import SwiftUI

struct BrightPlaceholderView: View {
    let title: String
    var subtitle: String?

    private let systemImage: String?
    private let assetImage: String?
    private let imageColor: Color?
    private let buttonTitle: String?
    private let buttonAction: (() -> Void)?

    init(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        imageColor: Color? = nil,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.assetImage = nil
        self.title = title
        self.subtitle = subtitle
        self.imageColor = imageColor
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }

    init(
        image: String,
        title: String,
        subtitle: String? = nil,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.systemImage = nil
        self.assetImage = image
        self.title = title
        self.subtitle = subtitle
        self.imageColor = nil
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }

    private var image: Image {
        if let systemImage {
            Image(systemName: systemImage)
        } else {
            Image(assetImage ?? "")
        }
    }

    var body: some View {
        VStack(spacing: .spacing2x) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .foregroundStyle(imageColor ?? .textColor)

            BrightText(title, size: .heading)

            if let subtitle {
                BrightText(subtitle, size: .body1, color: .lightTextColor)
                    .multilineTextAlignment(.center)
            }

            if let buttonTitle, let buttonAction {
                BrightPillButton(buttonTitle) {
                    buttonAction()
                }
                .padding(.top, .spacing1x)
            }
        }
        .padding(.horizontal, .spacing6x)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    VStack(spacing: .spacing10x) {
        BrightPlaceholderView(systemImage: "tray", title: "No documents yet")

        BrightPlaceholderView(
            image: ImageNames.genomeV5,
            title: "Your order is confirmed",
            subtitle: "Your kit is on its way. We'll email you tracking details."
        )
    }
    .background(Color.bG.ignoresSafeArea())
}
