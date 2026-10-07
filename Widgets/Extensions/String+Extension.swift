//
//  String+Extension.swift
//  Widgets
//

import Foundation

extension String {
    func isoStringToDate() -> Date {
        Date(brightISOZoned: self) ?? Date(brightDayKey: self) ?? Date()
    }
}
