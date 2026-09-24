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

    @State private var showsFile = false
    @State private var taps = 0

    var body: some View {
        Button {
            taps += 1
            withAnimation(.brightSnappy) { showsFile.toggle() }
        } label: {
            VStack(spacing: .spacing0x) {
                if !title.isEmpty {
                    BrightText(title, size: .subheading)
                }

                if showsFile {
                    BrightText(URL(filePath: file).lastPathComponent, size: .body6, color: .lightTextColor)
                        .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .task(id: taps) {
            guard showsFile else { return }
            // A fresh tap cancels this sleep; that tap's own window puts the file
            // name away rather than this one cutting it short on the way out.
            do { try await Task.sleep(for: .seconds(Constants.reveal)) } catch { return }
            withAnimation(.brightSnappy) { showsFile = false }
        }
    }

    private enum Constants {
        static let reveal: TimeInterval = 3
    }
}

#Preview {
    NavigationStack {
        Color.defaultBackground
            .ignoresSafeArea()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ExerciseInlineTitle(title: "Bench Press", file: #file)
                }
            }
    }
}
