//
//  BrightPageSheetView.swift
//  Bright
//
//  Copyright © 2026 Bryan Jordan. All rights reserved.
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
    /// Set false to let content run under the home indicator, e.g. a full-bleed map.
    let bottomSafeArea: Bool
    let path: Binding<NavigationPath>?
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
        bottomSafeArea: Bool = true,
        path: Binding<NavigationPath>? = nil,
        @ToolbarContentBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.horizontalPadding = horizontalPadding
        self.backgroundColor = backgroundColor
        self.showCloseButton = showCloseButton
        self.showBackButton = showBackButton
        self.backButtonCallback = backButtonCallback
        self.bottomSafeArea = bottomSafeArea
        self.path = path
        self.trailing = trailing()
        self.content = content()
    }

    var body: some View {
        if let path {
            NavigationStack(path: path) { stackContent }
        } else {
            NavigationStack { stackContent }
        }
    }

    private var stackContent: some View {
        content
                .padding(.horizontal, horizontalPadding)
                .safeAreaPadding(bottomSafeArea ? .bottom : [])
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
                        ToolbarItem(placement: .topBarLeading) {
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
        bottomSafeArea: Bool = true,
        path: Binding<NavigationPath>? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.horizontalPadding = horizontalPadding
        self.backgroundColor = backgroundColor
        self.showCloseButton = showCloseButton
        self.showBackButton = showBackButton
        self.backButtonCallback = backButtonCallback
        self.bottomSafeArea = bottomSafeArea
        self.path = path
        self.trailing = EmptyToolbarContent()
        self.content = content()
    }
}
