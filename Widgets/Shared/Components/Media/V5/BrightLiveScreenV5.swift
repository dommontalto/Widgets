//
//  BrightLiveScreenV5.swift
//  Widgets
//

import SwiftUI
import UIKit

// A small live copy of the app's page, as it sits behind anything presented over
// it or a window above it (the Lighthouse tray). Redrawn once a second while
// on screen; the last frame stays if the page leaves the window.
struct BrightLiveScreenV5: View {
    var height: CGFloat = Constants.defaultHeight
    var cornerRadius: CGFloat = Constants.cornerRadius
    var borderCornerRadius: CGFloat = Constants.borderCornerRadius

    @State private var frame: UIImage?
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        Group {
            if let frame {
                Image(uiImage: frame)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                shape
                    .fill(Color.semiLightTextColor.opacity(.lowOpacity))
                    .aspectRatio(Constants.placeholderAspect, contentMode: .fit)
            }
        }
        .frame(height: height)
        .clipShape(shape)
        .padding(Constants.borderGap)
        .overlay {
            RoundedRectangle(cornerRadius: borderCornerRadius, style: .continuous)
                .strokeBorder(Color.black.opacity(.minimalOpacity), lineWidth: Constants.borderWidth)
        }
        .accessibilityHidden(true)
        .task(id: height) {
            while !Task.isCancelled {
                if let next = Self.capture(height: height, scale: displayScale) {
                    frame = next
                }
                try? await Task.sleep(for: Constants.refresh)
            }
        }
    }

    // The app's own window, its root page only: presented sheets and covers, and
    // windows above it such as the tray's, are left out.
    private static func capture(height: CGFloat, scale: CGFloat) -> UIImage? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .filter { !$0.isHidden && !($0 is LighthouseTrayWindow) }
            .min { $0.windowLevel < $1.windowLevel }
        guard let view = window?.rootViewController?.view, view.window != nil else { return nil }
        let bounds = view.bounds
        guard bounds.height > .zero else { return nil }

        let width = height * bounds.width / bounds.height
        // Floored to whole pixels, so the opaque canvas has no unpainted black column on the right.
        let size = CGSize(width: (width * scale).rounded(.down) / scale, height: height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        var drew = false
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            drew = view.drawHierarchy(in: CGRect(x: .zero, y: .zero, width: width, height: height), afterScreenUpdates: false)
        }
        return drew ? image : nil
    }

    private enum Constants {
        static let defaultHeight: CGFloat = 66
        static let cornerRadius: CGFloat = 10
        static let borderCornerRadius: CGFloat = 13
        static let borderGap: CGFloat = .spacing05x
        static let borderWidth: CGFloat = 1
        static let placeholderAspect: CGFloat = 0.46
        static let refresh = Duration.seconds(1)
    }
}

#Preview {
    BrightLiveScreenV5()
        .padding(.spacing3x)
        .background(Color.defaultBackground)
}
