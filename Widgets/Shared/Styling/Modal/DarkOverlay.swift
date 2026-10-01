//
//  DarkOverlay.swift
//  Widgets
//
//  Created by Zoe Friedman on 12/9/2023.
//

import SwiftUI

struct DarkOverlay: View {
    var body: some View {
        Color.black
            .opacity(0.8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
            .transition(.opacity)
    }
}

#Preview {
    DarkOverlay()
}
