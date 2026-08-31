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
        }
        .padding(.spacing2x)
        .frame(maxWidth: .infinity, minHeight: Constants.minHeight, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    private var thumbnail: some View {
        Image(systemName: exercise.symbol)
            .font(.standard(size: .standout3, weight: .light))
            .foregroundStyle(Color.lightTextColor)
            .frame(width: Constants.thumbnailWidth)
    }

    private var subtitle: String {
        "\(exercise.primaryMuscle.displayName) \u{2022} \(exercise.equipmentLabel)"
    }

    enum Constants {
        static let thumbnailWidth: CGFloat = 40
        static let tickTouchSize: CGFloat = 44
        static let minHeight = tickTouchSize + 2 * CGFloat.spacing2x
    }
}

#Preview {
    NavigationStack {
        ExerciseLibraryRow(exercise: ExerciseDemoLibrary.strength[0])
            .padding(.spacing4x)
    }
}
