//
//  ExerciseLibraryRow.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

struct ExerciseLibraryRow: View {
    let exercise: ExerciseDefinition
    var isAdded: Bool = false
    var onToggle: (() -> Void)?

    var body: some View {
        HStack(spacing: .spacing0x) {
            NavigationLink(value: ExerciseSessionRoute.exercise(exercise.name)) {
                HStack(spacing: .spacing2x) {
                    thumbnail

                    VStack(alignment: .leading, spacing: .spacing05x) {
                        BrightText(exercise.name, size: .body2, weight: .regular)
                            .fixedSize(horizontal: false, vertical: true)

                        BrightText(subtitle, size: .body3, color: .lightTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: .spacing2x)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                onToggle?()
            } label: {
                BrightTick(isTicked: isAdded, style: .plus)
                    .frame(width: Constants.tickTouchSize, height: Constants.tickTouchSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(onToggle == nil)
            .padding(.trailing, .spacing1x)
        }
        .padding(.spacing2x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .sheetModalCards))
    }

    private var thumbnail: some View {
        Image(systemName: exercise.category.symbol)
            .font(.standardSFPro(size: .standout4, weight: .light))
            .foregroundStyle(exercise.category.accentColor)
            .frame(width: Constants.thumbnailWidth)
    }

    private var subtitle: String {
        "\(exercise.primaryMuscle.displayName) \u{2022} \(exercise.equipmentLabel)"
    }

    private enum Constants {
        static let thumbnailWidth: CGFloat = 40
        static let tickTouchSize: CGFloat = 44
    }
}

#Preview {
    NavigationStack {
        ExerciseLibraryRow(exercise: ExerciseDemoLibrary.strength[0])
            .padding(.spacing4x)
    }
}
