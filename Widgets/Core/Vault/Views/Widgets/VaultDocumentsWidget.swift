//
//  VaultDocumentsWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 4/11/2026.
//

import SwiftUI

struct VaultDocumentsWidget: View {
    let documents: [VaultDocumentSummary]
    var onExpand: (() -> Void)?
    var onOpen: ((VaultDocumentSummary) -> Void)?

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            header
                .padding(.spacing3x)

            ForEach(documents) { document in
                BrightRowV5(
                    document.labName,
                    subtitle: document.listSubtitle,
                    trailing: .chevron
                ) {
                    onOpen?(document)
                }

                if document.id != documents.last?.id {
                    BrightDividerV5(thickness: 1 / displayScale)
                        .padding(.horizontal, .spacing3x)
                }
            }
        }
        .environment(\.isInBrightRowGroup, true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(BrightCardModifierV5())
    }

    private var header: some View {
        HStack(alignment: .top) {
            BrightText("Last \(documents.count) uploaded", size: .body1, color: .semiLightTextColor)

            Spacer()

            if let onExpand {
                BrightRoundButton(systemImage: "arrow.down.backward.and.arrow.up.forward", onTapCallback: onExpand)
            }
        }
    }
}

#Preview {
    VaultDocumentsWidget(documents: VaultDemo.documents)
        .padding(.spacing3x)
        .background(Color.defaultBackground)
}
