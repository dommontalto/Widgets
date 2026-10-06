//
//  BrightError.swift
//  Bright
//
//  Copyright © 2026 Bryan Jordan. All rights reserved.
//

import Foundation

protocol BrightError: Error {
    var message: String { get }
    var surface: BrightErrorSurface { get }
}

struct BrightErrorMessage: BrightError {
    let message: String
    let surface: BrightErrorSurface

    static func toast(_ message: String) -> BrightErrorMessage {
        BrightErrorMessage(message: message, surface: .toast)
    }

    static func alert(_ message: String) -> BrightErrorMessage {
        BrightErrorMessage(message: message, surface: .alert)
    }

    static let silent = BrightErrorMessage(message: "", surface: .silent)
}
