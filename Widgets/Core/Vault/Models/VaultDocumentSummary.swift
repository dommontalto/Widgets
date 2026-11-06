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

    // Documents without a source filename are the demo PDF report.
    var fileType: VaultDocumentFileType {
        VaultDocumentFileType(filename: sourceFilename)
    }

    var listSubtitle: String {
        "\(fileType.title) · Uploaded: \((confirmedAt ?? collectedAt).formatted(.brightDate))"
    }
}

enum VaultDocumentFileType: Hashable {
    case pdf
    case dicom
    case other(String)

    init(filename: String?) {
        guard let filename else {
            self = .pdf
            return
        }
        switch (filename as NSString).pathExtension.lowercased() {
        case "pdf": self = .pdf
        case "dcm", "dicom": self = .dicom
        case let other: self = .other(other.isEmpty ? "File" : other.uppercased())
        }
    }

    var title: String {
        switch self {
        case .pdf: "PDF"
        case .dicom: "DICOM"
        case let .other(name): name
        }
    }
}
