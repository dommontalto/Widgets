//
//  BrightPageSheetView.swift
//  Widgets
//
//  Ported from Bright.
//

import SwiftUI
import UIKit

struct BrightPageSheetView<Content: View, Trailing: ToolbarContent>: View {
    let title: String
    let horizontalPadding: CGFloat
    let backgroundColor: Color
    let showCloseButton: Bool
    let showBackButton: Bool
    let backButtonCallback: (() -> Void)?
    let trailing: Trailing
    let content: Content

    @Environment(\.dismiss) private var dismiss

    init(
        title: String = "",
        horizontalPadding: CGFloat = .spacing3x,
        backgroundColor: Color = .sheetBackground,
        showCloseButton: Bool = true,
        showBackButton: Bool = false,
        backButtonCallback: (() -> Void)? = nil,
        @ToolbarContentBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.horizontalPadding = horizontalPadding
        self.backgroundColor = backgroundColor
        self.showCloseButton = showCloseButton
        self.showBackButton = showBackButton
        self.backButtonCallback = backButtonCallback
        self.trailing = trailing()
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            content
                .padding(.horizontal, horizontalPadding)
                .safeAreaPadding(.bottom)
                .scrollDismissesKeyboard(.interactively)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(backgroundColor.edgesIgnoringSafeArea(.all))
                .onTapGesture {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if showBackButton {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                if let backButtonCallback {
                                    backButtonCallback()
                                } else {
                                    dismiss()
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                        }
                    }
                    if showCloseButton && !showBackButton {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                    trailing
                }
        }
    }
}

struct EmptyToolbarContent: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            EmptyView()
        }
    }
}

extension BrightPageSheetView where Trailing == EmptyToolbarContent {
    init(
        title: String = "",
        horizontalPadding: CGFloat = .spacing3x,
        backgroundColor: Color = .sheetBackground,
        showCloseButton: Bool = true,
        showBackButton: Bool = false,
        backButtonCallback: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.horizontalPadding = horizontalPadding
        self.backgroundColor = backgroundColor
        self.showCloseButton = showCloseButton
        self.showBackButton = showBackButton
        self.backButtonCallback = backButtonCallback
        self.trailing = EmptyToolbarContent()
        self.content = content()
    }
}
