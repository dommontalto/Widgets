//
//  OrbloomTheme.swift
//  Widgets
//
//  Created by Dom Montalto on 14/9/2026.
//

import SwiftUI

// The sky the orb paints: which procedural galaxy shape the shader draws.
// Raw values are the shader's `archetype` selector.
enum OrbloomArchetype: Int, CaseIterable, Sendable {
    case spiral = 0
    case nebula = 1
    case core = 2
    case deepField = 3
}

// Product states the orb can reflect. Raw values are the shader's `state`
// selector; `speaking` shares idle's look and is driven by audio instead.
enum OrbloomState: Int, CaseIterable, Sendable {
    case idle = 0
    case listening = 1
    case thinking = 2
    case speaking = 3
    case success = 4
    case error = 5
}

// Frame-rate and resolution ceilings, matching the site's rendering profiles.
enum OrbloomQuality: Sendable {
    case low
    case balanced
    case high

    var frameRate: Double {
        switch self {
        case .low: 30
        case .balanced: 45
        case .high: 60
        }
    }

    var maxPixelRatio: CGFloat {
        switch self {
        case .low: 1
        case .balanced: 1.5
        case .high: 2
        }
    }

    var maxResolution: CGFloat {
        switch self {
        case .low: 512
        case .balanced: 896
        case .high: 1280
        }
    }
}

// The slow bob the whole orb makes: a CSS `translateY` + `scale` keyframe
// that eases out and back over `duration`, starting after `delay`.
struct OrbloomAmbientMotion: Sendable {
    var isEnabled: Bool
    var verticalTravel: CGFloat
    var scale: CGFloat
    var duration: TimeInterval
    var delay: TimeInterval

    static let off = OrbloomAmbientMotion(isEnabled: false, verticalTravel: 0, scale: 1, duration: 0, delay: 0)
    static let standard = OrbloomAmbientMotion(isEnabled: true, verticalTravel: 8, scale: 1, duration: 7, delay: 0)

    func with(verticalTravel: CGFloat) -> OrbloomAmbientMotion {
        var copy = self
        copy.verticalTravel = verticalTravel
        return copy
    }
}

struct OrbloomAppearance: Sendable {
    var detail: Double = 1
    var glow: Double = 1
    var intensity: Double = 1
}

struct OrbloomMotionTuning: Sendable {
    var drift: Double = 1
    var speed: Double = 1
}

struct OrbloomAudioResponse: Sendable {
    var brightness: Double = 1
    var motion: Double = 1
    var pulse: Double = 1
}

// A fully resolved orb look. Colours are linear 0…1 RGB ready for the shader.
struct OrbloomTheme: Identifiable, Sendable {
    let id: String
    let archetype: OrbloomArchetype
    // The seed every hash and phase in the shader keys off. Radians.
    let phase: Double
    let interiorColor: SIMD3<Float>
    let baseColor: SIMD3<Float>
    let accentPrimary: SIMD3<Float>
    let accentSecondary: SIMD3<Float>
    let accentHighlight: SIMD3<Float>
    // Strength of the chromatic lens along the rim. 0 disables it and the
    // back-face sample with it, which is what the site's small orbs do.
    let lensStrength: Double
    let ambientMotion: OrbloomAmbientMotion
    // The diameter the preset was tuned at on the site.
    let referenceDiameter: CGFloat
    var appearance = OrbloomAppearance()
    var motion = OrbloomMotionTuning()
    var audioResponse = OrbloomAudioResponse()

    var accentColors: [SIMD3<Float>] {
        [accentPrimary, accentSecondary, accentHighlight]
    }

    init(
        id: String,
        archetype: OrbloomArchetype,
        phase: Double,
        baseColor: String,
        accentColors: [String],
        referenceDiameter: CGFloat = Constants.defaultReferenceDiameter,
        lensStrength: Double? = nil,
        ambientMotion: OrbloomAmbientMotion = .standard,
        interiorColor: String = "#000000"
    ) {
        precondition(accentColors.count == 3, "Orbloom themes carry exactly three accents.")
        self.id = id
        self.archetype = archetype
        self.phase = phase
        self.interiorColor = Self.rgb(interiorColor)
        self.baseColor = Self.rgb(baseColor)
        self.accentPrimary = Self.rgb(accentColors[0])
        self.accentSecondary = Self.rgb(accentColors[1])
        self.accentHighlight = Self.rgb(accentColors[2])
        // Below the lens threshold the site falls back to the compact profile.
        self.lensStrength = lensStrength
            ?? (referenceDiameter >= Constants.lensMinimumDiameter ? Constants.defaultLensStrength : 0)
        self.ambientMotion = ambientMotion
        self.referenceDiameter = referenceDiameter
    }

    private static func rgb(_ hex: String) -> SIMD3<Float> {
        var digits = Substring(hex)
        if digits.hasPrefix("#") { digits = digits.dropFirst() }
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return .zero }
        return SIMD3(
            Float((value >> 16) & 0xFF) / 255,
            Float((value >> 8) & 0xFF) / 255,
            Float(value & 0xFF) / 255
        )
    }

    enum Constants {
        static let defaultReferenceDiameter: CGFloat = 264
        static let lensMinimumDiameter: CGFloat = 48
        static let defaultLensStrength: Double = 0.4
    }
}

// MARK: - Presets

extension OrbloomTheme {
    static let `default` = coreTeal01

    static let all: [OrbloomTheme] = [
        coreTeal01, spiralPink01, nebulaPink01, spiralCyan01, spiralCyan02, nebulaViolet01,
        coreBlue01, spiralOrange01, nebulaCyan01, coreCyan01, coreLime01,
        nebulaOrange01, coreBlue02, deepFieldCyan01, deepFieldGreen01, coreRed01, coreOrange01,
        deepFieldBlue01, nebulaBlue01, spiralViolet01, deepFieldYellow01, coreYellow01, coreOrange02,
        deepFieldTeal01, spiralCyan03, spiralBlue01, spiralCyan04, nebulaRed01, deepFieldOrange01,
        coreLime02, nebulaYellow01, spiralOrange02, nebulaOrange02, deepFieldBlue02, nebulaViolet02,
        deepFieldTeal02,
    ].sorted { $0.id < $1.id }

    static func preset(id: String) -> OrbloomTheme {
        all.first { $0.id == id } ?? .default
    }

    private static let floatingGently = OrbloomAmbientMotion(
        isEnabled: true, verticalTravel: 5, scale: 1.03, duration: 6.5, delay: 0
    )

    static let coreTeal01 = OrbloomTheme(
        id: "core-teal-01", archetype: .core, phase: 4.6,
        baseColor: "#07262B", accentColors: ["#00C2A8", "#38E1FF", "#FFC65C"],
        referenceDiameter: 264, ambientMotion: .standard.with(verticalTravel: 10)
    )
    static let spiralPink01 = OrbloomTheme(
        id: "spiral-pink-01", archetype: .spiral, phase: 6.05,
        baseColor: "#2A0F22", accentColors: ["#FF7ECB", "#D14FFF", "#FFDCF2"],
        referenceDiameter: 244, ambientMotion: floatingGently
    )
    static let nebulaPink01 = OrbloomTheme(
        id: "nebula-pink-01", archetype: .nebula, phase: 4.083,
        baseColor: "#241627", accentColors: ["#FFC9E0", "#E4A8FF", "#FFE9F4"],
        referenceDiameter: 186,
        ambientMotion: OrbloomAmbientMotion(isEnabled: true, verticalTravel: 5, scale: 1.03, duration: 7.8, delay: 0.4)
    )
    static let spiralCyan01 = OrbloomTheme(
        id: "spiral-cyan-01", archetype: .spiral, phase: 1.285,
        baseColor: "#0A1B2E", accentColors: ["#38BDF8", "#0E7BD1", "#CFF2FF"],
        referenceDiameter: 150,
        ambientMotion: OrbloomAmbientMotion(isEnabled: true, verticalTravel: 5, scale: 1.03, duration: 9.1, delay: 0.8)
    )
    static let spiralCyan02 = OrbloomTheme(
        id: "spiral-cyan-02", archetype: .spiral, phase: 2.502,
        baseColor: "#101B2E", accentColors: ["#7DBED4", "#6E8BFF", "#A24DFF"],
        referenceDiameter: 208, ambientMotion: .standard.with(verticalTravel: 9)
    )
    static let nebulaViolet01 = OrbloomTheme(
        id: "nebula-violet-01", archetype: .nebula, phase: 1.995,
        baseColor: "#1C0A2B", accentColors: ["#A24DFF", "#FF4DD8", "#6E8BFF"],
        referenceDiameter: 260, ambientMotion: .standard.with(verticalTravel: 9)
    )
    static let coreBlue01 = OrbloomTheme(
        id: "core-blue-01", archetype: .core, phase: 5.016,
        baseColor: "#131A2E", accentColors: ["#2563EB", "#FF2D87", "#FFD086"],
        referenceDiameter: 42, lensStrength: 0
    )
    static let spiralOrange01 = OrbloomTheme(
        id: "spiral-orange-01", archetype: .spiral, phase: 2.289,
        baseColor: "#5C4030", accentColors: ["#D86A3D", "#FFB873", "#FFE3C2"],
        referenceDiameter: 42, lensStrength: 0
    )
    static let nebulaCyan01 = OrbloomTheme(
        id: "nebula-cyan-01", archetype: .nebula, phase: 0.432,
        baseColor: "#2E4250", accentColors: ["#7DBED4", "#C5A8E8", "#F4F4F8"],
        referenceDiameter: 42, lensStrength: 0
    )
    static let coreCyan01 = OrbloomTheme(
        id: "core-cyan-01", archetype: .core, phase: 1.573,
        baseColor: "#0A2438", accentColors: ["#3DA5D9", "#5FC9D8", "#A6E5E5"],
        referenceDiameter: 42, lensStrength: 0
    )
    static let coreLime01 = OrbloomTheme(
        id: "core-lime-01", archetype: .core, phase: 1.542,
        baseColor: "#1A3A20", accentColors: ["#7BAE48", "#A8B85C", "#F4E4A8"],
        referenceDiameter: 42, lensStrength: 0
    )
    static let nebulaOrange01 = OrbloomTheme(
        id: "nebula-orange-01", archetype: .nebula, phase: 0.108,
        baseColor: "#301608", accentColors: ["#FFB25C", "#FF7E45", "#FFE9CE"]
    )
    static let coreBlue02 = OrbloomTheme(
        id: "core-blue-02", archetype: .core, phase: 4.401,
        baseColor: "#0E1A34", accentColors: ["#5C8DFF", "#3452D9", "#DCE8FF"]
    )
    static let deepFieldCyan01 = OrbloomTheme(
        id: "deep-field-cyan-01", archetype: .deepField, phase: 5.402,
        baseColor: "#0F2024", accentColors: ["#5FB7C4", "#33808F", "#DDF4F7"]
    )
    static let deepFieldGreen01 = OrbloomTheme(
        id: "deep-field-green-01", archetype: .deepField, phase: 1.89,
        baseColor: "#0C2414", accentColors: ["#57D98A", "#2FA05C", "#DFFBE9"]
    )
    static let coreRed01 = OrbloomTheme(
        id: "core-red-01", archetype: .core, phase: 1.577,
        baseColor: "#2A0A10", accentColors: ["#FF3B4E", "#B01C3A", "#FF9860"]
    )
    static let coreOrange01 = OrbloomTheme(
        id: "core-orange-01", archetype: .core, phase: 0.287,
        baseColor: "#301004", accentColors: ["#FF7A18", "#FFB340", "#FF4E2A"]
    )
    static let deepFieldBlue01 = OrbloomTheme(
        id: "deep-field-blue-01", archetype: .deepField, phase: 2.619,
        baseColor: "#0E1230", accentColors: ["#8FA8FF", "#5B6CFF", "#E8ECFF"]
    )
    static let nebulaBlue01 = OrbloomTheme(
        id: "nebula-blue-01", archetype: .nebula, phase: 0.484,
        baseColor: "#1B1E33", accentColors: ["#C7CFFF", "#9FB4E8", "#F2F4FF"]
    )
    static let spiralViolet01 = OrbloomTheme(
        id: "spiral-violet-01", archetype: .spiral, phase: 5.961,
        baseColor: "#221434", accentColors: ["#C084FC", "#F0A6FF", "#FFD1EC"]
    )
    static let deepFieldYellow01 = OrbloomTheme(
        id: "deep-field-yellow-01", archetype: .deepField, phase: 2.497,
        baseColor: "#171310", accentColors: ["#E8C98A", "#B08A50", "#FFF2D8"]
    )
    static let coreYellow01 = OrbloomTheme(
        id: "core-yellow-01", archetype: .core, phase: 0.224,
        baseColor: "#2E1E04", accentColors: ["#FFD54A", "#FFB300", "#FFF3B0"]
    )
    static let coreOrange02 = OrbloomTheme(
        id: "core-orange-02", archetype: .core, phase: 4.701,
        baseColor: "#2E1408", accentColors: ["#FF8A4C", "#FFC24B", "#FF5E62"]
    )
    static let deepFieldTeal01 = OrbloomTheme(
        id: "deep-field-teal-01", archetype: .deepField, phase: 1.778,
        baseColor: "#0A2220", accentColors: ["#63D8C2", "#2E9E8C", "#DFFCF4"]
    )
    static let spiralCyan03 = OrbloomTheme(
        id: "spiral-cyan-03", archetype: .spiral, phase: 3.465,
        baseColor: "#101632", accentColors: ["#4CC9F0", "#7B5CFF", "#B8F1FF"]
    )
    static let spiralBlue01 = OrbloomTheme(
        id: "spiral-blue-01", archetype: .spiral, phase: 1.258,
        baseColor: "#141B26", accentColors: ["#7FA6C9", "#4A7196", "#DCE8F2"]
    )
    static let spiralCyan04 = OrbloomTheme(
        id: "spiral-cyan-04", archetype: .spiral, phase: 0.825,
        baseColor: "#0E2030", accentColors: ["#4FC3F7", "#8BE38B", "#E1F7FF"]
    )
    static let nebulaRed01 = OrbloomTheme(
        id: "nebula-red-01", archetype: .nebula, phase: 1.692,
        baseColor: "#2A1418", accentColors: ["#FF9DA0", "#FFC6A8", "#FFE8E0"]
    )
    static let deepFieldOrange01 = OrbloomTheme(
        id: "deep-field-orange-01", archetype: .deepField, phase: 2.167,
        baseColor: "#221408", accentColors: ["#D9A05B", "#A0693A", "#FFE0B8"]
    )
    static let coreLime02 = OrbloomTheme(
        id: "core-lime-02", archetype: .core, phase: 3.431,
        baseColor: "#12240E", accentColors: ["#9BE84C", "#3ED598", "#EAFFC9"]
    )
    static let nebulaYellow01 = OrbloomTheme(
        id: "nebula-yellow-01", archetype: .nebula, phase: 1.461,
        baseColor: "#26200C", accentColors: ["#FFE08A", "#F4C14F", "#FFF8E0"]
    )
    static let spiralOrange02 = OrbloomTheme(
        id: "spiral-orange-02", archetype: .spiral, phase: 1.878,
        baseColor: "#26160C", accentColors: ["#E88B4E", "#C9653A", "#F7D9B8"]
    )
    static let nebulaOrange02 = OrbloomTheme(
        id: "nebula-orange-02", archetype: .nebula, phase: 0.365,
        baseColor: "#251106", accentColors: ["#FFAD33", "#E86A2C", "#FFE2A8"]
    )
    static let deepFieldBlue02 = OrbloomTheme(
        id: "deep-field-blue-02", archetype: .deepField, phase: 0.757,
        baseColor: "#14161C", accentColors: ["#9AA6B8", "#5E6B80", "#E6ECF5"]
    )
    static let nebulaViolet02 = OrbloomTheme(
        id: "nebula-violet-02", archetype: .nebula, phase: 3.978,
        baseColor: "#1A1430", accentColors: ["#A78BFA", "#F0ABFC", "#E0E7FF"]
    )
    static let deepFieldTeal02 = OrbloomTheme(
        id: "deep-field-teal-02", archetype: .deepField, phase: 6.142,
        baseColor: "#0F1F24", accentColors: ["#5EEAD4", "#99F6E4", "#E0F2FE"]
    )
}
