//
//  GenomeOrderInfo.swift
//  Widgets
//

import Foundation

struct GenomeOrderInfo: Codable {
    let widgetState: String
    let statusLabel: String
    let eta: String?
    let completedSteps: Int
    let totalSteps: Int
}
