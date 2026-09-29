//
//  GenomeOrderStatus.swift
//  Widgets
//

import Foundation

enum GenomeOrderStatus: String, Codable {
    case none
    case ordered
    case shipping
    case delivered
    case processing
    case ready
    case failed
    case cancelled

    var isTerminal: Bool {
        switch self {
        case .none, .ready, .failed, .cancelled: true
        case .ordered, .shipping, .delivered, .processing: false
        }
    }

    var displayTitle: String {
        switch self {
        case .none: "Not ordered"
        case .ordered: "Order placed"
        case .shipping: "Kit shipped"
        case .delivered: "Kit delivered"
        case .processing: "Processing sample"
        case .ready: "Results ready"
        case .failed: "Order failed"
        case .cancelled: "Order cancelled"
        }
    }

    var completedSteps: Int {
        switch self {
        case .ordered: 1
        case .shipping: 2
        case .delivered: 3
        case .processing, .ready: 4
        default: 0
        }
    }

    var activeOrderMessage: String {
        switch self {
        case .shipping: "Your kit is already on its way."
        case .delivered: "Your kit has been delivered — send your sample back when you're ready."
        case .processing: "Your sample is already being processed."
        default: "You've already got a kit on the way."
        }
    }
}
