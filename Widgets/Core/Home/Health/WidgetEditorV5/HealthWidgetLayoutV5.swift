//
//  HealthWidgetLayoutV5.swift
//  Widgets
//
//  Created by Dom Montalto on 7/10/2026.
//

import SwiftUI

// In alphabetical order of their row names, and every switch over them follows it.
enum HealthWidgetKindV5: String, CaseIterable, Codable, Hashable, Identifiable {
    case activity
    case exercise
    case heartRate
    case intake
    case journal
    case macros
    case menstrual
    case micros
    case mind
    case nutrition
    case sleep
    case water
    case weight
    case wellbeing

    var id: Self { self }

    var title: String {
        switch self {
        case .activity: "Total Energy"
        case .exercise: "Exercise"
        case .heartRate: "Heart Rate"
        case .intake: "Intake"
        case .journal: "Journal"
        case .macros: "Weekly Macros"
        case .menstrual: "Menstrual"
        case .micros: "Micros"
        case .mind: "Mind"
        case .nutrition: "Nutrition"
        case .sleep: "Sleep"
        case .water: "Water"
        case .weight: "Weight"
        case .wellbeing: "Wellbeing"
        }
    }

    // The shorter name it's listed under in the add sheet.
    var rowTitle: String {
        switch self {
        case .activity: "Activity"
        case .exercise: "Exercise"
        case .heartRate: "Heart"
        case .intake: "Intake"
        case .journal: "Journal"
        case .macros: "Macros"
        case .menstrual: "Menstrual"
        case .micros: "Micros"
        case .mind: "Mind"
        case .nutrition: "Nutrition"
        case .sleep: "Sleep"
        case .water: "Water"
        case .weight: "Weight"
        case .wellbeing: "Wellbeing"
        }
    }

    var systemImage: String {
        switch self {
        case .activity: "flame.fill"
        case .exercise: "figure.run"
        case .heartRate: "heart.fill"
        case .intake: "fork.knife"
        case .journal: "pencil.line"
        case .macros: "chart.pie.fill"
        case .menstrual: "moonphase.waxing.crescent"
        case .micros: "leaf.fill"
        case .mind: "brain.head.profile"
        case .nutrition: "fork.knife"
        case .sleep: "bed.double.fill"
        case .water: "drop.fill"
        case .weight: "scalemass.fill"
        case .wellbeing: "arrow.triangle.2.circlepath"
        }
    }

    // The black-and-white icon its row shows in the add sheet.
    var rowIcon: BrightRowV5Icon {
        switch self {
        case .activity: .template(ImageNames.activityAlertsIconV5)
        case .exercise: .symbol(systemImage)
        case .heartRate: .template(ImageNames.heartDashIconV4)
        case .intake: .template(ImageNames.logFoodIconV1)
        case .journal: .template(ImageNames.pencilBlueV5)
        case .macros: .template(ImageNames.macronutrientGraphV5)
        case .menstrual: .template(ImageNames.cycleTrackingMainV5)
        case .micros: .symbol(systemImage)
        case .mind: .symbol(systemImage)
        case .nutrition: .symbol(systemImage)
        case .sleep: .template(ImageNames.sleepInfoV4)
        case .water: .template(ImageNames.waterIconV5)
        case .weight: .template(ImageNames.weightIconV4)
        case .wellbeing: .template(ImageNames.recoveryV5)
        }
    }

    var tint: Color {
        switch self {
        case .activity: .defaultOrange
        case .exercise: .defaultSkyBlue
        case .heartRate: .defaultRed
        case .intake: .defaultGreen
        case .journal: .defaultCyan
        case .macros: .defaultGreen
        case .menstrual: .defaultPink
        case .micros: .defaultCyan
        case .mind: .defaultBrightPink
        case .nutrition: .defaultGreen
        case .sleep: .defaultBlue
        case .water: .defaultCyan
        case .weight: .defaultPurple
        case .wellbeing: .defaultGreen
        }
    }

    var styles: [HealthWidgetStyleV5] {
        switch self {
        case .activity: [.totalEnergyBars, .activeEnergyBars]
        case .exercise: [.exerciseSplits]
        case .heartRate: [.heartLine, .heartNumber, .vo2Line, .vo2Number]
        case .intake: [.intakeBars, .intakeRing, .intakeMeter]
        case .journal: [.journalChecklist]
        case .macros: [.macroBars, .macroRings, .macroRing, .macroMeter, .macroMeters]
        case .menstrual: [.menstrualCycle]
        case .micros: [.microRings]
        case .mind: [.mindNumber]
        case .nutrition: [.nutritionNumber]
        case .sleep: [.sleepRings, .sleepVitals, .sleepStages, .sleepStageRing, .sleepStageMeter]
        case .water: [.waterBars, .waterNumber, .waterRing, .waterTank, .waterMeter]
        case .weight: [.weightLine, .weightNumber]
        case .wellbeing: [.wellbeingRings, .wellbeingRing, .wellbeingMeter, .wellbeingMeters]
        }
    }
}

enum HealthMacroV5: String, CaseIterable, Codable, Identifiable {
    case carbs
    case fats
    case protein

    var id: Self { self }

    var title: String {
        switch self {
        case .carbs: "Carbs"
        case .fats: "Fats"
        case .protein: "Protein"
        }
    }
}

enum HealthSleepStageV5: String, CaseIterable, Codable, Identifiable {
    case awake
    case rem
    case core
    case deep

    var id: Self { self }

    var title: String {
        switch self {
        case .awake: "Awake"
        case .rem: "REM"
        case .core: "Core"
        case .deep: "Deep"
        }
    }
}

enum HealthNutrientV5: String, CaseIterable, Codable, Identifiable {
    case sodium
    case sugar
    case saturatedFat
    case cholesterol
    case caffeine
    case alcohol
    case fibre
    case calcium
    case iron
    case magnesium
    case potassium
    case zinc
    case vitaminB12
    case vitaminC
    case vitaminD

    static let maxPinned = 4
    static let defaultPins: [Self] = [.sodium, .sugar, .saturatedFat, .fibre]

    var id: Self { self }

    var title: String {
        switch self {
        case .sodium: "Sodium"
        case .sugar: "Sugar"
        case .saturatedFat: "Saturated Fat"
        case .cholesterol: "Cholesterol"
        case .caffeine: "Caffeine"
        case .alcohol: "Alcohol"
        case .fibre: "Fibre"
        case .calcium: "Calcium"
        case .iron: "Iron"
        case .magnesium: "Magnesium"
        case .potassium: "Potassium"
        case .zinc: "Zinc"
        case .vitaminB12: "Vitamin B12"
        case .vitaminC: "Vitamin C"
        case .vitaminD: "Vitamin D"
        }
    }

    var shortLabel: String {
        switch self {
        case .sodium: "Na"
        case .sugar: "Su"
        case .saturatedFat: "SF"
        case .cholesterol: "Ch"
        case .caffeine: "Cf"
        case .alcohol: "Al"
        case .fibre: "Fi"
        case .calcium: "Ca"
        case .iron: "Fe"
        case .magnesium: "Mg"
        case .potassium: "K"
        case .zinc: "Zn"
        case .vitaminB12: "B12"
        case .vitaminC: "C"
        case .vitaminD: "D"
        }
    }

    var unit: String {
        switch self {
        case .sugar, .saturatedFat, .fibre: "g"
        case .alcohol: "std"
        case .vitaminB12, .vitaminD: "µg"
        default: "mg"
        }
    }

    var isLimit: Bool {
        switch self {
        case .sodium, .sugar, .saturatedFat, .cholesterol, .caffeine, .alcohol: true
        default: false
        }
    }
}

enum HealthScoreV5: String, CaseIterable, Codable, Identifiable {
    case recovery
    case fatigue
    case readiness

    var id: Self { self }

    var title: String {
        switch self {
        case .recovery: "Recovery"
        case .fatigue: "Fatigue"
        case .readiness: "Readiness"
        }
    }
}

// Counts across everything the add sheet can make, for the debug stats.
enum HealthWidgetCatalogV5 {
    // Each kind's designs, paired with it.
    static var designs: [(kind: HealthWidgetKindV5, style: HealthWidgetStyleV5)] {
        HealthWidgetKindV5.allCases.flatMap { kind in kind.styles.map { (kind, $0) } }
    }

    static var designCount: Int {
        designs.count
    }

    static var sizedCount: Int {
        designs.reduce(0) { $0 + $1.style.sizes.count }
    }

    static var optionCount: Int {
        designs.reduce(0) { $0 + options(of: $1.style) }
    }

    static func optionCount(of family: HealthWidgetStyleV5.Family) -> Int {
        designs.filter { $0.style.family == family }.reduce(0) { $0 + options(of: $1.style) }
    }

    // Every size, range and macro a design can be set to.
    private static func options(of style: HealthWidgetStyleV5) -> Int {
        style.sizes.count * max(style.ranges.count, 1) * style.pickCount
    }
}

// The alternative designs a kind can be shown as, swiped between in the add and edit sheets.
// Each belongs to one kind, named for what it shows, and grouped in the kinds' order;
// `family` says which widget draws it.
enum HealthWidgetStyleV5: String, CaseIterable, Codable, Hashable, Identifiable {
    // MARK: Activity
    case totalEnergyBars
    case activeEnergyBars

    // MARK: Exercise
    case exerciseSplits

    // MARK: Heart
    case heartLine
    case heartNumber
    case vo2Line
    case vo2Number

    // MARK: Intake
    case intakeBars
    case intakeRing
    case intakeMeter

    // MARK: Journal
    case journalChecklist

    // MARK: Macros
    case macroBars
    case macroRings
    case macroRing
    case macroMeter
    case macroMeters

    // MARK: Menstrual
    case menstrualCycle

    // MARK: Micros
    case microRings

    // MARK: Mind
    case mindNumber

    // MARK: Nutrition
    case nutritionNumber

    // MARK: Sleep
    case sleepRings
    case sleepVitals
    case sleepStages
    case sleepStageRing
    case sleepStageMeter

    // MARK: Water
    case waterBars
    case waterNumber
    case waterRing
    case waterTank
    case waterMeter

    // MARK: Weight
    case weightLine
    case weightNumber

    // MARK: Wellbeing
    case wellbeingRings
    case wellbeingRing
    case wellbeingMeter
    case wellbeingMeters

    // Which widget draws it, grouped as the widget folders are.
    enum Family: CaseIterable {
        // MARK: Reusable, in Shared/Widgets/V5
        case bar
        case checklist
        case dottedLine
        case dottedRange
        case horizontalBar
        case line
        case number
        case ring

        // MARK: Features, in Shared/Widgets/V5/Features
        case exercise
        case menstrual
        case sleep
        case water

        var title: String {
            switch self {
            case .bar: "BrightVerticalBarChartWidgetV5"
            case .checklist: "BrightChecklistWidgetV5"
            case .dottedLine: "BrightDottedLineChartWidgetV5"
            case .dottedRange: "BrightDottedRangeChartWidgetV5"
            case .horizontalBar: "BrightHorizontalBarChartWidgetV5"
            case .line: "BrightLineChartWidgetV5"
            case .number: "BrightLeadingNumberWidgetV5"
            case .ring: "BrightRingGroupWidgetV5"
            case .exercise: "BrightExerciseSplitsWidgetV5"
            case .menstrual: "BrightMenstrualWidgetV5"
            case .sleep: "BrightSleepWidgetV5"
            case .water: "BrightWaterWidgetV5"
            }
        }
    }

    var id: Self { self }

    var family: Family {
        switch self {
        case .totalEnergyBars, .activeEnergyBars: .bar
        case .exerciseSplits: .exercise
        case .heartLine: .line
        case .heartNumber: .number
        case .vo2Line: .dottedLine
        case .vo2Number: .number
        case .intakeBars: .bar
        case .intakeRing: .ring
        case .intakeMeter: .horizontalBar
        case .journalChecklist: .checklist
        case .macroBars: .bar
        case .macroRings, .macroRing: .ring
        case .macroMeter, .macroMeters: .horizontalBar
        case .menstrualCycle: .menstrual
        case .microRings: .ring
        case .mindNumber: .number
        case .nutritionNumber: .number
        case .sleepRings: .ring
        case .sleepVitals: .dottedRange
        case .sleepStages: .sleep
        case .sleepStageRing: .ring
        case .sleepStageMeter: .horizontalBar
        case .waterBars: .bar
        case .waterNumber: .number
        case .waterRing: .ring
        case .waterTank: .water
        case .waterMeter: .horizontalBar
        case .weightLine: .dottedLine
        case .weightNumber: .number
        case .wellbeingRings: .ring
        case .wellbeingRing: .ring
        case .wellbeingMeter, .wellbeingMeters: .horizontalBar
        }
    }

    var sizes: [BrightWidgetSizeV5] {
        switch self {
        case .exerciseSplits: [.medium, .large]
        case .heartNumber: [.small]
        case .vo2Line: [.medium]
        case .vo2Number: [.small]
        case .intakeRing, .intakeMeter: [.small]
        case .journalChecklist: [.small]
        case .macroBars: [.medium, .large]
        case .macroRings: [.small, .medium]
        case .macroRing, .macroMeter: [.small]
        case .macroMeters: [.small, .medium]
        case .microRings: [.small, .medium]
        case .mindNumber: [.small]
        case .nutritionNumber: [.small]
        case .sleepRings: [.small, .medium]
        case .sleepVitals: [.small, .medium]
        case .sleepStages: [.small, .medium]
        case .sleepStageRing, .sleepStageMeter: [.small]
        case .waterNumber: [.small]
        case .waterRing: [.small, .medium]
        case .waterMeter: [.small]
        case .weightLine: [.medium, .large]
        case .weightNumber: [.small]
        case .wellbeingRings: [.small, .medium]
        case .wellbeingRing, .wellbeingMeter: [.small]
        case .wellbeingMeters: [.small, .medium]
        default: BrightWidgetSizeV5.allCases
        }
    }

    // The ranges it can be set to, the first being where it starts; always at least one.
    var ranges: [BrightWidgetRangeV5] {
        switch self {
        case .totalEnergyBars, .activeEnergyBars: [.today, .rolling12h, .week]
        case .exerciseSplits: [.latest]
        case .heartLine: [.rolling1h, .rolling6h, .rolling12h, .fixed6h, .fixed12h]
        case .heartNumber: [.latest]
        case .vo2Line: [.lastReadings]
        case .vo2Number: [.latest]
        case .intakeBars: [.today, .rolling12h, .week]
        case .intakeRing, .intakeMeter: [.today]
        case .journalChecklist: [.today]
        case .macroBars: [.week]
        case .macroRings, .macroRing, .macroMeter, .macroMeters: [.today]
        case .menstrualCycle: [.today]
        case .microRings: [.today]
        case .mindNumber: [.latest]
        case .nutritionNumber: [.latest]
        case .sleepRings, .sleepVitals, .sleepStages, .sleepStageRing, .sleepStageMeter: [.lastNight]
        case .waterBars: [.today, .rolling12h, .week]
        case .waterNumber: [.latest]
        case .waterRing, .waterTank, .waterMeter: [.today]
        case .weightLine: [.lastReadings]
        case .weightNumber: [.latest]
        case .wellbeingRings, .wellbeingRing, .wellbeingMeter, .wellbeingMeters: [.today]
        }
    }

    enum Pick {
        case macro
        case stage
        case score
        case nutrients
    }

    var pick: Pick? {
        switch self {
        case .macroRing, .macroMeter: .macro
        case .sleepStageRing, .sleepStageMeter: .stage
        case .wellbeingRing, .wellbeingMeter: .score
        case .microRings: .nutrients
        default: nil
        }
    }

    var pickCount: Int {
        switch pick {
        case .macro: HealthMacroV5.allCases.count
        case .stage: HealthSleepStageV5.allCases.count
        case .score: HealthScoreV5.allCases.count
        case .nutrients: HealthNutrientV5.allCases.count
        case nil: 1
        }
    }
}

struct HealthWidgetItemV5: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: HealthWidgetKindV5
    var style = HealthWidgetStyleV5.heartLine
    var size: BrightWidgetSizeV5
    var range = BrightWidgetRangeV5.rolling1h
    var macro = HealthMacroV5.carbs
    var stage = HealthSleepStageV5.awake
    var score = HealthScoreV5.recovery
    var nutrients = HealthNutrientV5.defaultPins
    var nutrientPinOrder = HealthNutrientV5.defaultPins

    init(
        kind: HealthWidgetKindV5,
        style: HealthWidgetStyleV5 = .heartLine,
        size: BrightWidgetSizeV5,
        range: BrightWidgetRangeV5? = nil
    ) {
        self.kind = kind
        self.size = size
        adopt(style)
        if let range, style.ranges.contains(range) {
            self.range = range
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decode(HealthWidgetKindV5.self, forKey: .kind)
        style = try container.decode(HealthWidgetStyleV5.self, forKey: .style)
        size = try container.decode(BrightWidgetSizeV5.self, forKey: .size)
        range = try container.decode(BrightWidgetRangeV5.self, forKey: .range)
        macro = try container.decodeIfPresent(HealthMacroV5.self, forKey: .macro) ?? .carbs
        stage = try container.decodeIfPresent(HealthSleepStageV5.self, forKey: .stage) ?? .awake
        score = try container.decodeIfPresent(HealthScoreV5.self, forKey: .score) ?? .recovery
        nutrients = try container.decodeIfPresent([HealthNutrientV5].self, forKey: .nutrients) ?? HealthNutrientV5.defaultPins
        nutrientPinOrder = try container.decodeIfPresent([HealthNutrientV5].self, forKey: .nutrientPinOrder) ?? nutrients
    }

    var picks: [HealthWidgetItemV5] {
        switch style.pick {
        case .macro: HealthMacroV5.allCases.map { macro in copy { $0.macro = macro } }
        case .stage: HealthSleepStageV5.allCases.map { stage in copy { $0.stage = stage } }
        case .score: HealthScoreV5.allCases.map { score in copy { $0.score = score } }
        case .nutrients, nil: [self]
        }
    }

    private func copy(_ change: (inout HealthWidgetItemV5) -> Void) -> HealthWidgetItemV5 {
        var widget = self
        widget.id = UUID()
        change(&widget)
        return widget
    }

    // Pinning past the limit swaps out the longest-pinned one, in its slot, so the other rings stay put.
    mutating func toggle(_ nutrient: HealthNutrientV5) {
        if let index = nutrients.firstIndex(of: nutrient) {
            nutrients.remove(at: index)
            nutrientPinOrder.removeAll { $0 == nutrient }
        } else if nutrients.count < HealthNutrientV5.maxPinned {
            nutrients.append(nutrient)
            nutrientPinOrder.append(nutrient)
        } else if let oldest = nutrientPinOrder.first, let slot = nutrients.firstIndex(of: oldest) {
            nutrients[slot] = nutrient
            nutrientPinOrder.removeFirst()
            nutrientPinOrder.append(nutrient)
        }
    }

    // Switches style, falling back to its first size and first range where the current
    // ones aren't offered.
    mutating func adopt(_ style: HealthWidgetStyleV5) {
        self.style = style
        if !style.sizes.contains(size), let first = style.sizes.first {
            size = first
        }
        if !style.ranges.isEmpty, !style.ranges.contains(range), let first = style.ranges.first {
            range = first
        }
    }
}

struct HealthGridPositionV5: Equatable, Hashable {
    var row: Int
    var col: Int
}

// Shared by the grid and the size picker so a preview is drawn at the size it lands at.
enum HealthWidgetGridMetricsV5 {
    static let columns = 2
    static let spacing: CGFloat = .spacing205x

    static func cellSize(containerWidth: CGFloat) -> CGFloat {
        max((containerWidth - spacing * CGFloat(columns + 1)) / CGFloat(columns), 1)
    }

    static func frame(for size: BrightWidgetSizeV5, cellSize: CGFloat) -> CGSize {
        CGSize(width: span(size.columns, cellSize: cellSize), height: span(size.rows, cellSize: cellSize))
    }

    // The size whose cells best match a frame being stretched by the resize handle.
    static func nearestSize(to extent: CGSize, in sizes: [BrightWidgetSizeV5], cellSize: CGFloat) -> BrightWidgetSizeV5? {
        let stride = cellSize + spacing
        let columns = (extent.width + spacing) / stride
        let rows = (extent.height + spacing) / stride
        return sizes.min { lhs, rhs in
            distance(of: lhs, columns: columns, rows: rows) < distance(of: rhs, columns: columns, rows: rows)
        }
    }

    private static func distance(of size: BrightWidgetSizeV5, columns: CGFloat, rows: CGFloat) -> CGFloat {
        pow(CGFloat(size.columns) - columns, 2) + pow(CGFloat(size.rows) - rows, 2)
    }

    private static func span(_ cells: Int, cellSize: CGFloat) -> CGFloat {
        let count = CGFloat(cells)
        return cellSize * count + spacing * (count - 1)
    }

    static func origin(of position: HealthGridPositionV5, cellSize: CGFloat) -> CGPoint {
        let stride = cellSize + spacing
        return CGPoint(x: CGFloat(position.col) * stride + spacing, y: CGFloat(position.row) * stride + spacing)
    }
}

@Observable
final class HealthWidgetLayoutV5 {
    private(set) var widgets: [HealthWidgetItemV5]
    private(set) var positions: [UUID: HealthGridPositionV5] = [:]

    static let defaultWidgets: [HealthWidgetItemV5] = [
        HealthWidgetItemV5(kind: .intake, style: .intakeMeter, size: .small),
        HealthWidgetItemV5(kind: .activity, style: .activeEnergyBars, size: .small, range: .today),
        HealthWidgetItemV5(kind: .sleep, style: .sleepRings, size: .medium),
        HealthWidgetItemV5(kind: .heartRate, style: .heartLine, size: .medium, range: .rolling1h),
        HealthWidgetItemV5(kind: .wellbeing, style: .wellbeingMeters, size: .small),
        HealthWidgetItemV5(kind: .water, style: .waterTank, size: .small),
        HealthWidgetItemV5(kind: .exercise, style: .exerciseSplits, size: .medium),
    ]

    var layoutText: String {
        widgets.map { widget in
            var line = "HealthWidgetItemV5(kind: .\(widget.kind.rawValue), style: .\(widget.style.rawValue), size: .\(widget.size.rawValue)"
            if widget.style.ranges.count > 1 {
                line += ", range: .\(widget.range.rawValue)"
            }
            switch widget.style.pick {
            case .macro: line += ", macro: .\(widget.macro.rawValue)"
            case .stage: line += ", stage: .\(widget.stage.rawValue)"
            case .score: line += ", score: .\(widget.score.rawValue)"
            case .nutrients: line += ", nutrients: [\(widget.nutrients.map { ".\($0.rawValue)" }.joined(separator: ", "))]"
            case nil: break
            }
            return line + "),"
        }
        .joined(separator: "\n")
    }

    init() {
        widgets = Self.loadSaved() ?? Self.defaultWidgets
        pack()
    }

    // MARK: - Editing

    func add(_ widget: HealthWidgetItemV5) {
        widgets.append(widget)
        commit()
    }

    // Replaces the grid with every kind and style that comes in this size, once for each
    // range and macro it offers, to check them all side by side.
    func showAll(_ size: BrightWidgetSizeV5) {
        showAll { _, widgetSize in widgetSize == size }
    }

    // The same, for every size of one family of widget, such as all the line charts.
    func showAll(_ family: HealthWidgetStyleV5.Family) {
        showAll { style, _ in style.family == family }
    }

    // A handful picked at random from every variant, for a fresh mix to check against.
    func showRandom(_ count: Int) {
        widgets = Array(variants { _, _ in true }.shuffled().prefix(count))
        commit()
    }

    private func showAll(where includes: (HealthWidgetStyleV5, BrightWidgetSizeV5) -> Bool) {
        widgets = variants(where: includes)
        commit()
    }

    private func variants(where includes: (HealthWidgetStyleV5, BrightWidgetSizeV5) -> Bool) -> [HealthWidgetItemV5] {
        HealthWidgetKindV5.allCases.flatMap { kind in
            kind.styles.flatMap { style in
                style.sizes.filter { includes(style, $0) }.flatMap { size in
                    style.ranges.flatMap { range in
                        var widget = HealthWidgetItemV5(kind: kind, style: style, size: size)
                        widget.range = range
                        return widget.picks
                    }
                }
            }
        }
    }

    func removeAll() {
        widgets.removeAll()
        commit()
    }

    // Every kind in every style at every size it comes in, for checking them all at once.
    func addAll() {
        for kind in HealthWidgetKindV5.allCases {
            for style in kind.styles {
                for size in style.sizes {
                    widgets.append(HealthWidgetItemV5(kind: kind, style: style, size: size))
                }
            }
        }
        commit()
    }

    func remove(id: UUID) {
        widgets.removeAll { $0.id == id }
        commit()
    }

    func update(_ widget: HealthWidgetItemV5) {
        guard let index = widgets.firstIndex(where: { $0.id == widget.id }) else { return }
        widgets[index] = widget
        commit()
    }

    func reset() {
        widgets = Self.defaultWidgets
        commit()
    }

    // Repacks around a widget held at `position` while it is being dragged.
    func preview(_ widget: HealthWidgetItemV5, at position: HealthGridPositionV5) {
        let lastRow = widgets
            .filter { $0.id != widget.id }
            .compactMap { other in positions[other.id].map { $0.row + other.size.rows } }
            .max() ?? 0
        let pinned = HealthGridPositionV5(
            row: min(max(position.row, 0), lastRow + 1),
            col: min(position.col, HealthWidgetGridMetricsV5.columns - widget.size.columns)
        )
        pack(pinning: (widget, pinned))
    }

    // Changes size in place while the resize handle is held, everything else flowing
    // around it; `commitDrag` saves it on release.
    func resize(_ widget: HealthWidgetItemV5, to size: BrightWidgetSizeV5, at position: HealthGridPositionV5) {
        guard let index = widgets.firstIndex(where: { $0.id == widget.id }) else { return }
        widgets[index].size = size
        pack(pinning: (widgets[index], position))
    }

    // Adopts the dragged or resized arrangement as the new reading order.
    func commitDrag() {
        widgets.sort { lhs, rhs in
            guard let left = positions[lhs.id], let right = positions[rhs.id] else { return false }
            return (left.row, left.col) < (right.row, right.col)
        }
        save()
    }

    // MARK: - Geometry

    func cell(at point: CGPoint, cellSize: CGFloat) -> HealthGridPositionV5? {
        let spacing = HealthWidgetGridMetricsV5.spacing
        let stride = cellSize + spacing
        guard point.x >= 0, point.y >= 0 else { return nil }

        let row = Int(point.y / stride)
        let col = point.x < stride + spacing / 2 ? 0 : 1
        guard point.x < stride * CGFloat(HealthWidgetGridMetricsV5.columns) + spacing else { return nil }

        let cellTop = CGFloat(row) * stride + spacing
        guard point.y >= cellTop - spacing / 2, point.y <= cellTop + cellSize + spacing / 2 else { return nil }
        return HealthGridPositionV5(row: row, col: col)
    }

    func height(cellSize: CGFloat) -> CGFloat {
        let rows = widgets
            .compactMap { widget in positions[widget.id].map { $0.row + widget.size.rows } }
            .max() ?? 0
        return CGFloat(rows) * (cellSize + HealthWidgetGridMetricsV5.spacing) + HealthWidgetGridMetricsV5.spacing
    }

    // MARK: - Private

    private func commit() {
        pack()
        save()
    }

    // First-fit packing in reading order. A pinned widget claims its cells first
    // and everything else flows around it.
    private func pack(pinning pinned: (widget: HealthWidgetItemV5, position: HealthGridPositionV5)? = nil) {
        var occupancy = Occupancy()
        var placed: [UUID: HealthGridPositionV5] = [:]

        if let pinned {
            occupancy.mark(pinned.position, size: pinned.widget.size)
            placed[pinned.widget.id] = pinned.position
        }

        for widget in widgets where widget.id != pinned?.widget.id {
            let position = occupancy.firstFit(for: widget.size)
            occupancy.mark(position, size: widget.size)
            placed[widget.id] = position
        }

        positions = placed
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(widgets) else { return }
        UserDefaults.standard.set(data, forKey: Constants.storageKey)
    }

    private static func loadSaved() -> [HealthWidgetItemV5]? {
        guard let data = UserDefaults.standard.data(forKey: Constants.storageKey) else { return nil }
        guard let items = try? JSONDecoder().decode([LossyItem].self, from: data) else { return nil }
        return items.compactMap(\.item)
    }

    private struct LossyItem: Decodable {
        let item: HealthWidgetItemV5?

        init(from decoder: Decoder) throws {
            item = try? HealthWidgetItemV5(from: decoder)
        }
    }

    private struct Occupancy {
        private var rows: [[Bool]] = []

        mutating func firstFit(for size: BrightWidgetSizeV5) -> HealthGridPositionV5 {
            var row = 0
            while true {
                for col in 0 ... (HealthWidgetGridMetricsV5.columns - size.columns) {
                    let position = HealthGridPositionV5(row: row, col: col)
                    if isFree(position, size: size) {
                        return position
                    }
                }
                row += 1
            }
        }

        mutating func mark(_ position: HealthGridPositionV5, size: BrightWidgetSizeV5) {
            grow(to: position.row + size.rows)
            for row in position.row ..< position.row + size.rows {
                for col in position.col ..< position.col + size.columns {
                    rows[row][col] = true
                }
            }
        }

        private mutating func isFree(_ position: HealthGridPositionV5, size: BrightWidgetSizeV5) -> Bool {
            grow(to: position.row + size.rows)
            for row in position.row ..< position.row + size.rows {
                for col in position.col ..< position.col + size.columns where rows[row][col] {
                    return false
                }
            }
            return true
        }

        private mutating func grow(to count: Int) {
            while rows.count < count {
                rows.append(Array(repeating: false, count: HealthWidgetGridMetricsV5.columns))
            }
        }
    }

    private enum Constants {
        static let storageKey = "healthWidgetLayoutV5"
    }
}
