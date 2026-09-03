import SwiftUI

// Size/type preset for the border beam effect.
//
// Rotate family (traveling/spinning beam): `.sm`, `.md`, `.line`.
// Pulse family (breathing glow, no rotation): `.pulseOutside`, `.pulseInner`.
public enum BeamSize: String, CaseIterable, Sendable {
    case sm
    case md
    case line
    case pulseOutside = "pulse-outside"
    case pulseInner = "pulse-inner"

    public var isPulse: Bool { self == .pulseOutside || self == .pulseInner }
}

// Theme mode for adapting beam colors to the background.
public enum BeamTheme: String, CaseIterable, Sendable {
    case dark
    case light
    // Follows the SwiftUI `colorScheme` environment.
    case auto
}

// Color variant for the beam effect.
public enum BeamColorVariant: String, CaseIterable, Sendable {
    // The Bright palette (`Color+StylingExtensions`) across the ring — the
    // only variant whose blobs carry different hues.
    case brand
    // Single-hue takes on `brand`, shaded per blob so the ring still reads as a
    // sweep. The raw value keys the spec's palettes.
    case defaultOrange
    case defaultSkyBlue
    case defaultCyan
    // Adaptive pick with no palette of its own: the beam resolves it against
    // its theme — `defaultSkyBlue` over light, `defaultCyan` over dark —
    // because the spec's palettes are fixed CSS colours.
    case skyBlueCyan

    // The offerable variants: sky blue and cyan exist only as the palettes
    // `skyBlueCyan` resolves to, so they stay out of the list.
    public static var allCases: [BeamColorVariant] {
        [.brand, .defaultOrange, .skyBlueCyan]
    }

    // Every blob shares one hue, so a hue shift doesn't sweep the ring through
    // colours the way it does on `brand` — it just drags the single colour off
    // the brand hue.
    var isSingleHue: Bool {
        switch self {
        case .defaultOrange, .defaultSkyBlue, .defaultCyan, .skyBlueCyan: true
        case .brand: false
        }
    }

    // The variant whose palettes actually get read: `skyBlueCyan` stands in
    // for one of the two real palettes depending on the resolved theme.
    func resolved(forDark isDark: Bool) -> BeamColorVariant {
        guard self == .skyBlueCyan else { return self }
        return isDark ? .defaultCyan : .defaultSkyBlue
    }
}
