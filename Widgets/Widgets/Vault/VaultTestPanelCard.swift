//
//  VaultTestPanelCard.swift
//  Widgets
//
//  Created by Dom Montalto on 8/7/2026.
//

import SwiftUI

/// Composed test-panel card from the Figma design: shared gradient background,
/// white wash, then icon / title / body blended with `.overlay` so they pick
/// up the background hue.
struct VaultTestPanelCard: View {
    let panel: VaultTestPanel
    var cornerRadius: CGFloat = .cornerRadius40

    var body: some View {
        Color.clear
            .background {
                Image(panel.backgroundName)
                    .resizable()
                    .scaledToFill()
            }
            .overlay {
                Color.white.opacity(.minimalOpacity)
            }
            .overlay {
                content
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var content: some View {
        VStack(spacing: .spacing2x) {
            icon

            BrightText(panel.name, size: .heading, color: .black, weight: .regular)
                .multilineTextAlignment(.center)

            BrightText(panel.detail, size: .body2, color: .black)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .blendMode(.overlay)
        .padding(.spacing4x)
    }

    @ViewBuilder
    private var icon: some View {
        if let iconName = panel.iconName {
            Image(iconName)
        } else if let systemImage = panel.systemImage {
            Image(systemName: systemImage)
                .font(.system(size: 46, weight: .medium))
                .foregroundStyle(.black)
        }
    }
}

#Preview {
    VStack(spacing: .spacing3x) {
        VaultTestPanelCard(panel: VaultTestPanel.demo[0])
            .frame(width: 250, height: 312)

        VaultTestPanelCard(panel: VaultTestPanel.demo[2])
            .frame(height: 280)
    }
    .padding(.spacing3x)
    .background(Color.bG.ignoresSafeArea())
}
