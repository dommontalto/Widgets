//
//  BeamControlsSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 6/8/2026.
//

import SwiftUI

// Do NOT port this file to the Bright iOS app — it's a tuning rig for dialling
// the beam in on device, reached from ContentView's sparkles button. What ports
// over is the result: the values it settles on, promoted to the defaults on
// `BrightScreenEdgeBeam`/`BorderBeam` and the beam spec.

struct BeamConfig {
    var colorVariant: BeamColorVariant = .defaultBlue
    var size: BeamSize = .md
    var isActive = true
    var duration = BrightScreenEdgeBeam.defaultDuration
    var brightness = BrightScreenEdgeBeam.defaultBrightness
    var strength: Double = 1
    var cornerRadius = BrightScreenEdgeBeam.defaultCornerRadius
    var saturation = BrightScreenEdgeBeam.defaultSaturation
    var renderScale = BrightScreenEdgeBeam.defaultRenderScale
    /// Multiplier on every layer's opacity. The web demo's tuned preset runs
    /// 1.71, which is what makes it read stronger than an untuned beam.
    var layerOpacity: Double = 1
    var glowBoost: Double = 1
    var glowBrightness: Double = 1
    var bloomBlur: Double = 0

    /// `BeamTuning` only reaches the pulse family — the rotate sizes take their
    /// prominence from brightness, saturation and spread instead.
    var tuning: BeamTuning {
        BeamTuning(
            glowBoost: glowBoost,
            strokeOpacity: layerOpacity,
            innerOpacity: layerOpacity,
            bloomOpacity: layerOpacity,
            bloomBlur: bloomBlur > 0 ? bloomBlur : nil,
            glowBrightness: brightness * glowBrightness,
            glowSaturate: saturation * glowBrightness
        )
    }

    static func screen(_ colorScheme: ColorScheme) -> BeamConfig {
        BeamConfig(glowBoost: glowBoost(for: colorScheme))
    }

    static func card(_ colorScheme: ColorScheme) -> BeamConfig {
        BeamConfig(
            colorVariant: .orange,
            size: .md,
            cornerRadius: CGFloat.cornerRadius24,
            glowBoost: glowBoost(for: colorScheme)
        )
    }

    /// A light background swallows the halo, so it needs far more boost than
    /// the same beam does on black.
    private static func glowBoost(for colorScheme: ColorScheme) -> Double {
        colorScheme == .light ? lightGlowBoost : 1
    }

    static let lightGlowBoost: Double = 5
}

/// Which of the screen's two beams the inline controls drive.
enum BeamTarget: String, CaseIterable, Identifiable {
    case screen
    case card

    var id: String { rawValue }

    var title: String {
        switch self {
        case .screen: "Screen"
        case .card: "Card"
        }
    }

    var symbol: String {
        switch self {
        case .screen: "rectangle.inset.filled"
        case .card: "rectangle.on.rectangle"
        }
    }

    var next: BeamTarget { self == .screen ? .card : .screen }
}

struct BeamControlsView: View {
    var defaults = BeamConfig()
    @Binding var config: BeamConfig

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: .spacing3x) {
                card {
                    BeamPicker("Colour", selection: $config.colorVariant, title: \.title)
                    BeamPicker("Shape", selection: $config.size, title: \.title)
                    Toggle(isOn: $config.isActive) {
                        BrightText("Active", size: .body3)
                    }
                    .tint(.defaultBrightGreen)
                }

                card {
                    BeamSlider("Duration", value: $config.duration, range: 0.5 ... 10)
                    BeamSlider("Brightness", value: $config.brightness, range: 0.5 ... 8)
                    BeamSlider("Saturation", value: $config.saturation, range: 0 ... 5)
                    BeamSlider("Opacity", value: $config.strength, range: 0 ... 1)
                }

                card {
                    BeamSlider("Layer Opacity", value: $config.layerOpacity, range: 0.5 ... 3)
                    BeamSlider("Glow Boost", value: $config.glowBoost, range: 0.5 ... 8)
                    BeamSlider("Glow Brightness", value: $config.glowBrightness, range: 0.5 ... 3)
                    BeamSlider("Bloom Blur", value: $config.bloomBlur, range: 0 ... 40)
                }

                card {
                    BeamSlider("Spread", value: $config.renderScale, range: 1 ... 6)
                    BeamSlider("Corner Radius", value: $config.cornerRadius, range: 0 ... 120)
                }

                BrightPillButton("Reset", color: .defaultBlue, buttonSize: .large) {
                    BrightHaptic.medium.play()
                    config = defaults
                }
            }
            .padding(.horizontal, .spacing3x)
            .padding(.bottom, .spacing4x)
        }
    }

    private func card(@ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: .spacing3x) {
            content()
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
    }
}

private struct BeamSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    init(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) {
        self.title = title
        _value = value
        self.range = range
    }

    var body: some View {
        VStack(spacing: .spacing05x) {
            HStack(spacing: .spacing2x) {
                BrightText(title, size: .body3)

                Spacer()

                BrightText(
                    value.formatted(.number.precision(.fractionLength(2))),
                    size: .body4,
                    color: Color.lightTextColor
                )
            }

            Slider(value: $value, in: range)
                .tint(.defaultBlue)
        }
    }
}

private struct BeamPicker<Value: Hashable & CaseIterable & Identifiable>: View
where Value.AllCases: RandomAccessCollection {
    let title: String
    @Binding var selection: Value
    let name: KeyPath<Value, String>

    init(_ title: String, selection: Binding<Value>, title name: KeyPath<Value, String>) {
        self.title = title
        _selection = selection
        self.name = name
    }

    var body: some View {
        HStack(spacing: .spacing2x) {
            BrightText(title, size: .body3)

            Spacer()

            Picker(title, selection: $selection) {
                ForEach(Value.allCases) { value in
                    Text(value[keyPath: name]).tag(value)
                }
            }
            .labelsHidden()
            .tint(.defaultBlue)
        }
    }
}

extension BeamColorVariant: Identifiable {
    public var id: String { rawValue }

    var title: String {
        switch self {
        case .brand: "Brand"
        case .orange: "Orange"
        case .defaultBlue: "Blue"
        }
    }
}

extension BeamSize: Identifiable {
    public var id: String { rawValue }

    var title: String {
        switch self {
        case .sm: "Small"
        case .md: "Medium"
        case .line: "Line"
        case .pulseOutside: "Pulse Outside"
        case .pulseInner: "Pulse Inner"
        }
    }
}
