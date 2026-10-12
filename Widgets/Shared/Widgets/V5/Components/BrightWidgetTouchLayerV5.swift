//
//  BrightWidgetTouchLayerV5.swift
//  Widgets
//
//  Created by Dom Montalto on 13/10/2026.
//

import Charts
import SwiftUI

struct BrightWidgetTouchLayerV5: View {
    @Binding var touch: UnitPoint?

    @State private var touchX: Double?
    @State private var touchY: Double?

    var body: some View {
        Chart {
            PointMark(x: .value("X", 0.5), y: .value("Y", 0.5))
                .opacity(.zero)
        }
        .chartXScale(domain: 0 ... 1)
        .chartYScale(domain: 0 ... 1)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartXSelection(value: $touchX)
        .chartYSelection(value: $touchY)
        .onChange(of: touchX) { resolve() }
        .onChange(of: touchY) { resolve() }
        .onDisappear { touch = nil }
    }

    private func resolve() {
        guard let touchX, let touchY else {
            touch = nil
            return
        }
        touch = UnitPoint(x: touchX, y: 1 - touchY)
    }
}
