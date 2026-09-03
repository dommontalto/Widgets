//
//  ExerciseCardioPlanEditor.swift
//  Widgets
//
//  Created by Dom Montalto on 18/8/2026.
//

import CoreLocation
import SwiftUI

// The cardio half of ExerciseCreateSessionSheet: what the run is chasing, and
// whatever the goal leaves worth adding to it.
struct ExerciseCardioPlanEditor: View {
    @Binding var plan: ExerciseCardioPlan

    @State private var isShowingRouteMap = false
    @State private var isPickingPace = false
    @State private var isShowingRegeneratePrompt = false
    @State private var autoGeneratesOnOpen = false

    @Environment(\.colorScheme) private var colorScheme

    var isTyping: FocusState<Bool>.Binding

    // Mirrors the interval row's own scaling so the list's height matches the rows
    // it holds.
    @ScaledMetric(relativeTo: .body) private var intervalRowHeight = ExerciseIntervalRow.Constants.rowHeight

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            section("Primary goal") {
                if plan.goal == .zone {
                    zoneCard(badge: goalBadge, title: plan.goal.title)
                } else {
                    primaryRow
                }
            }

            // Each goal carries its own follow-ups: a distance or timed run can be
            // paced and split into intervals, while a zone or calorie run only
            // needs the distance or pace it's run at.
            if plan.goal.hasSecondarySection {
                section("Optional") {
                    if plan.secondary == .zone {
                        zoneCard(badge: secondaryBadge, title: plan.secondary.title)
                    } else {
                        secondaryRow
                    }

                    if plan.hasIntervals {
                        intervalsCard
                    }

                    routeRow
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .fullScreenCover(isPresented: $isShowingRouteMap) {
            ExerciseRouteGeneratorSheet(
                onClose: { route in
                    plan.route = route
                    if let route {
                        syncValues(from: route)
                    }
                    autoGeneratesOnOpen = false
                    isShowingRouteMap = false
                },
                initialRoute: plan.route,
                targetDistanceKm: Double(plan.distance),
                autoGeneratesOnOpen: autoGeneratesOnOpen
            )
        }
        .brightMiniSheet(isPresented: $isPickingPace) {
            ExercisePacePicker(pace: $plan.pace) { isPickingPace = false }
        }
        .animation(.brightSnappy, value: plan.goal)
        .animation(.brightSnappy, value: plan.secondary)
        .onChange(of: plan.goal) { _, _ in
            if !plan.secondaryOptions.contains(plan.secondary) {
                plan.secondary = plan.secondaryOptions[0]
            }
        }
        .onChange(of: isTyping.wrappedValue) { _, focused in
            guard !focused, isRouteStale else { return }
            isShowingRegeneratePrompt = true
        }
        .alert("Generate New Route?", isPresented: $isShowingRegeneratePrompt) {
            Button("Generate") {
                autoGeneratesOnOpen = true
                isShowingRouteMap = true
            }

            Button("Cancel", role: .cancel) {
                revertDistance()
            }
        } message: {
            Text("Your saved route no longer matches the distance.")
        }
    }

    private func section(
        _ title: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            BrightText(title, size: .body1)
                .padding(.leading, .spacing2x)

            content()
        }
    }

    // MARK: - Goals

    // The badge picks what the run is chasing, so the row it heads swaps with it.
    // Freerun has nothing to chase, so the row carries the badge and title alone.
    private var primaryRow: some View {
        row(badge: goalBadge, title: plan.goal.title) {
            switch plan.goal {
            case .duration:
                valueField(text: $plan.duration, placeholder: "0", unit: plan.goal.unit, keyboard: .numberPad)
            case .calorie:
                valueField(text: $plan.calories, placeholder: "0", unit: plan.goal.unit, keyboard: .numberPad)
            case .freerun:
                EmptyView()
            default:
                valueField(text: $plan.distance, placeholder: "0", unit: plan.goal.unit, keyboard: .decimalPad)
            }
        }
    }

    private var goalBadge: some View {
        Menu {
            Picker("Primary goal", selection: $plan.goal) {
                ForEach(ExerciseCardioGoal.allCases) { option in
                    Label(option.title, systemImage: option.symbol).tag(option)
                }
            }
        } label: {
            // The Menu owns the tap, so the badge is label only.
            badge(symbol: plan.goal.symbol, tint: plan.goal.tint)
                .allowsHitTesting(false)
        }
        .brightHaptic(.light, trigger: plan.goal)
    }

    // The optional row picks its own target the same way the primary one does,
    // from whatever the primary goal leaves worth adding.
    private var secondaryRow: some View {
        row(badge: secondaryBadge, title: secondaryTitle) {
            switch plan.secondary {
            case .pace:
                paceField
            case .distance:
                valueField(text: $plan.distance, placeholder: "0", unit: plan.secondary.unit, keyboard: .decimalPad)
            case .duration:
                valueField(text: $plan.duration, placeholder: "0", unit: plan.secondary.unit, keyboard: .numberPad)
            case .zone:
                EmptyView()
            }
        }
    }

    // With nothing to choose between, the badge loses its circle so it doesn't
    // read as a menu that does nothing.
    @ViewBuilder
    private var secondaryBadge: some View {
        if plan.secondaryOptions.count > 1 {
            Menu {
                Picker("Target", selection: $plan.secondary) {
                    ForEach(plan.secondaryOptions) { option in
                        Label(option.title, systemImage: option.symbol).tag(option)
                    }
                }
            } label: {
                // The Menu owns the tap, so the badge is label only.
                badge(symbol: plan.secondary.symbol, tint: plan.secondary.tint)
                    .allowsHitTesting(false)
            }
            .brightHaptic(.light, trigger: plan.secondary)
        } else {
            badge(symbol: plan.secondary.symbol, tint: plan.secondary.tint, isCircled: false)
        }
    }

    private var secondaryTitle: String {
        plan.secondary == .pace && plan.secondaryOptions.count == 1 ? "Target Pace" : plan.secondary.title
    }

    private var paceField: some View {
        Button {
            isPickingPace = true
        } label: {
            BrightText(plan.pace.isEmpty ? "0’00”" : plan.pace, size: .standout2, weight: .light)
                .contentTransition(.numericText())
                .opacity(plan.pace.isEmpty ? .semiLowOpacity : .opaque)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .brightHaptic(.light, trigger: isPickingPace)
    }

    // MARK: - Zone

    private func zoneCard(badge: some View, title: String) -> some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            rowContent(badge: badge, title: title) {
                EmptyView()
            }
            .padding(.bottom, .spacing2x)

            ForEach(ExerciseHeartZone.allCases) { option in
                if option != .one {
                    BrightDivider()
                }

                zoneRow(option)
            }
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
        // BrightTick plays its own haptic, so the card doesn't add one.
        .animation(.brightSnappy, value: plan.zone)
    }

    private func zoneRow(_ option: ExerciseHeartZone) -> some View {
        Button {
            plan.zone = option
        } label: {
            HStack(spacing: .spacing2x) {
                BrightStatus(status: option.title)

                BrightText(option.range, size: .body1, color: .lightTextColor, weight: .regular)

                Spacer(minLength: .spacing2x)

                BrightTick(isTicked: option == plan.zone)
            }
            .frame(height: Constants.zoneRowHeight)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Intervals

    private var intervalsCard: some View {
        VStack(spacing: .spacing3x) {
            rowContent(
                badge: badge(symbol: "increase.quotelevel", tint: .defaultPurplePink, isCircled: false),
                title: "Intervals"
            ) {
                Toggle("", isOn: $plan.isIntervalsOn)
                    .labelsHidden()
                    .tint(Color.defaultGreen)
                    .brightHaptic(.light, trigger: plan.isIntervalsOn)
            }
            .padding(.horizontal, .spacing3x)

            if plan.isIntervalsOn {
                intervalsEditor
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.vertical, .spacing3x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
        .animation(.brightSnappy, value: plan.isIntervalsOn)
    }

    // The rows run edge to edge inside the card, the way set rows do in a strength
    // card, with the plus in the corner adding another leg.
    private var intervalsEditor: some View {
        VStack(spacing: .spacing3x) {
            intervalsList

            addIntervalButton
                .padding(.horizontal, .spacing3x)
        }
    }

    // A List so each leg swipes away, the same way a set does in a strength card.
    private var intervalsList: some View {
        List {
            ForEach(Array(plan.intervals.enumerated()), id: \.element.id) { index, interval in
                intervalRow(at: index)
                    .listRowInsets(EdgeInsets(top: 0, leading: .spacing3x, bottom: 0, trailing: .spacing3x))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            remove(interval)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(.defaultRed)
                    }
            }
        }
        .listStyle(.plain)
        .listRowSpacing(.spacing0x)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .contentMargins(.vertical, .spacing0x, for: .scrollContent)
        .environment(\.defaultMinListRowHeight, intervalRowHeight)
        .frame(height: intervalRowHeight * CGFloat(plan.intervals.count))
        .animation(.brightSnappy, value: plan.intervals.count)
    }

    private func intervalRow(at index: Int) -> some View {
        ExerciseIntervalRow(
            phase: plan.intervals[index].phase,
            isTinted: index.isMultiple(of: 2),
            value: $plan.intervals[index].value,
            isTyping: isTyping,
            onPickPhase: { phase in
                withAnimation(.brightSnappy) { plan.intervals[index].phase = phase }
            }
        )
    }

    private func remove(_ interval: ExerciseCardioInterval) {
        withAnimation(.brightSnappy) { plan.intervals.removeAll { $0.id == interval.id } }
    }

    private var addIntervalButton: some View {
        BrightRoundButton(systemImage: "plus") {
            withAnimation(.brightSnappy) {
                plan.intervals.append(ExerciseCardioInterval(phase: .run, value: "1000"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Rows

    private func row(
        badge: some View,
        title: String,
        @ViewBuilder trailing: () -> some View
    ) -> some View {
        rowContent(badge: badge, title: title, trailing: trailing)
            .padding(.horizontal, .spacing3x)
            .frame(height: Constants.rowHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(CardModifier(color: .defaultSheetModalCards, cornerRadius: .cornerRadius24))
    }

    private func rowContent(
        badge: some View,
        title: String,
        @ViewBuilder trailing: () -> some View
    ) -> some View {
        HStack(spacing: .spacing2x) {
            badge

            BrightText(title, size: .body1, color: .semiLightTextColor, weight: .regular)

            Spacer(minLength: .spacing2x)

            trailing()
        }
    }

    @ViewBuilder
    private func badge(symbol: String, tint: Color, isCircled: Bool = true) -> some View {
        let glyph = Image(systemName: symbol)
            .font(.standard(size: .subheading2, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: Constants.badgeSize, height: Constants.badgeSize)

        if isCircled {
            glyph.modifier(GlassEffect(shape: .circle))
        } else {
            glyph
        }
    }

    private func valueField(
        text: Binding<String>,
        placeholder: String,
        unit: String?,
        keyboard: UIKeyboardType
    ) -> some View {
        HStack(spacing: .spacing1x) {
            TextField(placeholder, text: text)
                .focused(isTyping)
                .font(.standard(size: .standout2, weight: .light))
                .foregroundStyle(Color.textColor)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)

            if let unit {
                BrightText(unit, size: .standout2, weight: .light)
            }
        }
        .opacity(text.wrappedValue.isEmpty ? .semiLowOpacity : .opaque)
    }

    // MARK: - Route

    private var routeRow: some View {
        row(badge: routeThumbnail, title: "Generate Route") {
            Toggle("", isOn: routeToggle)
                .labelsHidden()
                .tint(Color.defaultGreen)
                .brightHaptic(.light, trigger: plan.isRouteOn)
        }
        // The toggle takes its own taps; everywhere else opens the map.
        .contentShape(.rect)
        .onTapGesture { openRouteMap() }
    }

    private var isRouteStale: Bool {
        guard let route = plan.route,
              let target = Double(plan.distance), target > 0 else { return false }
        return abs(1 - route.distanceMetres / (target * 1000)) > Constants.staleTolerance
    }

    private func syncValues(from route: ExercisePlannedRoute) {
        let kilometres = (route.distanceMetres / 100).rounded() / 10
        plan.distance = kilometres == kilometres.rounded()
            ? "\(Int(kilometres))"
            : String(format: "%.1f", kilometres)
        if plan.goal == .duration {
            plan.duration = "\(Int((route.durationSeconds / 60).rounded()))"
        }
    }

    private func revertDistance() {
        guard let route = plan.route else { return }
        syncValues(from: route)
    }

    // Switching on opens the map; switching off drops the saved route.
    private var routeToggle: Binding<Bool> {
        Binding(
            get: { plan.isRouteOn },
            set: { isOn in
                if isOn {
                    openRouteMap()
                } else {
                    plan.route = nil
                }
            }
        )
    }

    // Nothing drawn yet and a distance to aim at is all the generator needs, so
    // the map opens already building rather than waiting for a tap.
    private func openRouteMap() {
        autoGeneratesOnOpen = plan.route == nil && (Double(plan.distance) ?? 0) > 0
        isShowingRouteMap = true
    }

    private var routeThumbnail: some View {
        AsyncImage(url: routeThumbnailURL) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Color.defaultCapsule
                .overlay {
                    Image(systemName: "map.fill")
                        .font(.standard(size: .body5, weight: .medium))
                        .foregroundStyle(Color.textColor)
                }
        }
        .frame(width: Constants.badgeSize, height: Constants.badgeSize)
        .clipShape(.rect(cornerRadius: .cornerRadius9))
        .id("\(plan.route?.coordinates.count ?? 0)-\(colorScheme)")
    }

    // A static Mapbox shot centred on the saved route — or, before one exists,
    // the map the generator opens on — so the row hints at what's behind it
    // without running a live map.
    private var routeThumbnailURL: URL? {
        guard let token = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String else { return nil }

        guard let route = plan.route, route.coordinates.count >= 2 else {
            return URL(
                string: "https://api.mapbox.com/styles/v1/mapbox/\(thumbnailStyle)/static/"
                    + "151.2006,-33.8769,12,0/60x60@2x?access_token=\(token)&logo=false&attribution=false"
            )
        }

        let path = Self.encodedPolyline(Self.downsampled(route.coordinates))
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else { return nil }
        return URL(
            string: "https://api.mapbox.com/styles/v1/mapbox/\(thumbnailStyle)/static/"
                + "path-3+ff4cc9(\(encodedPath))/auto/60x60@2x"
                + "?padding=6&access_token=\(token)&logo=false&attribution=false"
        )
    }

    private var thumbnailStyle: String {
        colorScheme == .dark ? "dark-v11" : "streets-v12"
    }

    private static func downsampled(_ coordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        guard coordinates.count > Constants.thumbnailMaxPoints else { return coordinates }
        let step = Double(coordinates.count - 1) / Double(Constants.thumbnailMaxPoints - 1)
        return (0 ..< Constants.thumbnailMaxPoints).map { coordinates[Int((Double($0) * step).rounded())] }
    }

    private static func encodedPolyline(_ coordinates: [CLLocationCoordinate2D]) -> String {
        var encoded = ""
        var lastLatitude = 0
        var lastLongitude = 0

        for coordinate in coordinates {
            let latitude = Int((coordinate.latitude * 1e5).rounded())
            let longitude = Int((coordinate.longitude * 1e5).rounded())
            encoded += encodedValue(latitude - lastLatitude)
            encoded += encodedValue(longitude - lastLongitude)
            lastLatitude = latitude
            lastLongitude = longitude
        }
        return encoded
    }

    private static func encodedValue(_ value: Int) -> String {
        var shifted = value < 0 ? ~(value << 1) : value << 1
        var chunk = ""
        while shifted >= 0x20 {
            chunk.append(Character(UnicodeScalar(((shifted & 0x1F) | 0x20) + 63)!))
            shifted >>= 5
        }
        chunk.append(Character(UnicodeScalar(shifted + 63)!))
        return chunk
    }

    private enum Constants {
        static let rowHeight: CGFloat = 62
        static let badgeSize: CGFloat = 30
        static let zoneRowHeight: CGFloat = 48
        static let thumbnailMaxPoints = 40
        static let staleTolerance: Double = 0.15
    }
}

// Deliberately its own row rather than a shared one: the live cardio screen shows
// intervals its own way, so the two can drift without fighting each other.
struct ExerciseIntervalRow: View {
    let phase: ExerciseIntervalPhase
    let isTinted: Bool
    @Binding var value: String
    var isTyping: FocusState<Bool>.Binding
    let onPickPhase: (ExerciseIntervalPhase) -> Void

    @Environment(\.colorScheme) private var colorScheme

    @ScaledMetric(relativeTo: .body) private var rowHeight = Constants.rowHeight
    @ScaledMetric(relativeTo: .body) private var badgeSize = Constants.badgeSize
    @ScaledMetric(relativeTo: .body) private var pillWidth = Constants.pillWidth

    private var phaseSelection: Binding<ExerciseIntervalPhase> {
        Binding(get: { phase }, set: { onPickPhase($0) })
    }

    var body: some View {
        HStack(spacing: .spacing2x) {
            Menu {
                Picker("Phase", selection: phaseSelection) {
                    ForEach(ExerciseIntervalPhase.allCases) { option in
                        Label(option.title, systemImage: option.symbol).tag(option)
                    }
                }
            } label: {
                // The Menu owns the tap, so the badge is label only.
                badge
                    .allowsHitTesting(false)
            }

            BrightText(phase.title, size: .body1, color: .semiLightTextColor, weight: .regular)

            Spacer(minLength: .spacing2x)

            field
        }
        .padding(.horizontal, .spacing2x)
        .frame(height: rowHeight)
        .background {
            if isTinted {
                RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous)
                    .fill(tint)
            }
        }
    }

    private var tint: Color {
        colorScheme == .dark
            ? .defaultSheetBackground.opacity(.veryLowOpacity)
            : .defaultMainGrey.opacity(.ultraLowOpacity)
    }

    private var badge: some View {
        Image(systemName: phase.symbol)
            .font(.standard(size: .body1, weight: .light))
            .foregroundStyle(Color.textColor)
            .frame(width: badgeSize, height: badgeSize)
            .modifier(GlassEffect(shape: .circle))
    }

    // The unit sits in the same capsule as the number, so the pair reads as one
    // value the way "500 M" does. The capsule is a fixed width so every row's
    // pill is the same size whatever it holds.
    private var field: some View {
        HStack(spacing: .spacing1x) {
            TextField("0", text: $value)
                .focused(isTyping)
                .font(.standard(size: .body1, weight: .regular))
                .foregroundStyle(Color.textColor)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity)

            BrightText(Constants.unit, size: .body1, weight: .regular)
        }
        .padding(.horizontal, .spacing2x)
        .frame(width: pillWidth, height: badgeSize)
        .background(Color.defaultCapsule, in: Capsule())
    }

    enum Constants {
        static let unit = "M"
        static let rowHeight: CGFloat = 49
        static let badgeSize: CGFloat = 30
        static let pillWidth: CGFloat = 84
    }
}

private struct ExerciseCardioPlanEditorPreview: View {
    @State private var plan = ExerciseCardioPlan()

    @FocusState private var isTyping: Bool

    var body: some View {
        ScrollView {
            ExerciseCardioPlanEditor(plan: $plan, isTyping: $isTyping)
                .padding(.spacing3x)
        }
        .background(Color.defaultSheetBackground.ignoresSafeArea())
    }
}

#Preview {
    ExerciseCardioPlanEditorPreview()
}
