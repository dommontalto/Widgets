//
//  ExerciseCategoryCircle.swift
//  Widgets
//
//  Created by Dom Montalto on 7/9/2026.
//

import SwiftUI

struct ExerciseCategoryCircle: View {
    let category: ExerciseCategory
    var ringColor: Color = .defaultCards

    var body: some View {
        Circle()
            .fill(category.tint.opacity(.minimalOpacity))
            .overlay {
                Image(systemName: category.symbol)
                    .font(.standardSFPro(size: .subheading2, weight: .light))
                    .foregroundStyle(category.tint)
            }
            .frame(width: Constants.size, height: Constants.size)
            .padding(Constants.ringWidth)
            .background(ringColor, in: Circle())
    }

    enum Constants {
        static let size: CGFloat = .spacing6x
        static let ringWidth: CGFloat = .spacing05x
        static let overlap: CGFloat = .spacing105x
    }
}

struct ExerciseCategoryCircleStack: View {
    let categories: [ExerciseCategory]
    var ringColor: Color = .defaultCards

    var body: some View {
        HStack(spacing: -ExerciseCategoryCircle.Constants.overlap) {
            ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                ExerciseCategoryCircle(category: category, ringColor: ringColor)
                    .zIndex(Double(categories.count - index))
            }
        }
    }
}

#Preview {
    VStack(spacing: .spacing4x) {
        HStack(spacing: .spacing2x) {
            ForEach(ExerciseCategory.allCases) { category in
                ExerciseCategoryCircle(category: category)
            }
        }

        ExerciseCategoryCircleStack(categories: [.gym, .cardio])
        ExerciseCategoryCircleStack(categories: [.sports, .bodyweight, .cardio])
    }
    .padding(.spacing4x)
    .modifier(CardModifier())
    .padding(.spacing4x)
    .frame(maxHeight: .infinity)
    .background(Color.defaultBackground.ignoresSafeArea())
}
