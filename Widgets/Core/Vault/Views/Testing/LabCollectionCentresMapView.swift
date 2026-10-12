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
    let onOrder: (VaultTestOrder) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @State private var data: LabCollectionCentres?
    @State private var failed = false
    @State private var selected: LabCollectionCentre?
    @State private var selectedDistanceKm: Double?
    @State private var trayDetent = Constants.minimisedDetent
    @State private var pin: UIImage?
    // Starts close in, like the Exercise maps, then flies to wherever the puck is, so it
    // never opens zoomed out on the globe.
    @State private var viewport: Viewport = .camera(center: Constants.initialCenter, zoom: Constants.followZoom)

    private let catalog = LabCatalog.shared

    var body: some View {
        MapReader { proxy in
            MapboxMaps.Map(viewport: $viewport) {
                Puck2D()

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

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: followPuck) {
                    Label("My Location", systemImage: "location")
                        .labelStyle(.iconOnly)
                }
            }

            ToolbarItem(placement: .principal) {
                DebugInlineTitle(title: data.map { "\($0.centres.count.formatted()) collection centres" } ?? "", file: #file)
            }
        }
        // The same three heights as Atlas's region tray: the centre at its smallest with
        // the map still in reach, its tests at medium, a test opened at large.
        .sheet(isPresented: sheetShown) {
            Group {
                if let selected {
                    CentreTray(
                        centre: selected,
                        clinic: catalog.clinic(for: .au),
                        tests: tests(at: selected),
                        distanceKm: selectedDistanceKm,
                        onExpand: { trayDetent = .large },
                        onClose: { self.selected = nil },
                        onOrder: order
                    )
                    .id(selected.id)
                }
            }
            .presentationDetents(Constants.trayDetents, selection: $trayDetent)
            .interactiveDismissDisabled(trayDetent != Constants.minimisedDetent)
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(.screenCornerRadius)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
        .onAppear(perform: followPuck)
        .task {
            pin = renderPin()
            data = await LabCollectionCentres.load()
            failed = data == nil
        }
    }

    private func select(_ centre: LabCollectionCentre, from location: CLLocationCoordinate2D?) {
        selectedDistanceKm = centre.distanceKm(from: location.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) })
        if selected == nil {
            trayDetent = Constants.minimisedDetent
        }
        selected = centre
    }

    // Eirly's own tests, narrowed to the ones this centre's network collects.
    private func tests(at centre: LabCollectionCentre) -> [VaultClinicTest] {
        guard let clinic = catalog.clinic(for: .au), let data else { return [] }
        let collected = Set(data.tests(at: centre).map(\.id))
        return clinic.tests.filter { $0.labTestId.map(collected.contains) == true }
    }

    // The tray has to be down before the map is left for the receipt.
    private func order(_ order: VaultTestOrder) {
        selected = nil
        Task {
            try? await Task.sleep(for: .seconds(Constants.sheetDismissDuration))
            onOrder(order)
        }
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
            // Centres on the user without turning the map to the way they face.
            viewport = .followPuck(zoom: Constants.followZoom, bearing: .constant(0), pitch: 0)
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
        static let minimisedDetent: PresentationDetent = .height(156)
        static let trayDetents: Set<PresentationDetent> = [minimisedDetent, .medium, .large]
        static let initialCenter = CLLocationCoordinate2D(latitude: -33.8769, longitude: 151.2006)
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

// MARK: - Tray

private struct CentreTray: View {
    let centre: LabCollectionCentre
    let clinic: VaultTestingClinic?
    let tests: [VaultClinicTest]
    let distanceKm: Double?
    let onExpand: () -> Void
    let onClose: () -> Void
    let onOrder: (VaultTestOrder) -> Void

    @Environment(\.openURL) private var openURL
    @State private var selectedTest: VaultClinicTest?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacing3x) {
                    header

                    if let clinic {
                        VaultClinicTestList(clinic: clinic, tests: tests, color: .defaultSheetModalCards) { test in
                            onExpand()
                            selectedTest = test
                        }
                    }
                }
                .padding(.horizontal, .spacing3x)
                .padding(.top, .spacing4x)
                .padding(.bottom, .spacing10x)
            }
            .scrollIndicators(.hidden)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedTest) { test in
                if let clinic {
                    VaultTestDetailView(test: test, clinic: clinic) { order in
                        selectedTest = nil
                        onOrder(order)
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            HStack(spacing: .spacing105x) {
                VaultClinicLogo()

                BrightText(centre.name, size: .subheading1, weight: .regular)
                    .lineLimit(1)

                Spacer(minLength: .spacing0x)

                BrightRoundButton(systemImage: "xmark", size: .medium, onTapCallback: onClose)
            }

            BrightText(details, size: .body1, color: .lightTextColor)
                .lineLimit(2)

            if let phoneURL = centre.phoneURL {
                BrightPillButton("Call", systemImage: "phone", buttonSize: .small) {
                    openURL(phoneURL)
                }
            }
        }
    }

    private var details: String {
        guard let distanceKm else { return centre.address }
        return String(format: "%.1f km away", distanceKm) + " · " + centre.address
    }
}

#Preview {
    NavigationStack {
        LabCollectionCentresMapView { _ in }
    }
}
