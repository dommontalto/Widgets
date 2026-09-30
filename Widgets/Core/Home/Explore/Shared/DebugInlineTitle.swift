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
    // Lets a page fade and blur the title in as it scrolls, without hiding the
    // file name once it has been tapped out.
    var titleFade: CGFloat = 1

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
                        .opacity(titleFade)
                        .blur(radius: (1 - titleFade) * 6)
                        .scaleEffect(1.15 - 0.15 * titleFade)
                }

                if showsFile {
                    BrightText(URL(filePath: file).lastPathComponent, size: .body6, color: .lightTextColor)
                        .transition(.opacity)
                }
            }
            // Untitled pages still need something at the top to tap.
            .frame(minWidth: Constants.minTapWidth, minHeight: Constants.minTapHeight)
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
        static let minTapWidth: CGFloat = 160
        static let minTapHeight: CGFloat = 32
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
