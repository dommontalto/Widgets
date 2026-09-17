//
//  BrightPlaceholderView.swift
//  Widgets
//

import SwiftUI

struct BrightPlaceholderView: View {
    let title: String
    var subtitle: String?
    var fillsViewport = true

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
        fillsViewport: Bool = true,
        buttonAction: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.assetImage = nil
        self.title = title
        self.subtitle = subtitle
        self.imageColor = imageColor
        self.buttonTitle = buttonTitle
        self.fillsViewport = fillsViewport
        self.buttonAction = buttonAction
    }

    init(
        image: String,
        title: String,
        subtitle: String? = nil,
        buttonTitle: String? = nil,
        fillsViewport: Bool = true,
        buttonAction: (() -> Void)? = nil
    ) {
        self.systemImage = nil
        self.assetImage = image
        self.title = title
        self.subtitle = subtitle
        self.imageColor = nil
        self.buttonTitle = buttonTitle
        self.fillsViewport = fillsViewport
        self.buttonAction = buttonAction
    }

    private var image: Image {
        if let systemImage {
            Image(systemName: systemImage)
        } else {
            Image(assetImage ?? "")
        }
    }

    @ViewBuilder
    var body: some View {
        if fillsViewport {
            layout
                .padding(.bottom, .spacing12x + .spacing12x + .spacing6x)
                .containerRelativeFrame(.vertical)
        } else {
            layout
        }
    }

    private var layout: some View {
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
    .background(Color.defaultBackground.ignoresSafeArea())
}
