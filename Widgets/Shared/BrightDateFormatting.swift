//
//  BrightDateFormatting.swift
//  Widgets
//
//  Created by Dom Montalto on 27/7/2026.
//

import Foundation

extension String {
    func isoStringToDate() -> Date {
        ISO8601DateFormatter().date(from: self) ?? Date()
    }
}

extension Locale {
    static let bright = Locale(identifier: "en_NZ")
}

extension FormatStyle where Self == Date.FormatStyle {
    static var brightTime: Self { Date.FormatStyle(locale: .bright).hour(.defaultDigits(amPM: .abbreviated)).minute() }
}

extension Date {
    var isoString: String {
        ISO8601DateFormatter().string(from: self)
    }

    static func brightTimeRange(from: Date, to: Date) -> String {
        "\(from.formatted(.brightTime)) – \(max(from, to).formatted(.brightTime))"
    }

    func stringFromDate(strFormatter: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = strFormatter
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: self)
    }
}

extension Double {
    var toString: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}
