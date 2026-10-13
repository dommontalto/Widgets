//
//  BrightStatusIconV5.swift
//  Widgets
//
//  Created by Vinh Tran on 19/2/2026.
//

import SwiftUI

struct BrightStatusIconV5: View {
    var status: ScoresStatus?
    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        switch status {
        case .optimal: Image(ImageNames.circleCheckmarkV5).resizable().scaledToFit().frame(
                width: 24,
                height: 24
            )
        case .borderline: Image(ImageNames.warningDiamondYellowV4).resizable().scaledToFit().frame(
                width: 24,
                height: 24
            )
        case .high, .low: Image(ImageNames.warningDiamondV4).resizable().scaledToFit().frame(width: 24, height: 24)
        case nil: EmptyView()
        }
    }

    init(status: ScoresStatus?) {
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
    fileprivate init?(value: Double) {
        switch value {
        case 0 ..< 30: self = .low
        case 30 ..< 60: self = .borderline
        case 60 ... 100: self = .optimal
        default: return nil
        }
    }

    fileprivate init?(heartRate: Double) {
        switch heartRate {
        case 40 ..< 85: self = .optimal
        case 85...: self = .borderline
        default: return nil
        }
    }

    fileprivate init?(hrv: Double) {
        switch hrv {
        case 0 ..< 40: self = .borderline
        case 40...: self = .optimal
        default: return nil
        }
    }

    fileprivate init?(cardioLoad: Double) {
        switch cardioLoad {
        case 0.1 ..< 0.8: self = .low
        case 0.8 ..< 1.0: self = .borderline
        case 1.0 ..< 2.0: self = .optimal
        case 2.0...: self = .high
        default: return nil
        }
    }
}
