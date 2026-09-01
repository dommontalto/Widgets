//
//  ExercisePreCardioSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 20/8/2026.
//

import SwiftUI

// What a run is about to do, read back off the plan it was built with. The
// strength equivalent lists exercises and sets; a run has targets and legs.
struct ExercisePreCardioSheet: View {
    let session: ExerciseQuickSession

    // Which of the session's legs this sets up — always a cardio one here.
    var leg = 0

    var chrome: ExercisePageChrome = .sheet

    // Ends the whole run. Only the flow can do that from a pushed leg, where
    // `dismiss` would pop back instead.
    var onClose: (() -> Void)?

    // Hands the run to the presenter, which pushes the live screen inside the
    // same presentation.
    var onStart: (ExerciseQuickSession) -> Void = { _ in }

    @Environment(ExerciseBuilder.self) private var builder
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false

    private var item: ExerciseTemplateItem? {
        guard case let .cardio(index)? = session.legs[safe: leg] else {
            return session.cardioItems.first
        }
        return session.items[safe: index]
    }

    private var plan: ExerciseCardioPlan {
        (item?.plan ?? ExerciseCardioPlan()).effective
    }

    // The session's own name when the run is all it is, and the run's name when
    // it's one leg among others.
    private var title: String {
        guard session.hasStrength || session.cardioItems.count > 1 else { return session.name }
        return item?.exerciseName ?? session.name
    }

    private var symbol: String {
        item.map { ExerciseDemoLibrary.glyph(for: $0.exerciseName).symbol } ?? session.symbol
    }

    var body: some View {
        page
            .navigationDestination(isPresented: $isEditing) {
                ExerciseCreateSessionSheet(editing: session) { isEditing = false }
            }
    }

    @ViewBuilder private var page: some View {
        switch chrome {
        case .sheet:
            BrightPageSheetView(
                horizontalPadding: .spacing0x,
                backgroundColor: .defaultBackground,
                trailing: { ToolbarItem(placement: .topBarTrailing) { sourceMenu } },
                content: {
                    content
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                ExerciseInlineTitle(file: #file)
                            }
                        }
                }
            )

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

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing3x) {
                header

                ForEach(targets) { target in
                    targetCard(target)
                }

                if plan.isIntervalsOn, plan.hasIntervals {
                    intervalsCard
                }
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
        VStack(alignment: .leading, spacing: .spacing2x) {
            Image(systemName: symbol)
                .font(.standard(size: .huge2, weight: .light))
                .foregroundStyle(Color.textColor)

            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(title, size: .standout3, scaleTextSize: 0.7)
                    .lineLimit(1)

                BrightText(startLabel, size: .body1, color: .semiLightTextColor)
            }
        }
    }

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

    // MARK: - Targets

    private func targetCard(_ target: Target) -> some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: target.symbol)
                .font(.standard(size: .standout3, weight: .regular))
                .foregroundStyle(target.tint)
                .frame(width: Constants.iconWidth)

            BrightText(target.title, size: .body1, weight: .regular)

            Spacer(minLength: .spacing2x)

            BrightText(target.value, size: .huge2)
                .monospacedDigit()
                .lineLimit(1)
        }
        .padding(.horizontal, .spacing3x)
        .frame(height: Constants.targetHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    // MARK: - Intervals

    private var intervalsCard: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            HStack(spacing: .spacing2x) {
                Image(systemName: "increase.quotelevel")
                    .font(.standard(size: .standout3, weight: .regular))
                    .foregroundStyle(Color.defaultPurple)
                    .frame(width: Constants.iconWidth)

                BrightText("Intervals", size: .body1, weight: .regular)
            }

            VStack(spacing: .spacing0x) {
                ForEach(Array(plan.intervals.enumerated()), id: \.element.id) { index, interval in
                    intervalRow(interval, isTinted: index.isMultiple(of: 2))
                }
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    private func intervalRow(_ interval: ExerciseCardioInterval, isTinted: Bool) -> some View {
        HStack(spacing: .spacing2x) {
            Image(systemName: interval.phase.symbol)
                .font(.standard(size: .body1, weight: .light))
                .foregroundStyle(Color.textColor)
                .frame(width: Constants.intervalIconWidth)

            BrightText(interval.phase.title, size: .body1, weight: .regular)

            Spacer(minLength: .spacing2x)

            BrightText(legLabel(interval.value), size: .body1, weight: .regular)
                .monospacedDigit()
        }
        .padding(.horizontal, .spacing2x)
        .frame(height: Constants.intervalRowHeight)
        .background {
            if isTinted {
                RoundedRectangle(cornerRadius: .cornerRadius18, style: .continuous)
                    .fill(Color.defaultBackground)
            }
        }
    }

    // Legs are held in metres; a round kilometre reads better as one.
    private func legLabel(_ value: String) -> String {
        guard let metres = Int(value.filter(\.isNumber)) else { return value }
        guard metres >= 1_000, metres.isMultiple(of: 1_000) else { return "\(metres) M" }
        return "\(metres / 1_000) KM"
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

    private var startLabel: String {
        "Today: \(Date().formatted(.brightTime))"
    }

    // One card per thing the plan is chasing: what stops the run, then how hard
    // it's meant to be run.
    private var targets: [Target] {
        var targets: [Target] = []

        switch plan.goal {
        case .distance:
            targets.append(target(plan.goal, "Target Distance", value: plan.distance, unit: "KM"))
        case .duration:
            targets.append(target(plan.goal, "Target Duration", value: plan.duration, unit: "MIN"))
        case .calorie:
            targets.append(target(plan.goal, "Target Calories", value: plan.calories, unit: "CAL"))
        case .zone:
            targets.append(target(plan.goal, "Target Zone", value: "Z\(plan.zone.rawValue)"))
        case .freerun:
            targets.append(target(plan.goal, "Freerun", value: "No target"))
        }

        guard plan.goal.hasSecondarySection else { return targets }

        switch plan.secondary {
        case .pace:
            targets.append(target(plan.secondary, "Target Pace", value: plan.pace))
        case .distance:
            targets.append(target(plan.secondary, "Target Distance", value: plan.distance, unit: "KM"))
        case .duration:
            targets.append(target(plan.secondary, "Target Duration", value: plan.duration, unit: "MIN"))
        case .zone:
            targets.append(target(plan.secondary, "Target Zone", value: "Z\(plan.zone.rawValue)"))
        }

        return targets.filter { !$0.value.isEmpty }
    }

    private func target(
        _ goal: ExerciseCardioGoal,
        _ title: String,
        value: String,
        unit: String? = nil
    ) -> Target {
        Target(symbol: goal.symbol, tint: goal.tint, title: title, value: valueLabel(value, unit))
    }

    private func target(
        _ secondary: ExerciseCardioSecondary,
        _ title: String,
        value: String,
        unit: String? = nil
    ) -> Target {
        Target(
            symbol: secondary.symbol,
            tint: secondary.tint,
            title: title,
            value: valueLabel(value, unit)
        )
    }

    private func valueLabel(_ value: String, _ unit: String?) -> String {
        guard !value.isEmpty, let unit else { return value }
        return "\(value) \(unit)"
    }

    private struct Target: Identifiable {
        let id = UUID()
        let symbol: String
        let tint: Color
        let title: String
        let value: String
    }

    private enum Constants {
        static let iconWidth: CGFloat = 28
        static let intervalIconWidth: CGFloat = 24
        static let targetHeight: CGFloat = 78
        static let intervalRowHeight: CGFloat = 49
    }
}

#Preview {
    Color.defaultBackground
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ExercisePreCardioSheet(session: ExerciseDemoSessions.all.first { $0.isCardio }!)
                .environment(ExerciseBuilder())
        }
}
