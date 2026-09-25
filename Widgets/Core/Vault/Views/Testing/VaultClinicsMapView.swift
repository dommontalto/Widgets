//
//  VaultClinicsMapView.swift
//  Widgets
//
//  Created by Dom Montalto on 17/9/2026.
//

import CoreLocation
import MapboxMaps
import SwiftUI

struct VaultClinicsMapView: View {
    let clinics: [VaultTestingClinic]
    let onSelectClinic: (VaultTestingClinic) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedClinic: VaultTestingClinic?
    @State private var viewport: Viewport = .camera(center: Constants.sydney, zoom: Constants.zoom)

    var body: some View {
        MapboxMaps.Map(viewport: $viewport) {
            Puck2D(bearing: .heading)

            ForEvery(clinics) { clinic in
                MapViewAnnotation(coordinate: clinic.coordinate) {
                    VaultClinicLogo()
                        .overlay {
                            Circle().strokeBorder(.white.opacity(.semiLowOpacity), lineWidth: Constants.pinStroke)
                        }
                        .onTapGesture { selectedClinic = clinic }
                }
                .allowOverlap(true)
            }
        }
        .mapStyle(.standard(lightPreset: colorScheme == .dark ? .night : .day))
        .ornamentOptions(OrnamentOptions(
            scaleBar: ScaleBarViewOptions(visibility: .hidden),
            compass: CompassViewOptions(visibility: .hidden)
        ))
        .ignoresSafeArea()
        .toolbarBackground(.hidden, for: .navigationBar)
        .brightSoftScrollEdges()
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
                    Label("Locate", systemImage: "location")
                        .labelStyle(.iconOnly)
                }
            }
        }
        .brightMiniSheet(isPresented: sheetShown) {
            if let selectedClinic {
                ClinicMiniSheet(
                    clinic: selectedClinic,
                    onFindOutMore: { open(selectedClinic) },
                    onClose: { self.selectedClinic = nil }
                )
            }
        }
    }

    // The mini sheet has to be down before the map pops, or it lingers over
    // the list behind.
    private func goBack() {
        guard selectedClinic != nil else {
            dismiss()
            return
        }
        withAnimation(.brightEaseInOut) { selectedClinic = nil }
        Task {
            try? await Task.sleep(for: .seconds(Constants.sheetDismissDuration))
            dismiss()
        }
    }

    // Same reason as goBack: the mini sheet has to be down before the clinic
    // sheet comes up over the map.
    private func open(_ clinic: VaultTestingClinic) {
        withAnimation(.brightEaseInOut) { selectedClinic = nil }
        Task {
            try? await Task.sleep(for: .seconds(Constants.sheetDismissDuration))
            onSelectClinic(clinic)
        }
    }

    private func followPuck() {
        withViewportAnimation(.easeOut(duration: Constants.locateDuration)) {
            viewport = .followPuck(zoom: Constants.followZoom, bearing: .heading)
        }
    }

    private var sheetShown: Binding<Bool> {
        Binding(
            get: { selectedClinic != nil },
            set: { if !$0 { selectedClinic = nil } }
        )
    }

    private enum Constants {
        static let sydney = CLLocationCoordinate2D(latitude: -33.8760, longitude: 151.2000)
        static let zoom: CGFloat = 11.5
        static let followZoom: CGFloat = 14
        static let pinStroke: CGFloat = 1.5
        static let sheetDismissDuration: TimeInterval = 0.35
        static let locateDuration: TimeInterval = 0.35
    }
}

private extension VaultTestingClinic {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Mini sheet

private struct ClinicMiniSheet: View {
    let clinic: VaultTestingClinic
    let onFindOutMore: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack {
                BrightRoundButton(systemImage: "xmark", size: .large, onTapCallback: onClose)

                Spacer(minLength: .spacing0x)

                BrightPillButton("Find out more", buttonSize: .medium, onTapCallback: onFindOutMore)
            }
            .padding(.bottom, .spacing105x)

            HStack(spacing: .spacing105x) {
                VaultClinicLogo()

                BrightText(clinic.name, size: .subheading1, weight: .regular)

                Spacer(minLength: .spacing0x)

                BrightText(clinic.distance, size: .body1, color: .lightTextColor)
            }

            BrightText(clinic.address, size: .body1, color: .lightTextColor)

            BrightDivider()

            BrightText("Services", size: .body1, color: .semiLightTextColor, weight: .regular)

            FlowLayout(spacing: .spacing1x) {
                ForEach(clinic.services, id: \.self) { service in
                    BrightChip(
                        title: service,
                        tint: .defaultBlue,
                        fill: .defaultBlue.opacity(.veryMinimalOpacity)
                    )
                }
            }
        }
        .padding(.spacing4x)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        VaultClinicsMapView(clinics: VaultTestingClinic.demo) { _ in }
    }
}
