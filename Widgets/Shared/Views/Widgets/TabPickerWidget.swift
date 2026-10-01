//
//  TabPickerWidget.swift
//  Widgets
//
//  Created by Ian Tran on 11/12/2025.
//

import SwiftUI

struct TabPickerWidget<T: TabDisplayable>: View {
    @Binding var selectedTab: T
    let tabs: [T]
    var body: some View {
        Picker("", selection: $selectedTab) {
            ForEach(tabs, id: \.self) { tab in
                BrightText(tab.displayTitle, size: .body1)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.bottom, .spacing2x)
    }
}
