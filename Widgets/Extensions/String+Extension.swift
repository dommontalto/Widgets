//
//  String+Extension.swift
//  Widgets
//

import Foundation

extension String {
    func formattedRecordedDate() -> String {
        if let date = Date(brightISOZoned: self) {
            return date.formatted(.brightTimestamp)
        }
        if let date = Date(brightDayKey: self) {
            return date.formatted(.brightDate)
        }
        return self
    }

    func isoStringToDate() -> Date {
        Date(brightISOZoned: self) ?? Date(brightDayKey: self) ?? Date()
    }
}
