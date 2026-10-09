//
//  LabCollectionCentresMapView.swift
//  Widgets
//
//  Created by Dom Montalto on 17/9/2026.
//

import CoreLocation
import MapboxMaps
import SwiftUI

struct LabCollectionCentresMapView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @State private var data: LabCollectionCentres?
    @State private var failed = false
    @State private var selected: LabCollectionCentre?
    @State private var selectedDistanceKm: Double?
    @State private var pin: UIImage?
    @State private var viewport: Viewport = .camera(center: Constants.australia, zoom: Constants.australiaZoom)

    var body: some View {
        MapReader { proxy in
            MapboxMaps.Map(viewport: $viewport) {
                Puck2D(bearing: .heading)

                if let data, let pin {
                    PointAnnotationGroup(data.centres) { centre in
                        PointAnnotation(coordinate: centre.coordinate)
                            .image(.init(image: pin, name: Constants.pinName))
                            .onTapGesture {
                                select(centre, from: proxy.location?.latestLocation?.coordinate)
                            }
                    }
                    .iconAllowOverlap(true)
                    .clusterOptions(Constants.clusterOptions)
                    .onClusterTapGesture(perform: expand)
                }
            }
            .mapStyle(.standard(lightPreset: colorScheme == .dark ? .night : .day))
            .ornamentOptions(OrnamentOptions(
                scaleBar: ScaleBarViewOptions(visibility: .hidden),
                compass: CompassViewOptions(visibility: .hidden)
            ))
        }
        .ignoresSafeArea()
        .overlay {
            if failed {
                BrightText("Couldn't load collection centres.", size: .body1, color: .lightTextColor)
            } else if data == nil {
                BrightProgressViewV5()
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .brightSoftScrollEdgesV5()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: goBack) {
                    Label("Back", systemImage: "chevron.backward")
                        .labelStyle(.iconOnly)
                }
            }

            ToolbarItem(placement: .principal) {
                DebugInlineTitle(title: data.map { "\($0.centres.count.formatted()) collection centres" } ?? "", file: #file)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: followPuck) {
                    Label("Locate", systemImage: "location")
                        .labelStyle(.iconOnly)
                }
            }
        }
        .brightMiniSheetV5(isPresented: sheetShown) {
            if let selected, let data {
                CentreMiniSheet(
                    centre: selected,
                    tests: data.tests(at: selected),
                    distanceKm: selectedDistanceKm,
                    onClose: { self.selected = nil }
                )
            }
        }
        .task {
            pin = renderPin()
            data = await LabCollectionCentres.load()
            failed = data == nil
        }
    }

    private func select(_ centre: LabCollectionCentre, from location: CLLocationCoordinate2D?) {
        selectedDistanceKm = centre.distanceKm(from: location.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) })
        selected = centre
    }

    private func expand(_ context: AnnotationClusterGestureContext) {
        withViewportAnimation(.easeOut(duration: Constants.zoomDuration)) {
            viewport = .camera(center: context.coordinate, zoom: context.expansionZoom ?? Constants.followZoom)
        }
    }

    private func goBack() {
        guard selected != nil else {
            dismiss()
            return
        }
        withAnimation(.brightEaseInOut) { selected = nil }
        Task {
            try? await Task.sleep(for: .seconds(Constants.sheetDismissDuration))
            dismiss()
        }
    }

    private func followPuck() {
        withViewportAnimation(.easeOut(duration: Constants.zoomDuration)) {
            viewport = .followPuck(zoom: Constants.followZoom, bearing: .heading)
        }
    }

    private func renderPin() -> UIImage? {
        let renderer = ImageRenderer(content: VaultClinicLogo()
            .overlay {
                Circle().strokeBorder(.white.opacity(.semiLowOpacity), lineWidth: Constants.pinStroke)
            }
        )
        renderer.scale = displayScale
        return renderer.uiImage
    }

    private var sheetShown: Binding<Bool> {
        Binding(
            get: { selected != nil },
            set: { if !$0 { selected = nil } }
        )
    }

    private enum Constants {
        static let australia = CLLocationCoordinate2D(latitude: -27.5, longitude: 134.5)
        static let australiaZoom: CGFloat = 3.2
        static let followZoom: CGFloat = 12
        static let pinName = "lab-centre-pin"
        static let pinStroke: CGFloat = 1.5
        static let sheetDismissDuration: TimeInterval = 0.35
        static let zoomDuration: TimeInterval = 0.35
        static let clusterOptions = ClusterOptions(
            circleRadius: .expression(Exp(.step) {
                Exp(.get) { "point_count" }
                16
                25
                20
                100
                25
                500
                31
            }),
            circleColor: .constant(StyleColor(.black)),
            textColor: .constant(StyleColor(.white)),
            textSize: .constant(13),
            textField: .expression(Exp(.get) { "point_count_abbreviated" }),
            clusterRadius: 44,
            clusterMaxZoom: 13
        )
    }
}

// MARK: - Mini sheet

private struct CentreMiniSheet: View {
    let centre: LabCollectionCentre
    let tests: [LabCentreTest]
    let distanceKm: Double?
    let onClose: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var query = ""

    private var shown: [LabCentreTest] {
        let needle = query.trimmingCharacters(in: .whitespaces)
        let list = needle.isEmpty ? tests : tests.filter { $0.name.localizedCaseInsensitiveContains(needle) }
        return list.filter(\.genetic) + list.filter { !$0.genetic }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack {
                BrightRoundButton(systemImage: "xmark", size: .large, onTapCallback: onClose)

                Spacer(minLength: .spacing0x)

                if let phoneURL = centre.phoneURL {
                    BrightPillButton("Call", systemImage: "phone", buttonSize: .medium) {
                        openURL(phoneURL)
                    }
                }
            }
            .padding(.bottom, .spacing105x)

            HStack(spacing: .spacing105x) {
                VaultClinicLogo()

                BrightText(centre.name, size: .subheading1, weight: .regular)
                    .lineLimit(2)

                Spacer(minLength: .spacing0x)

                if let distanceKm {
                    BrightText(String(format: "%.1f km away", distanceKm), size: .body1, color: .lightTextColor)
                }
            }

            BrightText(centre.address, size: .body1, color: .lightTextColor)
                .fixedSize(horizontal: false, vertical: true)

            BrightDividerV5()

            HStack(alignment: .firstTextBaseline, spacing: .spacing1x) {
                BrightText("Tests you can order in Bright", size: .body1, color: .semiLightTextColor, weight: .regular)

                BrightText("\(tests.count)", size: .body3, color: .lightTextColor)
                    .monospacedDigit()
            }

            BrightText("Order in Guided Testing. Eirly issues the referral, then collect here.", size: .body4, color: .lightTextColor)
                .fixedSize(horizontal: false, vertical: true)

            BrightSearchBarV5("Search tests", text: $query)

            ScrollView {
                FlowLayout(spacing: .spacing1x) {
                    ForEach(shown) { test in
                        BrightChipV5(
                            title: test.genetic ? "\(test.name) · Genetic" : test.name,
                            tint: test.genetic ? .defaultPurple : .defaultBlue,
                            fill: (test.genetic ? Color.defaultPurple : Color.defaultBlue).opacity(.veryMinimalOpacity)
                        )
                    }
                }

                if shown.isEmpty {
                    BrightText("No tests match “\(query)”.", size: .body1, color: .lightTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .frame(height: Constants.testsHeight)
        }
        .padding(.spacing4x)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private enum Constants {
        static let testsHeight: CGFloat = 220
    }
}

#Preview {
    NavigationStack {
        LabCollectionCentresMapView()
    }
}
