//
//  BrightDICOMViewerV5.swift
//  Widgets
//

import SwiftUI

// Shows a DICOM scan in a card with a slider along the bottom that lightens or darkens it.
// `footer` ends the scrolling content.
// Features modelled on https://github.com/ahsxn/Display-and-process-medical-images-on-an-iOS-device
// (no code taken; that repo has no licence).
struct BrightDICOMViewerV5<Footer: View>: View {
    let url: URL
    @ViewBuilder var footer: Footer

    @State private var file: BrightDICOMFile?
    @State private var didFail = false
    // -1 darkest, 0 the scan's own window, 1 lightest.
    @State private var brightness: Double = 0
    @State private var rendered: CGImage?
    // Touch to zoom and move, off for now:
    // @State private var zoom: CGFloat = 1
    // @State private var pan: CGSize = .zero
    // @GestureState private var pinch: CGFloat = 1
    // @GestureState private var drag: CGSize = .zero

    var body: some View {
        Group {
            if file == nil, !didFail {
                BrightProgressViewV5()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: .spacing4x) {
                        if let file {
                            card(file)
                            details(file)
                            footer
                        } else {
                            failure
                        }
                    }
                    .padding(.horizontal, .spacing3x)
                    .padding(.bottom, .spacing4x)
                }
            }
        }
        .animation(.brightEaseInOut, value: file == nil)
        .task(id: url) { await load() }
        .onChange(of: brightness) { _, value in
            guard let file else { return }
            rendered = file.image(window: window(for: value, in: file))
        }
    }

    // MARK: - Scan

    private func card(_ file: BrightDICOMFile) -> some View {
        scanImage(file)
            // .scaleEffect(zoom * pinch)
            // .offset(x: pan.width + drag.width, y: pan.height + drag.height)
            .frame(maxWidth: .infinity)
            .aspectRatio(CGFloat(file.width) / CGFloat(file.height), contentMode: .fit)
            .background(Color.defaultBlack)
            .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius))
            // .contentShape(RoundedRectangle(cornerRadius: .cardCornerRadius))
            // .gesture(magnify)
            // .gesture(panGesture, including: zoom > 1 ? .all : .subviews)
            // .onTapGesture(count: 2) {
            //     withAnimation(.brightSpring) {
            //         zoom = zoom > 1 ? 1 : Constants.doubleTapZoom
            //         pan = .zero
            //     }
            // }
            .overlay(alignment: .bottom) {
                brightnessSlider(file)
                    .padding(.bottom, .spacing3x)
            }
    }

    // private var magnify: some Gesture {
    //     MagnifyGesture()
    //         .updating($pinch) { value, pinch, _ in
    //             pinch = value.magnification
    //         }
    //         .onEnded { value in
    //             withAnimation(.brightSpring) {
    //                 zoom = min(max(zoom * value.magnification, 1), Constants.maxZoom)
    //                 if zoom == 1 { pan = .zero }
    //             }
    //         }
    // }
    //
    // private var panGesture: some Gesture {
    //     DragGesture()
    //         .updating($drag) { value, drag, _ in
    //             drag = value.translation
    //         }
    //         .onEnded { value in
    //             pan.width += value.translation.width
    //             pan.height += value.translation.height
    //         }
    // }

    private func scanImage(_ file: BrightDICOMFile) -> some View {
        Image(decorative: rendered ?? file.image, scale: 1)
            .resizable()
            .scaledToFit()
    }

    @ViewBuilder
    private func brightnessSlider(_ file: BrightDICOMFile) -> some View {
        if file.defaultWindow != nil {
            Slider(value: $brightness, in: -1 ... 1)
                .tint(Color.textColor)
                .padding(.horizontal, .spacing4x)
                .environment(\.colorScheme, .dark)
                .accessibilityLabel("Brightness")
        }
    }

    // Slides the window's level across half the value range each way. MONOCHROME1 stores
    // bright as low, so the level moves the other way there.
    private func window(for brightness: Double, in file: BrightDICOMFile) -> BrightDICOMFile.Window {
        guard var window = file.defaultWindow else { return BrightDICOMFile.Window(center: 0, width: 1) }
        let span = file.valueRange.upperBound - file.valueRange.lowerBound
        let direction: Double = file.isInverted ? 1 : -1
        window.center += brightness * span / 2 * direction
        return window
    }

    // MARK: - Details

    private func details(_ file: BrightDICOMFile) -> some View {
        VStack(alignment: .leading, spacing: .spacing4x) {
            BrightRowGroupV5(header: "Scan", color: .defaultSheetModalCards) {
                if let value = file.modalityName { BrightRowV5("Type", trailing: .value(value)) }
                if let value = file.bodyPart { BrightRowV5("Body part", trailing: .value(value)) }
                if let value = file.viewPosition { BrightRowV5("View", trailing: .value(value)) }
                if let value = file.studyDescription { BrightRowV5("Study", trailing: .value(value)) }
                if let value = file.studyDate { BrightRowV5("Date", trailing: .value(value.formatted(.brightDate))) }
                if let value = file.institution { BrightRowV5("Taken at", trailing: .value(value)) }
            }

            BrightRowGroupV5(header: "File", color: .defaultSheetModalCards) {
                BrightRowV5("Format", trailing: .value("DICOM (.\(url.pathExtension))"))
                BrightRowV5("Encoding", trailing: .value(file.encodingName))
                BrightRowV5("Resolution", trailing: .value("\(file.width) × \(file.height)"))
                BrightRowV5("Depth", trailing: .value("\(file.bitsStored)-bit"))
                if let spacing = file.pixelSpacing {
                    BrightRowV5("Pixel size", trailing: .value("\(Double(spacing.width).formatted(.number.precision(.fractionLength(2)))) mm"))
                }
                BrightRowV5("Size", trailing: .value(Int64(file.fileSize).formatted(.byteCount(style: .file))))
            }
        }
    }

    private var failure: some View {
        VStack(spacing: .spacing2x) {
            Image(systemName: "exclamationmark.triangle")
                .font(.standard(size: .standout1, weight: .regular))
                .foregroundStyle(Color.defaultOrange)
            BrightText("Couldn't read this scan", size: .body1, weight: .medium)
            BrightText("Compressed DICOM files aren't supported yet.", size: .body5, color: .lightTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.spacing4x)
    }

    // Works for bundled files and downloads alike; decoding runs off the main actor.
    private func load() async {
        guard let (data, _) = try? await URLSession.shared.data(from: url) else {
            didFail = true
            return
        }
        let decoded = await Task.detached(priority: .userInitiated) { BrightDICOMFile(data: data) }.value
        file = decoded
        didFail = decoded == nil
    }

    // private typealias Constants = BrightDICOMViewerConstants
}

extension BrightDICOMViewerV5 where Footer == EmptyView {
    init(url: URL) {
        self.init(url: url) { EmptyView() }
    }
}

// private enum BrightDICOMViewerConstants {
//     static let doubleTapZoom: CGFloat = 2.5
//     static let maxZoom: CGFloat = 6
// }
