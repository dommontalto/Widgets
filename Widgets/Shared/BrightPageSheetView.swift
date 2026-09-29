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
    // Set false to let content run under the home indicator, e.g. a full-bleed map.
    let bottomSafeArea: Bool
    let path: Binding<NavigationPath>?
    // Pass nil when the sheet puts its own view in the principal slot.
    let file: String?
    let trailing: Trailing
    let content: Content

    @Environment(\.dismiss) private var dismiss

    init(
        title: String = "",
        horizontalPadding: CGFloat = .spacing3x,
        backgroundColor: Color = .defaultSheetBackground,
        showCloseButton: Bool = true,
        showBackButton: Bool = false,
        backButtonCallback: (() -> Void)? = nil,
        bottomSafeArea: Bool = true,
        path: Binding<NavigationPath>? = nil,
        file: String? = #file,
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
        self.file = file
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
                .brightSoftScrollEdges()
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
                                Label("Back", systemImage: "chevron.left")
                                    .labelStyle(.iconOnly)
                            }
                        }
                    }
                    if showCloseButton && !showBackButton {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                Label("Close", systemImage: "xmark")
                                    .labelStyle(.iconOnly)
                            }
                        }
                    }
                    if let file {
                        ToolbarItem(placement: .principal) {
                            ExerciseInlineTitle(title: title, file: file)
                        }
                    }
                    trailing
                }
    }
}

extension BrightPageSheetView where Trailing == EmptyToolbarContent {
    init(
        title: String = "",
        horizontalPadding: CGFloat = .spacing3x,
        backgroundColor: Color = .defaultSheetBackground,
        showCloseButton: Bool = true,
        showBackButton: Bool = false,
        backButtonCallback: (() -> Void)? = nil,
        bottomSafeArea: Bool = true,
        path: Binding<NavigationPath>? = nil,
        file: String? = #file,
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
        self.file = file
        self.trailing = EmptyToolbarContent()
        self.content = content()
    }
}
