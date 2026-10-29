//
//  SideMenuView.swift
//  Widgets
//

import SwiftUI

// The iOS app's side menu. Labs, DNA and Edit Home screen work;
// the account rows and Log out are laid out but inert.
struct SideMenuView: View {
    @Binding var isExpanded: Bool
    let onLabs: () -> Void
    let onDNA: () -> Void
    let onEditHomescreen: () -> Void

    @State private var showingWhatsNew = false
    @State private var visibleRows: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            header
                .padding(.top, .spacing2x)
                .padding(.bottom, .spacing6x)

            VStack(alignment: .leading, spacing: .spacing3x) {
                tile(image: ImageNames.sideMenuLabsV5, title: "Labs", action: onLabs)
                    .staggered(at: 0, in: visibleRows)
                tile(image: ImageNames.sideMenuDNAV5, title: "DNA", action: onDNA)
                    .staggered(at: 1, in: visibleRows)
            }

            Rectangle()
                .fill(Color.textColor.opacity(.veryLowOpacity))
                .frame(height: Constants.dividerHeight)
                .padding(.vertical, .spacing4x)
                .staggered(at: 2, in: visibleRows)

            VStack(alignment: .leading, spacing: .spacing4x) {
                item(systemImage: "person.fill", color: .defaultGreen, title: "Personal Details")
                    .staggered(at: 3, in: visibleRows)
                item(systemImage: "shippingbox.fill", color: .defaultYellow, title: "My Orders")
                    .staggered(at: 4, in: visibleRows)
                item(image: ImageNames.sideMenuEditHomeV5, title: "Edit Home screen", action: onEditHomescreen)
                    .staggered(at: 5, in: visibleRows)
                item(systemImage: "iphone.gen3", color: .defaultWaveBlue, title: "App Settings")
                    .staggered(at: 6, in: visibleRows)
                item(systemImage: "creditcard.fill", color: .defaultPink, title: "Manage Subscription")
                    .staggered(at: 7, in: visibleRows)
            }

            VStack(alignment: .leading, spacing: .spacing4x) {
                item(systemImage: "text.document", color: .defaultRed, title: "Legal")
                    .staggered(at: 9, in: visibleRows)
                item(systemImage: "ladybug.fill", color: .defaultWaveMagenta, title: "Report a bug")
                    .staggered(at: 10, in: visibleRows)
            }
            .padding(.top, .spacing10x)

            Spacer(minLength: .spacing4x)

            VStack(spacing: .spacing2x) {
                BrightPillButton("Log out", systemImage: "arrow.backward", buttonSize: .large) {}

                versionIdentifier
            }
            .frame(maxWidth: .infinity)
            .staggered(at: 11, in: visibleRows)
        }
        .padding(.horizontal, .spacing3x)
        .padding(.bottom, .spacing2x)
        .task(id: isExpanded) {
            guard isExpanded else {
                withAnimation(.easeOut(duration: Constants.rowExitDuration)) { visibleRows.removeAll() }
                return
            }

            visibleRows = []
            try? await Task.sleep(for: .seconds(Constants.rowStartDelay))
            for i in 0 ..< Constants.rowCount {
                guard !Task.isCancelled else { return }
                withAnimation(.bouncy(duration: Constants.animationDuration, extraBounce: Constants.bounce)) {
                    _ = visibleRows.insert(i)
                }
                try? await Task.sleep(for: .seconds(Constants.rowStaggerDelay))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.defaultBackground.ignoresSafeArea())
        .sheet(isPresented: $showingWhatsNew) {
            BrightWhatsNewSheetV5()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(Constants.demoName, size: .standout1)
            BrightText(Constants.demoLifetime, size: .body3, color: .semiLightTextColor)
        }
    }

    private func tile(image: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: .spacing2x) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.tileSize, height: Constants.tileSize)
                BrightText(title, size: .body1)
                Spacer()
            }
            .contentShape(Rectangle())
        }
    }

    private func item(systemImage: String, color: Color, title: String, action: @escaping () -> Void = {}) -> some View {
        row(title: title, action: action) {
            Image(systemName: systemImage)
                .font(.system(size: Constants.symbolSize, weight: .regular))
                .foregroundStyle(color)
        }
    }

    private func item(image: String, title: String, action: @escaping () -> Void) -> some View {
        row(title: title, action: action) {
            Image(image)
                .resizable()
                .scaledToFit()
        }
    }

    private func row(title: String, action: @escaping () -> Void, @ViewBuilder icon: () -> some View) -> some View {
        Button(action: action) {
            HStack(spacing: .spacing1x) {
                icon()
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                BrightText(title, size: .body1, color: .semiLightTextColor)
                Spacer()
            }
            .contentShape(Rectangle())
        }
    }

    private var versionIdentifier: some View {
        VStack(spacing: .spacing025x) {
            BrightText(
                "Build \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1.0"))",
                size: .body5,
                color: .semiLightTextColor
            )
            BrightText("Dev", size: .body5, color: .lightTextColor)
        }
    }

    private enum Constants {
        static let demoName = "Dom"
        static let demoLifetime = "Lifetime user no. 1"
        static let iconSize: CGFloat = 24
        static let tileSize: CGFloat = 36
        static let symbolSize: CGFloat = 20
        static let dividerHeight: CGFloat = 0.5
        static let rowCount: Int = 12
        static let animationDuration: TimeInterval = 0.3
        static let bounce: TimeInterval = 0.1
        static let rowStaggerDelay: TimeInterval = 0.03
        static let rowStartDelay: TimeInterval = 0.02
        static let rowExitDuration: TimeInterval = 0.15
    }
}

private extension View {
    func staggered(at index: Int, in visibleRows: Set<Int>) -> some View {
        let isVisible = visibleRows.contains(index)
        return opacity(isVisible ? 1 : 0)
            .offset(x: isVisible ? 0 : -40)
    }
}
