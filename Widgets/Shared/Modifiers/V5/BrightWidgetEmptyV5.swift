//
//  BrightWidgetEmptyV5.swift
//  Widgets
//
//  Created by Dom Montalto on 15/10/2026.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var brightWidgetIsEmpty = false
}

extension View {
    func brightWidgetEmptyV5(_ isEmpty: Bool = true) -> some View {
        environment(\.brightWidgetIsEmpty, isEmpty)
    }
}

extension String {
    static let brightEmptyValue = "–"
}
