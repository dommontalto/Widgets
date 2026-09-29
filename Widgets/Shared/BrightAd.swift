//
//  BrightAd.swift
//  Widgets
//
//  Created by Dom Montalto on 28/9/2026.
//

import SwiftUI
import UIKit

// A sponsored card over a wash drawn from its own logo, the way Apple Music
// tints a player to its artwork: who they are, what they do, what they offer.
struct BrightAd: View {
    let title: String
    let subtitle: String
    let logo: String
    let logoBackground: Color
    var image: UIImage? = nil
    let blurb: String
    let services: [String]
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: .spacing0x) {
            header

            if !blurb.isEmpty || !services.isEmpty {
                details
            }
        }
        .frame(maxWidth: .infinity)
        .background { BrightAdBackdrop(logo: logo, image: image) }
        .overlay(alignment: .topTrailing) {
            adBadge
                .padding(.spacing3x)
        }
        .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous))
        .onTapGesture(perform: onTap)
        .environment(\.colorScheme, .dark)
    }

    private var header: some View {
        VStack(spacing: .spacing2x) {
            logoBackground
                .frame(width: Constants.logoSize, height: Constants.logoSize)
                .overlay {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(logo)
                            .resizable()
                            .scaledToFill()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius20, style: .continuous))
                .padding(.bottom, .spacing1x)

            BrightText(title, size: .standout1, color: .white)
                .multilineTextAlignment(.center)

            BrightText(subtitle, size: .body1, color: .white.opacity(.mediumOpacity))
                .multilineTextAlignment(.center)
        }
        .padding(.top, .spacing6x)
        .padding(.bottom, .spacing4x)
        .padding(.horizontal, .spacing3x)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            if !blurb.isEmpty {
                BrightText(blurb, size: .body1, color: .white.opacity(.mediumOpacity))
                    .lineSpacing(.lineSpacingMedium)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, .spacing3x)
            }

            if !services.isEmpty {
                VStack(alignment: .leading, spacing: .spacing2x) {
                    HStack(spacing: .spacing05x) {
                        Image(systemName: "list.clipboard")
                            .font(.standardSFPro(size: .body1, weight: .regular))

                        BrightText("Services", size: .body1, color: .white)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, .spacing3x)

                    ScrollView(.horizontal) {
                        HStack(spacing: .spacing105x) {
                            ForEach(services, id: \.self) { service in
                                BrightText(service, size: .body1, color: .white)
                                    .padding(.horizontal, .spacing105x)
                                    .frame(height: .spacing5x)
                                    .background(Color.white.opacity(.ultraLowOpacity), in: Capsule())
                                    .overlay(Capsule().strokeBorder(Color.white.opacity(.lowOpacity), lineWidth: Constants.stroke))
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .contentMargins(.horizontal, .spacing3x, for: .scrollContent)
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0.8),
                                .init(color: .clear, location: 1),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            }
        }
        .padding(.vertical, .spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(.ultraLowOpacity))
    }

    private var adBadge: some View {
        BrightText("Ad", size: .body1, color: .black)
            .padding(.horizontal, .spacing105x)
            .frame(height: .spacing4x)
            .background(Color.defaultAmber, in: Capsule())
    }

    private enum Constants {
        static let logoSize: CGFloat = 80
        static let stroke: CGFloat = 1
    }
}

// The wash behind an ad: its logo's own colour, deepening towards the bottom.
struct BrightAdBackdrop: View {
    let logo: String
    var image: UIImage? = nil
    // How far the top colour runs up past the edge, for a page pulled down past its top.
    var bleed: CGFloat = 0

    var body: some View {
        let tint = BrightAdTint.color(for: logo, image: image)
        let top = Color(tint.shaded(brightness: Constants.topBrightness))
        LinearGradient(
            colors: [top, Color(tint.shaded(brightness: Constants.bottomBrightness))],
            startPoint: .top,
            endPoint: .bottom
        )
        .background(alignment: .top) {
            top
                .frame(height: bleed)
                .offset(y: -bleed)
        }
    }

    private enum Constants {
        // Capped low enough for white text to read on the brightest artwork.
        static let topBrightness: CGFloat = 0.55
        static let bottomBrightness: CGFloat = 0.25
    }
}

// The artwork's most vivid colour, or its average when it has none, sampled
// once per image and kept.
@MainActor
private enum BrightAdTint {
    private static var cache: [String: UIColor] = [:]

    static func color(for imageName: String, image: UIImage? = nil) -> UIColor {
        let key = image.map { "\(imageName)#\(ObjectIdentifier($0).hashValue)" } ?? imageName
        if let cached = cache[key] { return cached }
        let color = sample(image ?? UIImage(named: imageName)) ?? .darkGray
        cache[key] = color
        return color
    }

    private static func sample(_ image: UIImage?) -> UIColor? {
        guard let cgImage = image?.cgImage else { return nil }
        let side = 24
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let drew = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: side,
                height: side,
                bitsPerComponent: 8,
                bytesPerRow: side * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        guard drew else { return nil }

        var vivid = (red: 0.0, green: 0.0, blue: 0.0, weight: 0.0)
        var average = (red: 0.0, green: 0.0, blue: 0.0, count: 0.0)
        for index in stride(from: 0, to: pixels.count, by: 4) {
            let alpha = Double(pixels[index + 3]) / 255
            guard alpha > 0.5 else { continue }
            let red = Double(pixels[index]) / 255 / alpha
            let green = Double(pixels[index + 1]) / 255 / alpha
            let blue = Double(pixels[index + 2]) / 255 / alpha
            average = (average.red + red, average.green + green, average.blue + blue, average.count + 1)

            let high = max(red, green, blue)
            let saturation = high == 0 ? 0 : (high - min(red, green, blue)) / high
            guard saturation > 0.25, high > 0.2 else { continue }
            let weight = saturation * saturation * high
            vivid = (vivid.red + red * weight, vivid.green + green * weight, vivid.blue + blue * weight, vivid.weight + weight)
        }

        if vivid.weight > 0 {
            return UIColor(red: vivid.red / vivid.weight, green: vivid.green / vivid.weight, blue: vivid.blue / vivid.weight, alpha: 1)
        }
        guard average.count > 0 else { return nil }
        return UIColor(red: average.red / average.count, green: average.green / average.count, blue: average.blue / average.count, alpha: 1)
    }
}

private extension UIColor {
    func shaded(brightness target: CGFloat) -> UIColor {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return UIColor(hue: hue, saturation: saturation, brightness: min(brightness, target), alpha: 1)
    }
}
