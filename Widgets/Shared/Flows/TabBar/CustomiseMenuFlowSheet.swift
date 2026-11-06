//
//  CustomiseMenuFlowSheet.swift
//  Widgets
//
//  Created by Amin Zabihi on 30/12/2025.
//

import SwiftUI

struct CustomiseMenuFlowSheet: View {
    let onDismiss: () -> Void
    @State private var editorVM = CustomiseMenuViewModel()

    var body: some View {
        NavigationStack {
            CustomiseMenuView(viewModel: editorVM)
        }
        .onChange(of: editorVM.didSave) {
            if editorVM.didSave {
                editorVM.didSave = false
                onDismiss()
            }
        }
    }
}
