//
//  ExerciseCustomiseSetsView.swift
//  Widgets
//
//  Created by Dom Montalto on 29/7/2026.
//

import SwiftUI

private struct ExerciseSwapTarget: Identifiable {
    let id: String
}

struct ExerciseCustomiseSetsView: View {
    var onSave: () -> Void

    @Environment(ExerciseSessionBuilder.self) private var builder

    @FocusState private var isTyping: Bool
    @State private var name = ""
    @State private var symbol = ExerciseSessionIcon.allCases[0]
    @State private var swapTarget: ExerciseSwapTarget?
    @State private var isAddingExercise = false
    @State private var addedExercise: String?

    var body: some View {
        ScrollViewReader { scroller in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: .spacing3x) {
                    nameField

                    iconPicker

                    ForEach(builder.added, id: \.self) { exercise in
                        exerciseCard(exercise)
                            .id(exercise)
                    }

                    BrightPillButton("Add exercise", systemImage: "plus", buttonSize: .medium) {
                        isAddingExercise = true
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, .spacing3x)
                .padding(.top, .spacing2x)
                .padding(.bottom, .spacing4x)
            }
            .onChange(of: addedExercise) { _, exercise in
                guard let exercise else { return }
                withAnimation(.brightEaseInOut) { scroller.scrollTo(exercise, anchor: .top) }
                addedExercise = nil
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.sheetBackground.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture { isTyping = false }
        .navigationTitle("Customise sets")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $swapTarget) { target in
            ExerciseSwapSheet(replacing: target.id) { replacement in
                builder.replace(target.id, with: replacement.name)
            }
        }
        .sheet(isPresented: $isAddingExercise) {
            ExerciseSwapSheet(adding: true) { exercise in
                builder.add(exercise.name)
                addedExercise = exercise.name
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    builder.save(named: name, icon: symbol)
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .tint(.defaultSkyBlue)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            TextField("Session name", text: $name)
                .focused($isTyping)
                .font(.standard(size: .standout4, weight: .regular))
                .foregroundStyle(Color.textColor)

            BrightText(builder.count.counted("exercise"), size: .body1, color: .semiLightTextColor)
        }
    }

    private var iconPicker: some View {
        HStack(spacing: .spacing0x) {
            ForEach(ExerciseSessionIcon.allCases) { icon in
                Button {
                    symbol = icon
                } label: {
                    Image(systemName: icon.symbol)
                        .font(.standardSFPro(size: .heading, weight: .light))
                        .foregroundStyle(icon == symbol ? icon.accentColor : .semiLightTextColor)
                        .frame(width: Constants.iconTile, height: Constants.iconTile)
                        .background {
                            Circle()
                                .fill(Color.defaultMainGrey.opacity(icon == symbol ? .minimalOpacity : .finalBossLowOpacity))
                        }
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.brightSnappy, value: symbol)
    }

    private func exerciseCard(_ exercise: String) -> some View {
        VStack(spacing: .spacing3x) {
            cardHeader(exercise)
                .padding(.horizontal, .spacing3x)

            columnHeaders
                .padding(.horizontal, .spacing2x)
                .padding(.horizontal, .spacing3x)

            setsList(exercise)

            cardFooter(exercise)
                .padding(.horizontal, .spacing3x)
        }
        .padding(.vertical, .spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .sheetModalCards))
    }

    private func cardHeader(_ exercise: String) -> some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: "dumbbell.fill")
                .font(.standardSFPro(size: .body2, weight: .medium))
                .foregroundStyle(Color.textColor)

            BrightText(exercise, size: .body2, color: .semiLightTextColor, weight: .regular)

            Spacer(minLength: .spacing2x)

            Menu {
                Button("Move up", systemImage: "arrow.up") {
                    builder.moveUp(exercise)
                }
                Button("Swap out exercise", systemImage: "rectangle.2.swap") {
                    swapTarget = ExerciseSwapTarget(id: exercise)
                }
                Button("Remove exercise", systemImage: "trash", role: .destructive) {
                    builder.remove(exercise)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.standardSFPro(size: .standout4, weight: .light))
                    .foregroundStyle(Color.semiLightTextColor)
            }
        }
    }

    private func cardFooter(_ exercise: String) -> some View {
        HStack(spacing: .spacing2x) {
            circleButton("chart.line.uptrend.xyaxis") {}

            BrightText(volumeLabel(for: exercise), size: .body2, color: .textColor.opacity(.veryLowOpacity))

            Spacer(minLength: .spacing2x)

            ShareLink(item: builder.exportText(for: exercise)) {
                Image(systemName: "link")
                    .font(.standardSFPro(size: .body2, weight: .medium))
                    .foregroundStyle(Color.textColor)
                    .frame(width: Constants.footerButtonSize, height: Constants.footerButtonSize)
                    .modifier(GlassEffect(shape: .circle))
            }
            .buttonStyle(.plain)

            circleButton("plus") {
                withAnimation(.brightSnappy) { builder.addSet(to: exercise) }
            }
        }
    }

    private func circleButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.standardSFPro(size: .body2, weight: .medium))
                .foregroundStyle(Color.textColor)
                .frame(width: Constants.footerButtonSize, height: Constants.footerButtonSize)
                .modifier(GlassEffect(shape: .circle))
        }
        .buttonStyle(.plain)
    }

    private func volumeLabel(for exercise: String) -> String {
        let sets = builder.sets[exercise] ?? []
        let volume = sets.reduce(into: 0.0) { total, set in
            let weight = Double(set.weight.filter { $0.isNumber || $0 == "." }) ?? 0
            let reps = Double(set.reps.filter(\.isNumber)) ?? 0
            total += weight * reps
        }
        return "\(Int(volume)) kg /week"
    }

    private var columnHeaders: some View {
        HStack(spacing: .spacing0x) {
            Spacer(minLength: .spacing0x)

            ForEach(Constants.columnTitles, id: \.self) { title in
                BrightText(title, size: .body2, color: .semiLightTextColor, weight: .regular)
                    .multilineTextAlignment(.center)
                    .frame(width: Constants.fieldWidth)

                if title != Constants.columnTitles.last {
                    Spacer()
                        .frame(width: Constants.fieldGap)
                }
            }
        }
    }

    private func setsList(_ exercise: String) -> some View {
        let drafts = builder.sets[exercise] ?? []
        return List {
            ForEach(Array(drafts.enumerated()), id: \.element.id) { index, draft in
                ExerciseSetRow(
                    kind: draft.kind,
                    isTinted: index.isMultiple(of: 2),
                    weight: builder.binding(for: draft.id, in: exercise, keyPath: \.weight),
                    reps: builder.binding(for: draft.id, in: exercise, keyPath: \.reps),
                    rest: builder.binding(for: draft.id, in: exercise, keyPath: \.rest),
                    isTyping: $isTyping,
                    onCycleKind: {
                        withAnimation(.brightSnappy) { builder.cycleKind(of: draft.id, in: exercise) }
                    }
                )
                .listRowInsets(EdgeInsets(top: 0, leading: .spacing3x, bottom: 0, trailing: .spacing3x))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        withAnimation(.brightSnappy) { builder.removeSet(draft.id, from: exercise) }
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .listRowSpacing(.spacing0x)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .contentMargins(.vertical, .spacing0x, for: .scrollContent)
        .environment(\.defaultMinListRowHeight, ExerciseSetRow.Constants.rowHeight)
        .frame(height: ExerciseSetRow.Constants.rowHeight * CGFloat(drafts.count))
        .animation(.brightSnappy, value: drafts.count)
    }

    private enum Constants {
        static let columnTitles = ["Weights", "Reps", "Rest"]
        static let fieldWidth: CGFloat = 60
        static let fieldGap: CGFloat = 24
        static let iconTile: CGFloat = 44
        static let footerButtonSize: CGFloat = 36
    }
}

#Preview {
    NavigationStack {
        ExerciseCustomiseSetsView {}
            .environment(previewBuilder)
    }
}

@MainActor private let previewBuilder: ExerciseSessionBuilder = {
    let builder = ExerciseSessionBuilder()
    builder.add("Bench Press")
    builder.add("Shoulder Press")
    return builder
}()
