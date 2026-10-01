//
//  BrightProgressViewV5.swift
//  Widgets
//

import SwiftUI

struct BrightProgressViewV5: View {
    var body: some View {
        ProgressView()
            .controlSize(.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
extension View {
    func brightProgressViewV5(isShowing: Binding<Bool>) -> some View {
        overlay {
            if isShowing.wrappedValue {
                BrightProgressViewV5()
                    .transition(.opacity)
            }
        }
        .animation(.brightEaseInOut, value: isShowing.wrappedValue)
    }
}

