//
//  VaultClinicsMapView.swift
//  Widgets
//
//  Created by Dom Montalto on 7/7/2026.
//

import MapKit
import SwiftUI

private struct MapClinic: Identifiable {
    let id = UUID()
    let clinic: VaultTestingClinic
    let coordinate: CLLocationCoordinate2D

    static let demo: [MapClinic] = [
        MapClinic(clinic: .demo[0], coordinate: .init(latitude: 47.6145, longitude: -122.3418)),
        MapClinic(clinic: .demo[1], coordinate: .init(latitude: 47.6097, longitude: -122.3331)),
        MapClinic(clinic: .demo[2], coordinate: .init(latitude: 47.6028, longitude: -122.3286)),
        MapClinic(clinic: .demo[3], coordinate: .init(latitude: 47.6082, longitude: -122.3400)),
        MapClinic(clinic: .demo[4], coordinate: .init(latitude: 47.6169, longitude: -122.3253)),
    ]
}

struct VaultClinicsMapView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedClinic: MapClinic?
    @State private var sheetHeight: CGFloat = 320
    @State private var position: MapCameraPosition = .region(Self.seattle)

    private let clinics = MapClinic.demo

    private static let sheetDismissDuration = 0.35

    private static let seattle = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 47.6090, longitude: -122.3330),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )

    var body: some View {
        Map(position: $position) {
            ForEach(clinics) { clinic in
                Annotation(clinic.clinic.name, coordinate: clinic.coordinate) {
                    clinicPin
                        .onTapGesture {
                            selectedClinic = clinic
                        }
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: goBack) {
                    Image(systemName: "chevron.backward")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.brightEaseInOut) {
                        position = .region(Self.seattle)
                    }
                } label: {
                    Image(systemName: "location")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .sheet(isPresented: sheetShown) {
            if let selected = selectedClinic {
                ClinicMiniSheet(clinic: selected.clinic) { selectedClinic = nil }
                    .onPreferenceChange(SheetHeightKey.self) { if $0 > 0 { sheetHeight = $0 } }
                    .presentationDetents([.height(sheetHeight)])
                    .presentationDragIndicator(.hidden)
                    .presentationBackgroundInteraction(.enabled)
            }
        }
    }

    private func goBack() {
        guard selectedClinic != nil else {
            dismiss()
            return
        }
        withAnimation(.brightEaseInOut) { selectedClinic = nil }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.sheetDismissDuration) {
            dismiss()
        }
    }

    /// Drives the sheet from the selected pin; dismissing clears the selection.
    private var sheetShown: Binding<Bool> {
        Binding(
            get: { selectedClinic != nil },
            set: { if !$0 { selectedClinic = nil } }
        )
    }

    private var clinicPin: some View {
        Circle()
            .fill(Color.defaultMainBlack)
            .frame(width: .spacing5x, height: .spacing5x)
            .overlay {
                Image(systemName: "circle.hexagongrid")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            .overlay {
                Circle().strokeBorder(.white.opacity(.semiLowOpacity), lineWidth: 1.5)
            }
    }
}

// MARK: - Clinic mini sheet (native slide-up, glass background, drag to dismiss)

/// Reports the intrinsic content height so the sheet can size to it.
private struct SheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct ClinicMiniSheet: View {
    let clinic: VaultTestingClinic
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack {
                BrightRoundButton(systemImage: "xmark", size: .large, onTapCallback: onClose)
                Spacer()
                visitWebsiteButton
            }
            .padding(.bottom, .spacing105x)

            HStack(spacing: .spacing105x) {
                Circle()
                    .fill(Color.defaultMainBlack)
                    .frame(width: .spacing5x, height: .spacing5x)
                    .overlay {
                        Image(systemName: "circle.hexagongrid")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                    }

                BrightText(clinic.name, size: .subheading1, weight: .regular)

                Spacer()

                BrightText(clinic.distance, size: .body2, color: .lightTextColor)
            }

            BrightText(clinic.address, size: .body2, color: .lightTextColor)

            divider

            BrightText("Services:", size: .body2, color: .lightTextColor)

            FlowLayout(spacing: .spacing1x) {
                ForEach(clinic.services, id: \.self) { service in
                    BrightChip(
                        title: service,
                        size: .body3,
                        tint: .defaultBlue,
                        fill: .defaultBlue.opacity(.veryMinimalOpacity)
                    )
                }
            }

            divider

            BrightText("Pricing:", size: .body2, color: .lightTextColor)

            VStack(spacing: .spacing1x) {
                ForEach(Array(clinic.pricing.enumerated()), id: \.offset) { _, row in
                    HStack {
                        BrightText(row.option, size: .body2)
                        Spacer()
                        BrightText(row.price, size: .body2)
                    }
                }
            }
        }
        .padding(.spacing4x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: SheetHeightKey.self, value: proxy.size.height)
            }
        )
    }

    private var visitWebsiteButton: some View {
        Button {
        } label: {
            BrightText("Visit website", size: .body2, weight: .regular)
                .padding(.horizontal, .spacing2x)
                .padding(.vertical, .spacing105x)
                .overlay {
                    Capsule()
                        .strokeBorder(Color.textColor.opacity(.minimalOpacity), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.lightTextColor.opacity(.ultraLowOpacity))
            .frame(height: 0.5)
    }
}

#Preview {
    NavigationStack {
        VaultClinicsMapView()
    }
}
