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
    // sweep: `defaultOrange` and `defaultBlue`.
    case orange
    case defaultBlue

    // Every blob shares one hue, so a hue shift doesn't sweep the ring through
    // colours the way it does on `brand` — it just drags the single colour off
    // the brand hue.
    var isSingleHue: Bool {
        switch self {
        case .orange, .defaultBlue: true
        case .brand: false
        }
    }
}
