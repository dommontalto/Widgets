//
//  ExerciseLiveSessionSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 24/7/2026.
//

import SwiftUI

struct ExerciseLiveSessionSheet: View {
    var sessionName = "Gym session"
    var templateItems: [ExerciseTemplateItem]? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var startDate = Date()
    @State private var exercises: [ExerciseActiveExercise]
    @State private var restEndDate: Date?
    @State private var showAddExercise = false
    @State private var replacingExerciseId: UUID?
    @State private var completedSession: ExerciseSession?

    private let setColumnWidth: CGFloat = 32
    private let rpeColumnWidth: CGFloat = 32
    private let checkColumnWidth: CGFloat = 36
    private let statTileHeight: CGFloat = 67

    init(sessionName: String = "Gym session", templateItems: [ExerciseTemplateItem]? = nil) {
        self.sessionName = sessionName
        self.templateItems = templateItems
        _exercises = State(initialValue: templateItems.map(ExerciseActiveExercise.fromTemplate) ?? ExerciseDemoData.activeExercises)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing4x) {
                header

                statsRow

                VStack(spacing: .spacing3x) {
                    ForEach($exercises) { $exercise in
                        exerciseCard($exercise)
                    }
                }

                footerButtons
            }
            .padding(.horizontal, .spacing3x)
            .padding(.top, .spacing2x)
            .padding(.bottom, .spacing4x)
        }
        .safeAreaInset(edge: .bottom) {
            if restEndDate != nil {
                restTimerPill
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.defaultSheetBackground.ignoresSafeArea())
        .navigationTitle(sessionName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("End") {
                    completedSession = finishedSession
                }
                .buttonStyle(.borderedProminent)
                .tint(.defaultRed)
            }
        }
        .animation(.brightEaseInOut, value: completedSets)
        .animation(.brightBouncy, value: restEndDate)
        .navigationDestination(item: $completedSession) { session in
            ExerciseSessionCompleteSheet(session: session)
        }
        .sheet(isPresented: $showAddExercise) {
            BrightPageSheetView(title: "Exercises") {
                BrightPlaceholderView(
                    systemImage: "dumbbell",
                    title: "Exercise library",
                    subtitle: "This screen hasn\u{2019}t been ported yet."
                )
            }
        }

    }

    private var header: some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: "dumbbell")
                .resizable()
                .scaledToFit()
                .fontWeight(.light)
                .frame(width: 40, height: 40)
                .foregroundStyle(Color.defaultPurple)

            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(sessionName, size: .standout3)
                TimelineView(.periodic(from: startDate, by: 1)) { context in
                    BrightText(elapsedString(at: context.date), size: .body2, color: .defaultGreen, weight: .regular)
                        .monospacedDigit()
                }
            }

            Spacer(minLength: .spacing2x)
        }
    }

    private var finishedSession: ExerciseSession {
        let logged = exercises.compactMap { exercise -> ExerciseLoggedExercise? in
            let done = exercise.sets.filter(\.isDone)
            guard !done.isEmpty else { return nil }
            return ExerciseLoggedExercise(
                name: exercise.name,
                sets: done.map { ExerciseLoggedSet(weight: $0.weight, reps: $0.reps, isRecord: $0.isRecord) }
            )
        }
        let duration = elapsedString(at: Date())

        return ExerciseSession(
            name: sessionName,
            timestamp: Date().formatted(date: .abbreviated, time: .shortened),
            type: .strength,
            summary: "\(duration) • \(volumeString) kg • \(completedSets) sets",
            detail: ExerciseSessionDetail(
                stats: [
                    ExerciseSessionStat(label: "Duration", value: duration),
                    ExerciseSessionStat(label: "Volume", value: volumeString, unit: "kg"),
                    ExerciseSessionStat(label: "Total sets", value: "\(completedSets)"),
                    ExerciseSessionStat(label: "Records", value: "\(recordCount)", unit: recordCount == 1 ? "PR" : "PRs"),
                ],
                exercises: logged,
                splits: [],
                note: "Nice work — that's another session logged."
            )
        )
    }

    private var statsRow: some View {
        HStack(spacing: .spacing2x) {
            statTile(label: "Volume", value: volumeString, unit: "kg")
            statTile(label: "Sets", value: "\(completedSets)/\(totalSets)")
            statTile(label: "Records", value: "\(recordCount)")
        }
    }

    private func statTile(label: String, value: String, unit: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            HStack(alignment: .firstTextBaseline, spacing: .spacing05x) {
                BrightText(value, size: .standout3, weight: .regular)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let unit {
                    BrightText(unit, size: .body4, color: .lightTextColor)
                }
            }
            BrightText(label, size: .body4, color: .semiLightTextColor)
        }
        .padding(.horizontal, .spacing2x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: statTileHeight)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius18))
    }

    private func exerciseCard(_ exercise: Binding<ExerciseActiveExercise>) -> some View {
        VStack(alignment: .leading, spacing: .spacing105x) {
            HStack {
                BrightText(exercise.wrappedValue.name, size: .body2, color: .defaultPurple, weight: .regular)

                Spacer(minLength: .spacing2x)

                Menu {
                    Button {
                        replacingExerciseId = exercise.wrappedValue.id
                        showAddExercise = true
                    } label: {
                        Label("Replace exercise", systemImage: "arrow.triangle.2.circlepath")
                    }
                    Button {
                        moveUp(exercise.wrappedValue.id)
                    } label: {
                        Label("Move up", systemImage: "arrow.up")
                    }
                    Button(role: .destructive) {
                        withAnimation(.brightEaseInOut) {
                            exercises.removeAll { $0.id == exercise.wrappedValue.id }
                        }
                    } label: {
                        Label("Remove exercise", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.standardSFPro(size: .body2, weight: .regular))
                        .foregroundStyle(Color.lightTextColor)
                        .padding(.vertical, .spacing05x)
                        .padding(.horizontal, .spacing1x)
                        .contentShape(Rectangle())
                }
            }

            TextField("Add notes...", text: exercise.notes, axis: .vertical)
                .font(.standardSFPro(size: .body3, weight: .light))
                .foregroundStyle(Color.semiLightTextColor)

            HStack(spacing: .spacing0x) {
                BrightText("SET", size: .body5, color: .lightTextColor)
                    .frame(width: setColumnWidth, alignment: .leading)
                BrightText("PREVIOUS", size: .body5, color: .lightTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                BrightText("KG", size: .body5, color: .lightTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                BrightText("REPS", size: .body5, color: .lightTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                BrightText("RPE", size: .body5, color: .lightTextColor)
                    .frame(width: rpeColumnWidth, alignment: .leading)
                BrightText("", size: .body5)
                    .frame(width: checkColumnWidth)
            }

            VStack(spacing: .spacing1x) {
                ForEach(exercise.sets) { $set in
                    ExerciseLoggerSetRow(
                        index: workingIndex(of: $set.wrappedValue, in: exercise.wrappedValue),
                        set: $set,
                        setColumnWidth: setColumnWidth,
                        rpeColumnWidth: rpeColumnWidth,
                        checkColumnWidth: checkColumnWidth
                    ) {
                        if $set.wrappedValue.isDone {
                            restEndDate = Date().addingTimeInterval(Constants.restSeconds)
                        }
                    } onDelete: {
                        withAnimation(.brightEaseInOut) {
                            exercise.wrappedValue.sets.removeAll { $0.id == $set.wrappedValue.id }
                        }
                    }
                }
            }

            Button {
                let last = exercise.wrappedValue.sets.last
                withAnimation(.brightEaseInOut) {
                    exercise.wrappedValue.sets.append(
                        ExerciseActiveSet(weight: last?.weight ?? "20", reps: last?.reps ?? "10", previous: last?.previous ?? "\u{2014}")
                    )
                }
            } label: {
                HStack(spacing: .spacing1x) {
                    Image(systemName: "plus")
                        .font(.standardSFPro(size: .body4, weight: .regular))
                    BrightText("Add set", size: .body3, weight: .regular)
                }
                .foregroundStyle(Color.semiLightTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spacing1x)
            }
            .buttonStyle(.plain)
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards))
    }

    private var restTimerPill: some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: "timer")
                .font(.standardSFPro(size: .body1, weight: .regular))
                .foregroundStyle(Color.defaultGreen)

            TimelineView(.periodic(from: Date(), by: 1)) { context in
                BrightText(restRemainingString(at: context.date), size: .subheading2, weight: .regular)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            BrightText("Rest", size: .body3, color: .lightTextColor)

            Spacer(minLength: .spacing2x)

            Button {
                restEndDate = nil
            } label: {
                BrightText("Skip", size: .body3, color: .defaultGreen, weight: .regular)
                    .padding(.horizontal, .spacing2x)
                    .padding(.vertical, .spacing1x)
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.defaultGreen.opacity(.minimalOpacity), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, .spacing3x)
        .padding(.vertical, .spacing2x)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius18))
        .padding(.horizontal, .spacing3x)
        .padding(.bottom, .spacing1x)
    }

    private var footerButtons: some View {
        VStack(spacing: .spacing2x) {
            BrightPillButton("Add exercise", systemImage: "plus", buttonSize: .large) {
                replacingExerciseId = nil
                showAddExercise = true
            }
            .frame(maxWidth: .infinity)

            Button {
                dismiss()
            } label: {
                BrightText("Cancel workout", size: .body2, color: .defaultRed, weight: .regular)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .spacing2x)
            }
            .buttonStyle(.plain)
        }
    }

    private func moveUp(_ id: UUID) {
        guard let index = exercises.firstIndex(where: { $0.id == id }), index > 0 else { return }
        withAnimation(.brightEaseInOut) {
            exercises.swapAt(index, index - 1)
        }
    }

    private func workingIndex(of set: ExerciseActiveSet, in exercise: ExerciseActiveExercise) -> Int {
        let working = exercise.sets.filter { !$0.isWarmup }
        return (working.firstIndex { $0.id == set.id } ?? 0) + 1
    }

    private var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    private var completedSets: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.isDone).count }
    }

    private var recordCount: Int {
        exercises.reduce(0) { $0 + $1.sets.filter { $0.isDone && $0.isRecord }.count }
    }

    private var volumeString: String {
        let volume = exercises
            .flatMap(\.sets)
            .filter(\.isDone)
            .reduce(0) { $0 + (Int($1.weight) ?? 0) * (Int($1.reps) ?? 0) }
        return volume.formatted(.number.grouping(.automatic))
    }

    private func elapsedString(at date: Date) -> String {
        let elapsed = max(0, Int(date.timeIntervalSince(startDate)))
        return String(format: "%d:%02d", elapsed / 60, elapsed % 60)
    }

    private func restRemainingString(at date: Date) -> String {
        guard let restEndDate else { return "0:00" }
        let remaining = Int(restEndDate.timeIntervalSince(date).rounded(.down))
        if remaining <= 0 {
            Task { @MainActor in self.restEndDate = nil }
            return "0:00"
        }
        return String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    private class Constants {
        static let restSeconds: TimeInterval = 90
    }
}

private struct ExerciseLoggerSetRow: View {
    let index: Int
    @Binding var set: ExerciseActiveSet
    let setColumnWidth: CGFloat
    let rpeColumnWidth: CGFloat
    let checkColumnWidth: CGFloat
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: .spacing0x) {
            setLabel
                .frame(width: setColumnWidth, alignment: .leading)

            BrightText(set.previous, size: .body3, color: .lightTextColor)
                .monospacedDigit()
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            valueField($set.weight, placeholder: "kg")
            valueField($set.reps, placeholder: "reps")

            valueField($set.rpe, placeholder: "\u{2014}")
                .frame(width: rpeColumnWidth, alignment: .leading)

            Button {
                set.isDone.toggle()
                onToggle()
            } label: {
                BrightTick(isTicked: set.isDone)
            }
            .buttonStyle(.plain)
            .frame(width: checkColumnWidth)
        }
        .padding(.vertical, .spacing05x)
        .padding(.horizontal, .spacing105x)
        .background(
            Color.defaultGreen.opacity(set.isDone ? .ultraLowOpacity : 0),
            in: RoundedRectangle(cornerRadius: .cornerRadius10, style: .continuous)
        )
        .padding(.horizontal, -.spacing105x)
        .offset(x: dragOffset)
        .background(alignment: .trailing) {
            if dragOffset < 0 {
                Image(systemName: "trash")
                    .font(.standardSFPro(size: .body2, weight: .regular))
                    .foregroundStyle(Color.defaultRed)
                    .padding(.trailing, .spacing1x)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    dragOffset = min(0, value.translation.width)
                }
                .onEnded { value in
                    if value.translation.width < Constants.deleteThreshold {
                        onDelete()
                    } else {
                        withAnimation(.brightBouncy) { dragOffset = 0 }
                    }
                }
        )
    }

    @ViewBuilder private var setLabel: some View {
        if set.isWarmup {
            BrightText("W", size: .body2, color: .defaultSkyBlue, weight: .regular)
        } else if set.isDone, set.isRecord {
            Image(systemName: "trophy")
                .font(.standardSFPro(size: .body4, weight: .regular))
                .foregroundStyle(Color.defaultOrange)
        } else {
            BrightText("\(index)", size: .body2, color: .semiLightTextColor)
                .monospacedDigit()
        }
    }

    private func valueField(_ text: Binding<String>, placeholder: String) -> some View {
        TextField(placeholder, text: text)
            .font(.standardSFPro(size: .body2, weight: .regular))
            .foregroundStyle(Color.textColor)
            .keyboardType(.decimalPad)
            .monospacedDigit()
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private enum Constants {
        static let deleteThreshold: CGFloat = -90
    }
}

struct ExerciseTemplateItem: Identifiable, Sendable {
    let id = UUID()
    let exerciseName: String
    let target: String
}

struct ExerciseActiveSet: Identifiable, Sendable {
    let id = UUID()
    var weight: String
    var reps: String
    var rpe = ""
    var previous = "\u{2014}"
    var isWarmup = false
    var isRecord = false
    var isDone = false
}

struct ExerciseActiveExercise: Identifiable, Sendable {
    let id = UUID()
    var name: String
    var notes = ""
    var sets: [ExerciseActiveSet]

    nonisolated static func fresh(named name: String) -> ExerciseActiveExercise {
        ExerciseActiveExercise(name: name, sets: [
            ExerciseActiveSet(weight: "", reps: "", isWarmup: true),
            ExerciseActiveSet(weight: "", reps: ""),
            ExerciseActiveSet(weight: "", reps: ""),
            ExerciseActiveSet(weight: "", reps: ""),
        ])
    }

    nonisolated static func fromTemplate(_ items: [ExerciseTemplateItem]) -> [ExerciseActiveExercise] {
        items.map { item in
            ExerciseActiveExercise(name: item.exerciseName, notes: item.target, sets: [
                ExerciseActiveSet(weight: "", reps: "", isWarmup: true),
                ExerciseActiveSet(weight: "", reps: ""),
                ExerciseActiveSet(weight: "", reps: ""),
                ExerciseActiveSet(weight: "", reps: ""),
            ])
        }
    }

}

#Preview {
    ExerciseLiveSessionSheet()
}
