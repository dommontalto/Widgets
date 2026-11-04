//
//  VaultUploadRecordsView.swift
//  Widgets
//
//  Created by Dom Montalto on 4/11/2026.
//

import SwiftUI

enum VaultUploadRecordKind: String, CaseIterable, Identifiable, Hashable {
    case prescriptions
    case healthRecords
    case mri

    var id: String { rawValue }

    var title: String {
        switch self {
        case .prescriptions: "Prescriptions"
        case .healthRecords: "Health Records"
        case .mri: "MRI"
        }
    }

    var imageName: String {
        switch self {
        case .prescriptions: ImageNames.vaultUploadPrescriptionsV5
        case .healthRecords: ImageNames.vaultUploadHealthRecordsV5
        case .mri: ImageNames.vaultUploadMriV5
        }
    }
}

struct VaultUploadRecordsView: View {
    var canScan = true
    let onScan: () -> Void
    let onChooseImage: () -> Void
    let onChooseFile: () -> Void
    let onImportFromApp: () -> Void

    var body: some View {
        VStack(spacing: .spacing0x) {
            VaultUploadRecordsMarquee()
                .padding(.top, .spacing12x + .spacing4x)

            VStack(spacing: .spacing3x) {
                BrightText("Upload Records", size: .standout1)

                BrightText("PDFs, DOCX, images & DNA files all supported", size: .body1, color: .lightTextColor)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, .spacing3x)
            .padding(.top, .spacing10x)

            Spacer(minLength: .spacing4x)

            uploadMenu
                .padding(.bottom, .spacing4x)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var uploadMenu: some View {
        Menu {
            if canScan {
                Button(action: onScan) {
                    Label("Scan", systemImage: "document.viewfinder.fill")
                }
            }

            Button(action: onChooseImage) {
                Label("Choose image", systemImage: "photo")
            }

            Button(action: onChooseFile) {
                Label("Choose file", systemImage: "folder.badge.plus")
            }

            Button(action: onImportFromApp) {
                Label("Import from app", systemImage: "sharedwithyou")
            }
        } label: {
            BrightPillButton("Upload", systemImage: "arrow.up", buttonSize: .large) {}
                .allowsHitTesting(false)
        }
        .menuOrder(.fixed)
    }
}

// The record types drifting left at a steady pace, forever. The one passing the
// middle is full size and the rest shrink, each with its name above it. A drag
// takes over and a flick carries on with momentum before the drift picks back up.
private struct VaultUploadRecordsMarquee: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var width: CGFloat = 0
    @State private var anchorDate = Date.now
    @State private var anchorShift: CGFloat = 0
    @State private var momentum: CGFloat = 0
    @State private var dragTranslation: CGFloat?
    @State private var hapticTrigger = 0

    private let kinds = VaultUploadRecordKind.allCases

    private var itemSize: CGFloat { width * Constants.itemWidthRatio }
    private var pitch: CGFloat { width * Constants.pitchRatio }
    private var speed: CGFloat { reduceMotion ? 0 : Constants.speed }

    var body: some View {
        TimelineView(.animation(paused: reduceMotion && dragTranslation == nil)) { context in
            let total = shift(at: context.date)
            let cycle = pitch * CGFloat(kinds.count)
            let wrapped = cycle > 0 ? (total.truncatingRemainder(dividingBy: cycle) + cycle).truncatingRemainder(dividingBy: cycle) : 0
            let centred = pitch > 0 ? Int((total / pitch).rounded()) : 0

            ZStack {
                ForEach((kinds.count - 2)...(kinds.count * 2 + 3), id: \.self) { slot in
                    item(kinds[slot % kinds.count], x: width / 2 + CGFloat(slot - kinds.count - 1) * pitch - wrapped)
                }
            }
            .onChange(of: centred) {
                if isInteracting(at: context.date) { hapticTrigger += 1 }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: itemSize + Constants.labelGap + Constants.labelHeight)
        .contentShape(Rectangle())
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { width = $0 }
        .gesture(drag)
        .brightHapticV5(.soft, trigger: hapticTrigger)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: Constants.dragThreshold)
            .onChanged { value in
                if dragTranslation == nil {
                    anchorShift = shift(at: .now)
                    momentum = 0
                }
                dragTranslation = value.translation.width
            }
            .onEnded { value in
                anchorShift -= value.translation.width
                anchorDate = .now
                momentum = reduceMotion ? 0 : min(max(-value.velocity.width, -Constants.maxMomentum), Constants.maxMomentum)
                dragTranslation = nil
            }
    }

    // How far the strip has travelled: the steady drift, plus a flick's momentum
    // easing out, or the finger's position while dragging.
    private func shift(at date: Date) -> CGFloat {
        if let dragTranslation { return anchorShift - dragTranslation }
        let elapsed = CGFloat(max(date.timeIntervalSince(anchorDate), 0))
        let glide = momentum * Constants.momentumDecay * (1 - exp(-elapsed / Constants.momentumDecay))
        return anchorShift + speed * elapsed + glide
    }

    private func isInteracting(at date: Date) -> Bool {
        dragTranslation != nil
            || (momentum != 0 && CGFloat(date.timeIntervalSince(anchorDate)) < Constants.momentumDecay * 3)
    }

    private func item(_ kind: VaultUploadRecordKind, x: CGFloat) -> some View {
        let distance = pitch > 0 ? min(abs(x - width / 2) / pitch, 1) : 0
        let size = itemSize * (1 - (1 - Constants.sideScale) * distance)
        let centerY = Constants.labelHeight + Constants.labelGap + itemSize / 2

        return ZStack {
            BrightText(kind.title, size: .subheading1, color: .semiLightTextColor)
                .lineLimit(1)
                .fixedSize()
                .frame(height: Constants.labelHeight)
                .position(x: x, y: centerY - size / 2 - Constants.labelGap - Constants.labelHeight / 2)

            Image(kind.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .position(x: x, y: centerY)
        }
    }

    private enum Constants {
        static let itemWidthRatio: CGFloat = 0.44
        static let pitchRatio: CGFloat = 0.46
        static let sideScale: CGFloat = 0.76
        static let speed: CGFloat = 40
        static let labelHeight: CGFloat = .spacing4x
        static let labelGap: CGFloat = .spacing2x
        static let dragThreshold: CGFloat = 5
        static let maxMomentum: CGFloat = 2500
        // Seconds for a flick's extra speed to fall to about a third.
        static let momentumDecay: CGFloat = 0.35
    }
}

#Preview {
    VaultUploadRecordsView(onScan: {}, onChooseImage: {}, onChooseFile: {}, onImportFromApp: {})
        .background(Color.defaultSheetBackground)
}
