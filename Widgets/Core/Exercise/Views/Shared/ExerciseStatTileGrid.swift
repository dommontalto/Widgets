//
//  ExerciseStatTileGrid.swift
//  Widgets
//
//  Created by Dom Montalto on 4/8/2026.
//

import SwiftUI

nonisolated struct ExerciseStatTile: Identifiable {
    let label: String
    let value: String
    let unit: String
    let symbol: String
    let color: Color

    var id: String { label }
}

struct ExerciseStatTileGrid: View {
    let tiles: [ExerciseStatTile]
    var cardColor: Color = .defaultSheetModalCards

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Constants.gridSpacing), count: 2),
            spacing: Constants.gridSpacing
        ) {
            ForEach(tiles) { tile in
                ExerciseStatTileView(tile: tile, cardColor: cardColor)
            }
        }
    }

    private enum Constants {
        static let gridSpacing: CGFloat = .spacing2x + .spacing05x
    }
}

struct ExerciseStatTileView: View {
    let tile: ExerciseStatTile
    var cardColor: Color = .defaultSheetModalCards

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            Image(systemName: tile.symbol)
                .font(.system(size: Constants.iconSize, weight: .regular))
                .foregroundStyle(tile.color)

            BrightText(tile.label, size: .body2)

            Spacer(minLength: .spacing0x)

            HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                BrightText(tile.value, size: .huge3)
                    .monospacedDigit()

                BrightText(tile.unit, size: .subheading, color: .lightTextColor)
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(1, contentMode: .fit)
        .modifier(CardModifier(color: cardColor))
    }

    private enum Constants {
        static let iconSize: CGFloat = 18
    }
}

#Preview {
    ExerciseStatTileGrid(tiles: ExerciseDemoData.detailStats)
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.defaultSheetBackground.ignoresSafeArea())
}
