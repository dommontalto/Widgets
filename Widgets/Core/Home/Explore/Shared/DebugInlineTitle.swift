//
//  DebugInlineTitle.swift
//  Widgets
//
//  Created by Dom Montalto on 4/8/2026.
//

import SwiftUI

struct DebugInlineTitle: View {
    var title = ""
    let file: String
    var titleFade: CGFloat = 1

    @State private var showsFile = false

    var body: some View {
        Group {
            if showsFile {
                BrightText(URL(filePath: file).lastPathComponent, size: .subheading, color: .lightTextColor)
            } else if !title.isEmpty {
                BrightText(title, size: .subheading)
                    .opacity(titleFade)
                    .blur(radius: (1 - titleFade) * 6)
                    .scaleEffect(1.15 - 0.15 * titleFade)
            } else {
                Color.clear
                    .frame(width: Constants.untitledWidth, height: Constants.untitledHeight)
            }
        }
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: Constants.holdDuration) {
            withAnimation(.brightSnappy) { showsFile = true }
        }
        .brightHapticV5(.light, trigger: showsFile)
        .task(id: showsFile) {
            guard showsFile else { return }
            do { try await Task.sleep(for: .seconds(Constants.reveal)) } catch { return }
            withAnimation(.brightSnappy) { showsFile = false }
        }
    }

    private enum Constants {
        static let holdDuration: TimeInterval = 2
        static let reveal: TimeInterval = 3
        static let untitledWidth: CGFloat = 160
        static let untitledHeight: CGFloat = 32
    }
}

#Preview {
    NavigationStack {
        Color.defaultBackground
            .ignoresSafeArea()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    DebugInlineTitle(title: "Bench Press", file: #file)
                }
            }
    }
}
