//
//  BrightSandMaskV5.swift
//  Widgets
//

import CoreGraphics
import CoreText
import Foundation

enum BrightSandMaskV5 {

    static let size = 420

    struct Random {
        private var a: UInt32
        init(seed: Int) {
            a = UInt32(truncatingIfNeeded: seed)
        }
        mutating func next() -> Double {
            a = a &+ 0x6d2b79f5
            var t = a
            t = (t ^ (t >> 15)) &* (t | 1)
            t ^= t &+ ((t ^ (t >> 7)) &* (t | 61))
            return Double((t ^ (t >> 14))) / 4294967296.0
        }
    }

    static func render(text: String, image: CGImage?) -> [UInt8] {
        let s = size
        var bytes = [UInt8](repeating: 0, count: s * s * 4)
        bytes.withUnsafeMutableBytes { raw in
            guard
                let ctx = CGContext(
                    data: raw.baseAddress,
                    width: s,
                    height: s,
                    bitsPerComponent: 8,
                    bytesPerRow: s * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )
            else { return }

            ctx.interpolationQuality = .low
            ctx.setShouldSubpixelPositionFonts(false)
            ctx.setShouldSubpixelQuantizeFonts(false)
            ctx.setShouldAntialias(true)

            let side = CGFloat(s)
            let c = side / 2

            if let image {
                let pad: CGFloat = 0.94
                let iw = CGFloat(image.width)
                let ih = CGFloat(image.height)
                let k = min(side * pad / iw, side * pad / ih)
                let w = iw * k
                let h = ih * k
                ctx.draw(image, in: CGRect(x: (side - w) / 2, y: (side - h) / 2, width: w, height: h))
            } else {
                let str = text.isEmpty ? "S" : text
                var pt = side * 0.8
                var font = bold(pt)
                var w = advance(str, font)
                if w > side * 0.88, w > 0 {
                    pt = pt * (side * 0.88) / w
                    font = bold(pt)
                    w = advance(str, font)
                }
                let ascent = CTFontGetAscent(font)
                let descent = CTFontGetDescent(font)
                let baselineFromTop = c + (ascent - descent) / 2
                ctx.textPosition = CGPoint(x: c - w / 2, y: side - baselineFromTop)
                ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
                CTLineDraw(line(str, font), ctx)
            }
        }
        unpremultiply(&bytes)
        return bytes
    }

    private static func unpremultiply(_ bytes: inout [UInt8]) {
        var o = 0
        while o < bytes.count {
            let a = Int(bytes[o + 3])
            if a > 0 && a < 255 {
                for c in 0..<3 {
                    bytes[o + c] = UInt8(min(255, (Int(bytes[o + c]) * 255 + a / 2) / a))
                }
            }
            o += 4
        }
    }

    private static func bold(_ pt: CGFloat) -> CTFont {
        let base = CTFontCreateUIFontForLanguage(.system, pt, nil)
            ?? CTFontCreateWithName("Helvetica" as CFString, pt, nil)
        return CTFontCreateCopyWithSymbolicTraits(base, pt, nil, .traitBold, .traitBold) ?? base
    }

    private static func line(_ s: String, _ font: CTFont) -> CTLine {
        let attrs = [kCTFontAttributeName as NSAttributedString.Key: font]
        return CTLineCreateWithAttributedString(
            NSAttributedString(string: s, attributes: attrs) as CFAttributedString
        )
    }

    private static func advance(_ s: String, _ font: CTFont) -> CGFloat {
        CGFloat(CTLineGetTypographicBounds(line(s, font), nil, nil, nil))
    }

    static func targets(count: Int, data: [UInt8], seed: Int) -> [Float] {
        let mask = size
        let n = mask * mask

        var opaque = 0
        var lumSum = 0.0
        var edgeLum = 0.0
        var edgeN = 0
        var q = 0
        while q < n {
            let o = q * 4
            if data[o + 3] > 200 {
                opaque += 1
                let l =
                    (Double(data[o]) * 0.299 + Double(data[o + 1]) * 0.587
                        + Double(data[o + 2]) * 0.114) / 255
                lumSum += l
                let x = q % mask
                let y = q / mask
                let lo = Double(mask) * 0.06
                let hi = Double(mask) * 0.94
                if Double(x) < lo || Double(x) > hi || Double(y) < lo || Double(y) > hi {
                    edgeLum += l
                    edgeN += 1
                }
            }
            q += 7
        }
        let sampled = Int((Double(n) / 7).rounded(.up))
        let useLum = Double(opaque) / Double(sampled) > 0.92
        let bgBright =
            edgeN != 0
            ? edgeLum / Double(edgeN) > 0.5 : lumSum / Double(max(1, opaque)) > 0.5

        func hit(_ o: Int) -> Bool {
            if !useLum { return data[o + 3] >= 140 }
            let l =
                (Double(data[o]) * 0.299 + Double(data[o + 1]) * 0.587 + Double(data[o + 2]) * 0.114)
                / 255
            return bgBright ? l < 0.55 : l > 0.45
        }

        var out = [Float](repeating: 0, count: count * 3)

        var anyInk = false
        for i in 0..<n where hit(i * 4) {
            anyInk = true
            break
        }

        let scale = 0.86
        var rng = Random(seed: seed)
        var i = 0
        var guardCount = anyInk ? 0 : count * 200
        while i < count && guardCount < count * 200 {
            guardCount += 1
            let px = Int(rng.next() * Double(mask))
            let py = Int(rng.next() * Double(mask))
            if !hit((py * mask + px) * 4) { continue }
            out[i * 3] = Float(((Double(px) / Double(mask)) * 2 - 1) * scale)
            out[i * 3 + 1] = Float((1 - (Double(py) / Double(mask)) * 2) * scale)
            out[i * 3 + 2] = Float(rng.next() - 0.5)
            i += 1
        }
        return out
    }

    static func morphAt(
        _ t: Double, scatterHold: Double, gatherTime: Double, shapeHold: Double,
        disperseTime: Double, loop: Bool
    ) -> Float {
        let a = max(0.1, scatterHold)
        let b = max(0.2, gatherTime)
        let c = max(0.1, shapeHold)
        let d = max(0.2, disperseTime)
        let cycle = a + b + c + d
        if !loop && t >= a + b + c { return 1 }
        var x = loop ? t.truncatingRemainder(dividingBy: cycle) : t
        if x < a { return 0 }
        x -= a
        if x < b {
            let k = x / b
            return Float(k * k * (3 - 2 * k))
        }
        x -= b
        if x < c { return 1 }
        x -= c
        let k = 1 - x / d
        return Float(k * k * (3 - 2 * k))
    }

    static func swingAt(
        _ t: Double, scatterHold: Double, gatherTime: Double, shapeHold: Double,
        disperseTime: Double, iconSpin: Double, loop: Bool
    ) -> Float {
        if !(iconSpin > 0) { return 0 }
        let a = max(0.1, scatterHold)
        let b = max(0.2, gatherTime)
        let c = max(0.1, shapeHold)
        let d = max(0.2, disperseTime)
        let cycle = a + b + c + d
        var x = loop ? t.truncatingRemainder(dividingBy: cycle) : t
        x -= a
        x -= b
        if x < 0 { return 0 }
        if loop && x >= c { return 0 }
        let swings = max(1, (iconSpin * c / Double.pi).rounded())
        return Float(sin(swings * Double.pi * (x / c)))
    }

    static func rgb(_ hex: String) -> SIMD3<Float> {
        var h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        if h.count == 3 { h = h.map { "\($0)\($0)" }.joined() }
        let head = h.prefix(6)
        let valid = head.prefix { $0.isHexDigit }
        guard !valid.isEmpty, let n = UInt32(valid, radix: 16) else { return SIMD3(1, 1, 1) }
        return SIMD3(
            Float((n >> 16) & 255) / 255, Float((n >> 8) & 255) / 255, Float(n & 255) / 255)
    }

    static func onLight(_ g: SIMD3<Float>) -> Bool {
        0.299 * g.x + 0.587 * g.y + 0.114 * g.z > 0.5
    }
}
