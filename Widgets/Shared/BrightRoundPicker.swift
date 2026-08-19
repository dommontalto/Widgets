//
//  BrightRoundPicker.swift
//  Widgets
//
//  Created by Dom Montalto on 11/8/2026.
//

import SwiftUI

struct BrightRoundPickerIcon: Identifiable, Hashable {
    let id: String
    let symbol: String
    var accentColor: Color = .textColor
}

struct BrightRoundPicker: View {
    let icons: [BrightRoundPickerIcon]

    @Binding var selection: BrightRoundPickerIcon

    // A row that shares its line with a label has to come down from the default
    // tile size or it runs past the screen margin.
    var size: BrightButtonSizes = .medium
    var tileGap: CGFloat = Constants.tileGap

    @Namespace private var pickerSpace

    private var tile: CGFloat { size.rawValue }

    var body: some View {
        HStack(spacing: tileGap) {
            ForEach(icons) { icon in
                tileView(icon)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .leading) {
            Color.clear
                .frame(width: tile, height: tile)
                .modifier(GlassEffect(shape: .circle))
                .matchedGeometryEffect(id: selection, in: pickerSpace, isSource: false)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    select(at: value.location.x)
                }
        )
        .brightHaptic(.light, trigger: selection)
        .animation(.brightSnappy, value: selection)
    }

    private func tileView(_ icon: BrightRoundPickerIcon) -> some View {
        Image(systemName: icon.symbol)
            .font(.standard(size: size.defaultFontSize, weight: .light))
            .foregroundStyle(icon == selection ? icon.accentColor : .semiLightTextColor)
            .frame(width: tile, height: tile)
            .background {
                Circle()
                    .fill(Color.defaultMainGrey.opacity(.finalBossLowOpacity))
            }
            .matchedGeometryEffect(id: icon, in: pickerSpace)
    }

    // One gesture drives both tap and drag, so the glass follows the finger
    // across the row instead of jumping between taps.
    private func select(at x: CGFloat) {
        let slot = tile + tileGap
        let index = min(max(0, Int(x / slot)), icons.count - 1)
        guard icons[index] != selection else { return }
        selection = icons[index]
    }

    enum Constants {
        static let tileGap: CGFloat = .spacing2x
    }
}

#Preview {
    @Previewable @State var selection = BrightRoundPickerIcon(id: "run", symbol: "figure.run")

    BrightRoundPicker(
        icons: [
            BrightRoundPickerIcon(id: "warmup", symbol: "figure.cooldown"),
            BrightRoundPickerIcon(id: "run", symbol: "figure.run"),
            BrightRoundPickerIcon(id: "walk", symbol: "figure.walk"),
            BrightRoundPickerIcon(id: "cool", symbol: "snowflake"),
            BrightRoundPickerIcon(id: "finish", symbol: "flag.pattern.checkered"),
        ],
        selection: $selection
    )
    .padding(.spacing3x)
}
