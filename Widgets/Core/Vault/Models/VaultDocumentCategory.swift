//
//  VaultDocumentCategory.swift
//  Widgets
//
//  Created by Dom Montalto on 5/11/2026.
//

import SwiftUI

enum VaultDocumentCategory: String, CaseIterable, Identifiable {
    case bloodWork
    case prescriptions
    case xrays
    case mri
    case clinicalNotes
    case ecg
    case dna

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bloodWork: "Blood work"
        case .prescriptions: "Prescriptions"
        case .xrays: "XRAYs"
        case .mri: "MRI"
        case .clinicalNotes: "Clinical notes"
        case .ecg: "ECG"
        case .dna: "DNA"
        }
    }

    var systemImage: String {
        switch self {
        case .bloodWork: "drop.fill"
        case .prescriptions: "pills.fill"
        case .xrays: "lightspectrum.horizontal"
        case .mri: "brain.head.profile.fill"
        case .clinicalNotes: "note.text"
        case .ecg: "waveform.path.ecg"
        case .dna: "testtube.2"
        }
    }

    var tint: Color {
        switch self {
        case .bloodWork: .defaultRed
        case .prescriptions: .defaultBlue
        case .xrays: .defaultPurple
        case .mri: .defaultPink
        case .clinicalNotes: .defaultOrange
        case .ecg: .defaultRed
        case .dna: .defaultGreen
        }
    }

    var emptyText: String {
        "No \(title.lowercased()) uploaded"
    }

    // DNA only shows once there's a genetic report; the rest always have a section.
    var isAlwaysShown: Bool { self != .dna }
}
