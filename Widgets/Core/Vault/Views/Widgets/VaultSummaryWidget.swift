//
//  VaultSummaryWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 14/10/2026.
//

import SwiftUI

struct VaultSummaryWidget: View {
    var ranking: VaultRankingData?
    var fallbackTopPercent: Double?

    @State private var gender = "men"
    @State private var ageRange = "18-24"
    @State private var topPct: Double?
    @State private var delta7d: Double = 0

    private static let genderOptions = ["men", "women"]
    private static let ageOptions = ["18-24", "25-34", "35-44", "45-54", "55-64", "65+"]

    private var fraction: Double? {
        (topPct ?? ranking?.topPct ?? fallbackTopPercent).map { 1 - $0 / 100 }
    }

    var body: some View {
        BrightWaveWidgetV5(
            title: "Global Health Ranking",
            fraction: fraction,
            delta: delta7d,
            emptySubtitle: "Your ranking appears once your data syncs",
            subtitle: { "Your health is better than \(Self.percent($0)) of users" },
            heldSubtitle: { "Scoring here beats \(Self.percent($0)) of users" }
        ) {
            cohortRow
        }
        .onChange(of: ranking?.topPct, initial: true) { _, _ in
            seedFromRanking()
        }
        .onChange(of: gender) { _, _ in refetch() }
        .onChange(of: ageRange) { _, _ in refetch() }
    }

    private func seedFromRanking() {
        guard let ranking else { return }
        topPct = ranking.topPct
        delta7d = ranking.delta7d ?? 0
        for axis in ranking.cohortAxes ?? [] {
            switch axis.axis?.lowercased() {
            case "sex":
                if let value = axis.value?.lowercased() {
                    gender = value == "female" ? "women" : "men"
                }
            case "age":
                if let value = axis.value, !value.isEmpty {
                    ageRange = value
                }
            default:
                break
            }
        }
    }

    private func refetch() {
        let sex = gender == "women" ? "female" : "male"
        let cohort = "sex:\(sex),age:\(ageRange)"
        let result = VaultRankingData.demo(cohort: cohort)
        withAnimation(.brightBouncy) {
            topPct = result.topPct ?? topPct
            delta7d = result.delta7d ?? delta7d
        }
    }

    // MARK: - Cohort

    private var cohortRow: some View {
        HStack(spacing: .spacing1x) {
            Image(systemName: "person.3.sequence.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.textColor, Color.lightTextColor, Color.textColor.opacity(.semiLowOpacity))
                .font(.standardSFPro(size: .subheading2, weight: .regular))

            BrightText("Cohort:", size: .body1, color: .lightTextColor, weight: .regular)
                .lineLimit(1)

            cohortMenu(selection: $gender, options: Self.genderOptions) { $0 == "women" ? "Female" : "Male" }

            cohortMenu(selection: $ageRange, options: Self.ageOptions) { Self.ageTitle($0) }
        }
    }

    private func cohortMenu(selection: Binding<String>, options: [String], title: @escaping (String) -> String) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button {
                    selection.wrappedValue = option
                } label: {
                    Label {
                        Text(title(option))
                    } icon: {
                        if option == selection.wrappedValue {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            BrightText(title(selection.wrappedValue), size: .body1, weight: .regular)
                .contentTransition(.numericText())
                .lineLimit(1)
                .padding(.horizontal, .spacing2x)
                .padding(.vertical, .spacing1x)
                .modifier(BrightGlassEffectV5(shape: .capsule))
                .contentShape(Capsule())
                .animation(.brightBouncy, value: selection.wrappedValue)
        }
        .buttonStyle(.plain)
        .brightHapticV5(.light, trigger: selection.wrappedValue)
    }

    // MARK: - Formatting

    private static func ageTitle(_ range: String) -> String {
        range.replacingOccurrences(of: "-", with: "–")
    }

    private static func percent(_ fraction: Double) -> String {
        BrightWaveWidgetV5<EmptyView>.percent(fraction * 100)
    }
}

#Preview {
    VaultSummaryWidget(ranking: .demo)
        .padding(.spacing3x)
        .background(Color.defaultBackground)
}
