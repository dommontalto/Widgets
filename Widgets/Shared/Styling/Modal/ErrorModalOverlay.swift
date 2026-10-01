//
//  ErrorModalOverlay.swift
//  Widgets
//
//  Created by Zoe Friedman on 25/7/2023.
//

import SwiftUI

struct ErrorModalOverlay: ViewModifier {
    @Binding var showing: Bool
    let errorMessage: String
    let onTapCallback: (() -> Void)?

    init(showing: Binding<Bool>, errorMessage: String = "Something went wrong", onTapCallback: (() -> Void)? = nil) {
        _showing = showing
        self.errorMessage = errorMessage
        self.onTapCallback = onTapCallback
    }

    func body(content: Content) -> some View {
        ZStack {
            content
                .alert(errorMessage, isPresented: $showing) {
                    Button("OK", role: .cancel) {}
                }
            /* TODO: Remove this code when not required
             if showing {
                 modalOverlay
             }
              */
        }
        .animation(.brightSpring, value: showing)
    }

    var modalOverlay: some View {
        ZStack {
            DarkOverlay()
            modal
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .edgesIgnoringSafeArea(.all)
        .transition(.opacity)
    }

    var modal: some View {
        ErrorModal(errorMessage: errorMessage, onTapCallback: {
            onTapCallback?()
            showing = false
        })
    }
}

#Preview {
    VStack {
        Text("Hello world")
        Spacer()
    }
    .modifier(ErrorModalOverlay(showing: Binding.constant(true)))
}
