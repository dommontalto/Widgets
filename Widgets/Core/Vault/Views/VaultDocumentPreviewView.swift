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

    private var url: URL? { VaultDemo.documentURL(for: document) }

    var body: some View {
        ZStack {
            Color.defaultSheetBackground.ignoresSafeArea()

            if let url {
                if document.fileType == .dicom {
                    BrightDICOMViewerV5(url: url) {
                        removeButton
                            .frame(maxWidth: .infinity)
                            .padding(.top, .spacing2x)
                    }
                } else {
                    VStack(spacing: .spacing2x) {
                        BrightPDFViewerV5(url: url)
                            .padding(.horizontal, .spacing3x)
                        removeButton
                            .padding(.bottom, .spacing2x)
                    }
                }
            }
        }
        .brightSoftScrollEdgesV5()
        .navigationTitle(document.labName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let url {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: url, preview: SharePreview(document.labName)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share")
                }
            }
        }
    }

    private var removeButton: some View {
        BrightPillButton("Remove Document", systemImage: "trash", color: .defaultRed.opacity(.veryMinimalOpacity), textColor: .defaultRed, buttonSize: .large) {
            dismiss()
        }
    }
}
