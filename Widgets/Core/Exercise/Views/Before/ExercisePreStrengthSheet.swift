//
//  ExercisePreStrengthSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 3/8/2026.
//

import SwiftUI

struct ExercisePreStrengthSheet: View {
    let session: ExerciseQuickSession
    // Which of the session's strength blocks this sets up.
    var leg = 0
    var chrome: ExercisePageChrome = .sheet
    // Ends the whole run. Only the flow can do that from a pushed leg, where
    // `dismiss` would pop back instead.
    var onClose: (() -> Void)?
    // Hands the session to the presenter, which pushes the live screen inside
    // the same presentation.
    var onStart: (ExerciseQuickSession) -> Void = { _ in }

    @Environment(ExerciseBuilder.self) private var builder
    @Environment(\.dismiss) private var dismiss

    @State private var openedExerciseName: String?
    @State private var isEditing = false

    // The contiguous stretch of lifts this leg runs; the whole list when the
    // leg is out of range.
    private var blockItems: [ExerciseTemplateItem] {
        session.legs[safe: leg].map(session.items(in:)) ?? session.strengthItems
    }

    var body: some View {
        page
            .navigationDestination(isPresented: $isEditing) {
                ExerciseCreateSessionSheet(editing: session) { isEditing = false }
            }
            .navigationDestination(item: $openedExerciseName) { name in
                if let exercise = ExerciseDemoLibrary.exercise(named: name) {
                    ExerciseDetailSheet(exercise: exercise, cardColor: .defaultCards)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .background(Color.defaultBackground.ignoresSafeArea())
                }
            }
    }

    @ViewBuilder private var page: some View {
        switch chrome {
        case .sheet:
            BrightPageSheetView(
                horizontalPadding: .spacing0x,
                backgroundColor: .defaultBackground,
                trailing: { ToolbarItem(placement: .topBarTrailing) { sourceMenu } }
            ) {
                content
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            ExerciseInlineTitle(file: #file)
                        }
                    }
            }

        case .pushed:
            BrightPageView(
                horizontalPadding: .spacing0x,
                backgroundColor: .defaultBackground,
                toolbar: {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            close()
                        } label: {
                            Label("Close", systemImage: "xmark")
                                .labelStyle(.iconOnly)
                        }
                    }

                    ToolbarItem(placement: .principal) {
                        ExerciseInlineTitle(file: #file)
                    }

                    ToolbarItem(placement: .topBarTrailing) { sourceMenu }
                },
                content: { content }
            )
        }
    }

    // Where the session records, decided once at this first gate. The watch
    // option is part 3, with the watch app — shown but not pickable.
    private var sourceMenu: some View {
        Menu {
            Picker("Start session on", selection: Bindable(builder).source) {
                Label(ExerciseSessionSource.phone.title, systemImage: "iphone")
                    .tag(ExerciseSessionSource.phone)
            }

            Button {
            } label: {
                Label(ExerciseSessionSource.phoneAndWatch.title, systemImage: "applewatch")
            }
            .disabled(true)
        } label: {
            // The Menu owns the tap, so the glyphs are label only.
            ExerciseDeviceGlyphs(symbols: builder.source.symbols)
                .allowsHitTesting(false)
        }
        .brightHaptic(.light, trigger: builder.source)
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing3x) {
                header

                statsRow

                exerciseRows
            }
            .padding(.spacing3x)
        }
        .safeAreaInset(edge: .bottom) {
            controls
        }
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: session.symbol)
                .font(.standard(size: .huge2, weight: .light))
                .foregroundStyle(Color.textColor)

            BrightText(session.name, size: .standout3, scaleTextSize: 0.7)
                .lineLimit(1)
        }
    }

    private var statsRow: some View {
        HStack(spacing: .spacing0x) {
            statColumn(
                symbol: "text.line.magnify",
                color: .lightTextColor,
                label: "Exercises:",
                value: "\(blockItems.count)"
            )

            BrightVerticalDivider(height: Constants.statDividerHeight)
                .padding(.horizontal, .spacing2x)

            statColumn(
                symbol: "text.line.3.summary",
                color: .lightTextColor,
                label: "Total sets:",
                value: "\(totalSets)"
            )

            Spacer(minLength: .spacing0x)
        }
    }

    private func statColumn(
        symbol: String,
        color: Color,
        label: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing1x) {
                Image(systemName: symbol)
                    .font(.standard(size: .body1, weight: .regular))
                    .foregroundStyle(color)

                BrightText(label, size: .body1)
                    .lineLimit(1)
                    .fixedSize()
            }

            BrightText(value, size: .huge)
                .monospacedDigit()
        }
        .frame(width: Constants.statColumnWidth, alignment: .leading)
    }

    // MARK: - Exercises

    private var exerciseRows: some View {
        VStack(spacing: .spacing2x) {
            ForEach(blockItems) { item in
                Button {
                    openedExerciseName = item.exerciseName
                } label: {
                    exerciseRow(item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // Mirrors ExerciseLibraryRow, with the set count where its add button sits.
    private func exerciseRow(_ item: ExerciseTemplateItem) -> some View {
        HStack(spacing: .spacing2x) {
            thumbnail(for: item)

            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(item.exerciseName, size: .body2, weight: .regular)
                    .fixedSize(horizontal: false, vertical: true)

                BrightText(subtitle(for: item), size: .body3, color: .lightTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: .spacing2x)

            BrightText(setsLabel(for: item), size: .subheading, color: .lightTextColor)
                .monospacedDigit()
                .fixedSize()
                .padding(.trailing, .spacing1x)
        }
        .padding(.spacing2x)
        .frame(maxWidth: .infinity, minHeight: ExerciseLibraryRow.Constants.minHeight, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    @ViewBuilder
    private func thumbnail(for item: ExerciseTemplateItem) -> some View {
        if let exercise = ExerciseDemoLibrary.exercise(named: item.exerciseName) {
            Image(systemName: exercise.symbol)
                .font(.standard(size: .standout3, weight: .light))
                .foregroundStyle(Color.lightTextColor)
                .frame(width: Constants.thumbnailWidth)
        } else {
            Color.clear
                .frame(width: Constants.thumbnailWidth)
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: .spacing2x) {
            Menu {
                // The menu opens upward from the foot of the sheet, so it is
                // declared bottom-up to land Delete at the bottom.
                Button("Delete", systemImage: "trash", role: .destructive) {
                    builder.delete(session)
                    close()
                }
                .tint(.defaultRed)

                Button("Edit", systemImage: "pencil") {
                    builder.loadDraft(from: session)
                    isEditing = true
                }

                Button("Duplicate", systemImage: "plus.square.on.square") {
                    withAnimation(.brightSnappy) { builder.duplicate(session) }
                }
            } label: {
                BrightRoundButton(systemImage: "ellipsis", size: .finalBossLarge)
                    .allowsHitTesting(false)
            }

            Spacer(minLength: .spacing2x)

            BrightRoundButton(systemImage: "play.fill", size: .finalBossLarge, color: .defaultGreen) {
                onStart(session)
            }
        }
        .padding(.spacing4x)
    }

    // MARK: - Derived state

    private var totalSets: Int {
        blockItems.reduce(0) { $0 + setCount(for: $1) }
    }

    private func setCount(for item: ExerciseTemplateItem) -> Int {
        Int(item.target.prefix { $0.isNumber }) ?? 0
    }

    private func setsLabel(for item: ExerciseTemplateItem) -> String {
        let count = setCount(for: item)
        return "\(count) set\(count == 1 ? "" : "s")"
    }

    private func subtitle(for item: ExerciseTemplateItem) -> String {
        guard let exercise = ExerciseDemoLibrary.exercise(named: item.exerciseName) else {
            return item.target
        }
        return "\(exercise.primaryMuscle.displayName) \u{2022} \(exercise.equipmentLabel)"
    }

    private enum Constants {
        static let statColumnWidth: CGFloat = 110
        static let statDividerHeight: CGFloat = 58
        static let thumbnailWidth: CGFloat = 40
        static let controlSize = BrightButtonSizes.finalBossLarge.rawValue
    }
}

// A device reads as one glyph, a pairing as both with a plus between them.
struct ExerciseDeviceGlyphs: View {
    let symbols: [String]

    var body: some View {
        HStack(spacing: .spacing05x) {
            ForEach(Array(symbols.enumerated()), id: \.offset) { index, symbol in
                if index != 0 {
                    Image(systemName: "plus")
                        .imageScale(.small)
                }

                Image(systemName: symbol)
            }
        }
        .foregroundStyle(Color.textColor)
    }
}

#Preview {
    Color.defaultBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ExercisePreStrengthSheet(session: ExerciseDemoSessions.quickPush)
                .environment(ExerciseBuilder())
        }
}
