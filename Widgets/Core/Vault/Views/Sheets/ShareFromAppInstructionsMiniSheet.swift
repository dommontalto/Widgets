//
//  ShareFromAppInstructionsMiniSheet.swift
//  Widgets
//
//

import SwiftUI

// Instructional partial sheet explaining how to share files into Bright from third-party
// storage apps (Google Drive, Azure, OneDrive, Dropbox, etc.) via the iOS Share sheet.
struct ShareFromAppInstructionsMiniSheet: View {
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            BrightText("Import from app", size: .heading)
                .padding(.top, .spacing6x)

            BrightText(
                "You can send documents into Bright directly from Google Drive, Azure Storage, OneDrive, Dropbox, and most other storage apps.",
                size: .body1,
                color: .lightTextColor
            )

            VStack(alignment: .leading, spacing: .spacing2x) {
                step(number: 1, text: "Open the app where your document is stored.")
                step(number: 2, text: "Tap the file, then tap the Share button.")
                step(number: 3, text: "Choose Bright from the Share sheet.")
                step(number: 4, text: "Bright will receive and add to your Vault.")
            }

            BrightText(
                "If Bright doesn't appear in the Share sheet, tap \"More…\" and enable it.",
                size: .body1,
                color: .lightTextColor
            )
        }
        .padding(.horizontal, .spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) {
            BrightRoundButton(systemImage: "xmark", size: .large) {
                onClose()
            }
            .padding(.top, .spacing3x)
            .padding(.trailing, .spacing3x)
        }
    }

    private func step(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: .spacing2x) {
            BrightText("\(number).", size: .body1, weight: .medium)
                .frame(width: 22, alignment: .leading)
            BrightText(text, size: .body1)
                .multilineTextAlignment(.leading)
        }
    }
}
