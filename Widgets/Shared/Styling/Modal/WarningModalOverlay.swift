//
//  WarningModalOverlay.swift
//  Widgets
//
//  Created by Zoe Friedman on 17/10/2023.
//

import SwiftUI

struct WarningModalOverlay: ViewModifier {
    @Binding var showing: Bool
    let message: String
    let buttonTitle: String
    let onTapCallback: (() -> Void)?

    func body(content: Content) -> some View {
        ZStack {
            content
            if showing {
                modalOverlay
            }
        }
        .animation(.brightSpring, value: showing)
    }

    var modalOverlay: some View {
        ZStack {
            DarkOverlay()
                .onTapGesture {
                    withAnimation {
                        showing = false
                    }
                }
            modal
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .edgesIgnoringSafeArea(.all)
        .transition(.opacity)
    }

    var modal: some View {
        WarningModal(
            message: message,
            buttonTitle: buttonTitle,
            onTapCallback: {
                onTapCallback?()
                showing = false
            }
        )
    }
}

#Preview {
    VStack {
        Text("Hello world")
        Spacer()
    }
    .modifier(WarningModalOverlay(
        showing: Binding.constant(true),
        message: "Are you sure?",
        buttonTitle: "Yes",
        onTapCallback: {}
    ))
}
