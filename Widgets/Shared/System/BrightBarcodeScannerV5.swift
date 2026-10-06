//
//  BrightBarcodeScannerV5.swift
//  Widgets
//

import AVFoundation
import SwiftUI
import Vision
import VisionKit

struct BrightBarcodeScannerV5: View {
    @Binding var isActive: Bool
    var symbologies: [VNBarcodeSymbology] = .brightFoodDefault
    let onFound: (String) -> Void

    @State private var cameraAuthorized = false

    var body: some View {
        Group {
            if DataScannerViewController.isSupported, cameraAuthorized {
                DataScannerView(isActive: $isActive, symbologies: symbologies, onFound: onFound)
            } else {
                BarcodeScannerPlaceholder(isSupported: DataScannerViewController.isSupported, onFound: onFound)
            }
        }
        .task {
            cameraAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        }
    }
}

extension [VNBarcodeSymbology] {
    static let brightFoodDefault: [VNBarcodeSymbology] = [
        .ean13, .ean8, .upce,
        .code128, .code39, .code39Checksum, .code93,
        .i2of5, .i2of5Checksum,
        .gs1DataBar, .gs1DataBarExpanded, .gs1DataBarLimited,
    ]
}

private struct DataScannerView: UIViewControllerRepresentable {
    @Binding var isActive: Bool
    let symbologies: [VNBarcodeSymbology]
    let onFound: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: symbologies)],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        context.coordinator.onFound = onFound
        if isActive {
            try? scanner.startScanning()
        } else {
            scanner.stopScanning()
        }
    }

    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
        scanner.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onFound: onFound)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onFound: (String) -> Void

        init(onFound: @escaping (String) -> Void) {
            self.onFound = onFound
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            for case let .barcode(barcode) in addedItems {
                if let value = barcode.payloadStringValue {
                    onFound(value)
                    return
                }
            }
        }
    }
}

private struct BarcodeScannerPlaceholder: View {
    let isSupported: Bool
    let onFound: (String) -> Void

    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: .spacing2x) {
                Image(systemName: "barcode.viewfinder")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                BrightText(
                    isSupported ? "Camera access is required to scan barcodes." : "Barcode scanning is unavailable in the Simulator.",
                    size: .body3,
                    color: .white
                )
                .multilineTextAlignment(.center)
            }
            .padding(.spacing4x)
        }
        #if targetEnvironment(simulator)
        .onTapGesture { onFound("0123456789012") }
        #endif
    }
}
