//
//  VaultMarkerData.swift
//  Widgets
//
//

import Foundation

struct VaultMarkerData: Identifiable, Equatable {
    let id: String
    let name: String
    let category: String
    let type: String?
    let status: String
    let value: String
    var lastUpdated: String? = nil
    let unit: String
    let trend: [Double]
    let normalRange: ClosedRange<Double>?
}
