//
//  VaultDocumentPreviewView.swift
//  Widgets
//
//  Created by Dom Montalto on 5/11/2026.
//

import SwiftUI

struct VaultDocumentPreviewView: View {
    let document: VaultDocumentSummary

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.defaultSheetBackground.ignoresSafeArea()

            if let url = VaultDemo.documentURL {
                BrightPDFViewerV5(url: url)
                    .padding(.horizontal, .spacing3x)
            }
        }
        .brightSoftScrollEdgesV5()
        .navigationTitle(document.labName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let url = VaultDemo.documentURL {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: url, preview: SharePreview(document.labName)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            BrightPillButton("Remove Document", color: .defaultRed, buttonSize: .large) {
                dismiss()
            }
            .padding(.bottom, .spacing2x)
        }
    }
}
