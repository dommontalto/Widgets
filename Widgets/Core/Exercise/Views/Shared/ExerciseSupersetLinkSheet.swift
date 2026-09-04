//
//  ExerciseSupersetLinkSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

struct ExerciseSupersetCandidate: Identifiable, Equatable {
    let id: String
    let name: String
}

// Picks the one lift to superset with the lift this was opened from, which
// heads the list already ticked. A superset holds two, so ticking another
// candidate swaps it in, and Link with nothing else ticked breaks the pair.
struct ExerciseSupersetLinkSheet: View {
    let anchor: ExerciseSupersetCandidate
    let candidates: [ExerciseSupersetCandidate]
    let onLink: (String?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var partner: String?

    init(
        anchor: ExerciseSupersetCandidate,
        candidates: [ExerciseSupersetCandidate],
        partner: String?,
        onLink: @escaping (String?) -> Void
    ) {
        self.anchor = anchor
        self.candidates = candidates
        self.onLink = onLink
        _partner = State(initialValue: partner)
    }

    var body: some View {
        BrightPageSheetView(
            title: "Superset",
            horizontalPadding: .spacing0x,
            showCloseButton: false,
            showBackButton: true,
            backButtonCallback: { dismiss() },
            trailing: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Link") {
                        onLink(partner)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.defaultSkyBlue)
                }
            },
            content: {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: .spacing3x) {
                        header

                        VStack(spacing: .spacing2x) {
                            row(anchor)
                                .disabled(true)

                            ForEach(candidates) { candidate in
                                row(candidate)
                            }
                        }
                    }
                    .padding(.spacing3x)
                }
            }
        )
        .animation(.brightSnappy, value: partner)
    }

    private var header: some View {
        VStack(spacing: .spacing2x) {
            Image(systemName: "link")
                .font(.standard(size: .standout3, weight: .medium))
                .foregroundStyle(Color.defaultPink)

            BrightText("Link with", size: .standout3, color: .semiLightTextColor, weight: .regular)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacing3x)
    }

    private func row(_ candidate: ExerciseSupersetCandidate) -> some View {
        Button {
            partner = partner == candidate.id ? nil : candidate.id
        } label: {
            HStack(spacing: .spacing2x) {
                thumbnail(for: candidate)

                VStack(alignment: .leading, spacing: .spacing05x) {
                    BrightText(candidate.name, size: .body2, weight: .regular)
                        .fixedSize(horizontal: false, vertical: true)

                    BrightText(subtitle(for: candidate), size: .body3, color: .lightTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: .spacing2x)

                BrightTick(isTicked: isTicked(candidate), tickTint: .defaultPink)
                    .frame(width: ExerciseLibraryRow.Constants.tickTouchSize,
                           height: ExerciseLibraryRow.Constants.tickTouchSize)
            }
            .padding(.spacing2x)
            .frame(maxWidth: .infinity, minHeight: ExerciseLibraryRow.Constants.minHeight, alignment: .leading)
            .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius18))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func isTicked(_ candidate: ExerciseSupersetCandidate) -> Bool {
        candidate.id == anchor.id || candidate.id == partner
    }

    @ViewBuilder
    private func thumbnail(for candidate: ExerciseSupersetCandidate) -> some View {
        if let definition = ExerciseDemoLibrary.exercise(named: candidate.name) {
            Image(systemName: definition.symbol)
                .font(.standard(size: .standout3, weight: .light))
                .foregroundStyle(Color.lightTextColor)
                .frame(width: ExerciseLibraryRow.Constants.thumbnailWidth)
        } else {
            Color.clear
                .frame(width: ExerciseLibraryRow.Constants.thumbnailWidth)
        }
    }

    private func subtitle(for candidate: ExerciseSupersetCandidate) -> String {
        guard let definition = ExerciseDemoLibrary.exercise(named: candidate.name) else { return "" }
        return "\(definition.primaryMuscle.displayName) \u{2022} \(definition.equipmentLabel)"
    }
}

#Preview {
    ExerciseSupersetLinkSheet(
        anchor: ExerciseSupersetCandidate(id: "Barbell Back Squat", name: "Barbell Back Squat"),
        candidates: [
            ExerciseSupersetCandidate(id: "Bench Press", name: "Bench Press"),
            ExerciseSupersetCandidate(id: "Shoulder Press", name: "Shoulder Press"),
        ],
        partner: "Bench Press"
    ) { _ in }
}
