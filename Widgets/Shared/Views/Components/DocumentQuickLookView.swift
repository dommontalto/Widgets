//
//  DocumentQuickLookView.swift
//  Widgets
//
//

import QuickLook
import SwiftUI
import UniformTypeIdentifiers

// Downloads a remote document to a temp file and previews it with QuickLook,
// which natively renders CSV, DOCX, PDF, images and more — the formats
// `BrightPDFViewerV5`/`AsyncImage` can't handle.
struct DocumentQuickLookView: View {
    let url: URL
    var mimeType: String?

    @State private var localURL: URL?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let localURL {
                QuickLookRepresentable(url: localURL)
                    .transition(.opacity)
            } else if failed {
                unavailable
                    .transition(.opacity)
            }
        }
        .animation(.brightEaseInOut, value: localURL)
        .animation(.brightEaseInOut, value: failed)
        .task(id: url) {
            failed = false
            localURL = nil
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                let ext = Self.fileExtension(mimeType: mimeType, response: response, url: url)
                let dest = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(ext)
                // Keep the disk write off the main actor.
                try await Task.detached(priority: .utility) {
                    try data.write(to: dest)
                }.value
                localURL = dest
            } catch {
                print("Vault: QuickLook download failed - \(error.localizedDescription)")
                failed = true
            }
        }
    }

    private var unavailable: some View {
        VStack(spacing: .spacing2x) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.defaultOrange)
            BrightText("Couldn't load document", size: .body1, weight: .medium)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // QuickLook keys off the file extension, so resolve the best one from the
    // known mime, then the response mime, then the URL.
    private static func fileExtension(mimeType: String?, response: URLResponse, url: URL) -> String {
        if let mimeType, let ext = UTType(mimeType: mimeType)?.preferredFilenameExtension {
            return ext
        }
        if let mime = response.mimeType, let ext = UTType(mimeType: mime)?.preferredFilenameExtension {
            return ext
        }
        if !url.pathExtension.isEmpty {
            return url.pathExtension
        }
        return "dat"
    }
}

private struct QuickLookRepresentable: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: QLPreviewController, context: Context) {
        guard context.coordinator.url != url else { return }
        context.coordinator.url = url
        controller.reloadData()
    }

    func makeCoordinator() -> Coordinator { Coordinator(url: url) }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        var url: URL
        init(url: URL) { self.url = url }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}
