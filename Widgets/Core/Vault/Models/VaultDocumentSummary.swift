//
//  VaultDocumentSummary.swift
//  Widgets
//

import Foundation

struct VaultDocumentSummary: Identifiable, Hashable {
    let id: String
    let labName: String
    let collectedAt: Date
    let sourceFilename: String?
    let confirmedAt: Date?
    let isGeneticReport: Bool
    var category: VaultDocumentCategory = .bloodWork
}
