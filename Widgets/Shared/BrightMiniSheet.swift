//
//  BrightMiniSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 14/7/2026.
//

import SwiftUI

private struct BrightMiniSheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct BrightMiniSheet<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder var sheetContent: () -> SheetContent

    @State private var sheetHeight: CGFloat = 220

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                sheetContent()
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(key: BrightMiniSheetHeightKey.self, value: proxy.size.height)
                        }
                    )
                    .onPreferenceChange(BrightMiniSheetHeightKey.self) { if $0 > 0 { sheetHeight = $0 } }
                    .presentationDetents([.height(sheetHeight)])
                    .presentationCornerRadius(.cornerRadius50)
                    .presentationDragIndicator(.hidden)
                    .presentationBackgroundInteraction(.enabled)
            }
    }
}

extension View {
    func brightMiniSheet(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        modifier(BrightMiniSheet(isPresented: isPresented, sheetContent: content))
    }
}
