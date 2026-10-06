//
//  BrightPDFViewerV5.swift
//  Widgets
//
//

import PDFKit
import SwiftUI

// SwiftUI wrapper over `PDFView` that downloads + renders a remote PDF from a URL.
// Gives native pinch-zoom, multi-page scrolling, and text selection.
struct BrightPDFViewerV5: View {
    let url: URL

    @State private var document: PDFDocument?
    @State private var loadError: String?

    var body: some View {
        ZStack {
            if let document {
                PDFKitRepresentable(document: document)
                    .transition(.opacity)
            } else if let loadError {
                VStack(spacing: .spacing2x) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(Color.defaultOrange)
                    BrightText("Couldn't load preview", size: .body1, weight: .medium)
                    BrightText(loadError, size: .body5, color: .lightTextColor)
                        .multilineTextAlignment(.center)
                }
                .padding(.spacing4x)
                .transition(.opacity)
            }
        }
        .animation(.brightEaseInOut, value: document)
        .animation(.brightEaseInOut, value: loadError)
        .task(id: url) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let doc = PDFDocument(data: data) {
                    document = doc
                } else {
                    loadError = "File is not valid."
                }
            } catch {
                loadError = error.localizedDescription
            }
        }
    }
}

private struct PDFKitRepresentable: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = UIColor(Color.defaultSheetBackground)
        view.pageShadowsEnabled = false
        view.document = document
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document !== document {
            uiView.document = document
        }
        DispatchQueue.main.async {
            disableZoom(in: uiView)
        }
    }

    private func disableZoom(in view: UIView) {
        if let scrollView = view as? UIScrollView {
            scrollView.pinchGestureRecognizer?.isEnabled = false
            scrollView.bouncesZoom = false
            scrollView.maximumZoomScale = scrollView.zoomScale
            scrollView.minimumZoomScale = scrollView.zoomScale
        }
        view.subviews.forEach { disableZoom(in: $0) }
    }
}
