//
//  RowCircleIcon.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

struct RowCircleIcon: View {
    let color: Color

    var body: some View {
        Circle()
            .stroke(color, lineWidth: Constants.strokeWidth)
            .fill(color.opacity(.veryMinimalOpacity))
            .frame(width: Constants.diameter, height: Constants.diameter)
    }

    private enum Constants {
        static let diameter: CGFloat = 8
        static let strokeWidth: CGFloat = 1.67
    }
}
