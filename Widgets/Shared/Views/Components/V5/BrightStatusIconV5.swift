//
//  BrightStatusIconV5.swift
//  Widgets
//
//  Created by Vinh Tran on 19/2/2026.
//

import SwiftUI

struct BrightStatusIconV5: View {
    var status: ScoresStatus
    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        switch status {
        case .excellent, .good, .average: Image(ImageNames.circleCheckmarkV5).resizable().scaledToFit().frame(
                width: 24,
                height: 24
            )
        case .subOptimal, .poor: Image(ImageNames.warningDiamondYellowV4).resizable().scaledToFit().frame(
                width: 24,
                height: 24
            )
        case .high, .low: Image(ImageNames.warningDiamondV4).resizable().scaledToFit().frame(width: 24, height: 24)
        case .noData: EmptyView()
        }
    }

    init(status: ScoresStatus) {
        self.status = status
    }

    init(value: Double) {
        status = ScoresStatus(value: value)
    }

    init(heartRate: Double) {
        status = ScoresStatus(heartRate: heartRate)
    }

    init(hrv: Double) {
        status = ScoresStatus(hrv: hrv)
    }

    init(cardioLoad: Double) {
        status = ScoresStatus(cardioLoad: cardioLoad)
    }
}

extension ScoresStatus {
    // Convenience init as a percentage
    fileprivate init(value: Double) {
        switch value {
        case 0 ... 14: self = .high
        case 16 ... 29: self = .low
        case 30 ... 44: self = .subOptimal
        case 45 ... 59: self = .poor
        case 60 ... 74: self = .average
        case 75 ... 89: self = .good
        case 90 ... 100: self = .excellent
        default: self = .noData
        }
    }

    // Convenience init for resting heart rate (BPM)
    fileprivate init(heartRate: Double) {
        switch heartRate {
        case 1 ..< 40: self = .noData
        case 40 ... 59: self = .excellent
        case 60 ... 74: self = .good
        case 75 ... 84: self = .average
        case 85 ... 99: self = .subOptimal
        case 100...: self = .poor
        default: self = .noData
        }
    }

    // Convenience init for heart rate variability (milliseconds)
    fileprivate init(hrv: Double) {
        switch hrv {
        case 0 ..< 20: self = .poor
        case 20 ..< 40: self = .subOptimal
        case 40 ..< 60: self = .average
        case 60 ..< 100: self = .good
        case 100...: self = .excellent
        default: self = .noData
        }
    }

    // Convenience init for Cardio Load (ratio)
    fileprivate init(cardioLoad: Double) {
        switch cardioLoad {
        case 0.1 ..< 0.8: self = .low
        case 0.8 ..< 1.0: self = .subOptimal
        case 1.0 ..< 1.5: self = .good
        case 1.5 ..< 2.0: self = .average
        case 2.0...: self = .high
        default: self = .noData
        }
    }
}
