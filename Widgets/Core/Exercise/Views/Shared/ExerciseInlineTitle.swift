//
//  ExerciseInlineTitle.swift
//  Widgets
//
//  Created by Dom Montalto on 4/8/2026.
//

import SwiftUI

struct ExerciseInlineTitle: View {
    var title = ""
    let file: String

    var body: some View {
        VStack(spacing: .spacing0x) {
            if !title.isEmpty {
                BrightText(title, size: .subheading)
            }

            BrightText(URL(filePath: file).lastPathComponent, size: .body6, color: .lightTextColor)
        }
    }
}

#Preview {
    NavigationStack {
        Color.defaultSheetBackground
            .ignoresSafeArea()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(title: "Bench Press", file: #file)
                }
            }
    }
}
