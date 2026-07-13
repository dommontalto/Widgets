//
//  VaultDatapointDetailSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 13/7/2026.
//

import SwiftUI

/// Full-height datapoint detail: latest value + status tag, range selector,
/// BrightGraph, AVG/Range pills, and the guided-testing card.
struct VaultDatapointDetailSheet: View {
    let metric: VaultDemoData.Metric

    @Environment(\.dismiss) private var dismiss
    @State private var selectedRange = "D"
    @State private var showingTests = false
    @State private var rangeFrames: [String: CGRect] = [:]
    @Namespace private var rangePill

    private static let ranges = ["D", "W", "M", "3M", "1Y"]

    private var valueNumber: String {
        metric.value.split(separator: " ", maxSplits: 1).first.map(String.init) ?? metric.value
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: .spacing4x) {
                latest
                rangeSelector
                BrightGraph()
                    .frame(height: 250)
                statPills
                VaultGuidedTestingCard {
                    withAnimation(.brightBouncy) {
                        showingTests = true
                    }
                }
            }
            .padding(.horizontal, .spacing3x)
            .padding(.top, .spacing2x)
            .padding(.bottom, .spacing4x)
        }
        .safeAreaInset(edge: .top) { topBar }
        .background(Color.bG)
        .sheet(isPresented: $showingTests) {
            VaultTestsSheet(onDismiss: {
                showingTests = false
            })
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            BrightText(metric.title, size: .body1, weight: .regular)

            HStack {
                glassButton {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.textColor)
                        .frame(width: 44, height: 44)
                } action: { dismiss() }

                Spacer()
            }
        }
        .padding(.horizontal, .spacing3x)
        .padding(.vertical, .spacing2x)
    }

    private func glassButton<Label: View>(@ViewBuilder label: () -> Label, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            label()
                .modifier(GlassEffect(shape: .circle, interactive: false))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Latest value

    private var latest: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            BrightText("Latest", size: .body2, color: .lightTextColor)

            HStack(spacing: .spacing2x) {
                BrightText(valueNumber, size: .huge)
                    .monospacedDigit()
                BrightHealthStatus(status: "Optimal")
            }

            BrightText("Today, 21 Jan, 2026", size: .body2, color: .lightTextColor)
        }
    }

    // MARK: - Range selector

    private var rangeSelector: some View {
        HStack(spacing: .spacing1x) {
            ForEach(Self.ranges, id: \.self) { range in
                BrightText(range, size: .body1)
                    .padding(.horizontal, .spacing3x)
                    .frame(height: 30)
                    .background {
                        if selectedRange == range {
                            Color.clear
                                .modifier(GlassEffect(shape: .capsule))
                                .matchedGeometryEffect(id: "rangePill", in: rangePill)
                        }
                    }
                    .contentShape(Capsule())
                    .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .named("rangeSelector")) }) {
                        rangeFrames[range] = $0
                    }
                    .onTapGesture {
                        withAnimation(.brightBouncy) { selectedRange = range }
                    }
            }
        }
        .coordinateSpace(name: "rangeSelector")
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: selectedRange)
        .gesture(
            DragGesture(minimumDistance: 5, coordinateSpace: .named("rangeSelector"))
                .onChanged { value in
                    guard let nearest = rangeFrames.min(by: {
                        abs($0.value.midX - value.location.x) < abs($1.value.midX - value.location.x)
                    })?.key, nearest != selectedRange else { return }
                    withAnimation(.brightBouncy) { selectedRange = nearest }
                }
        )
    }

    // MARK: - Stat pills

    private var statPills: some View {
        HStack(spacing: .spacing2x) {
            statPill("AVG –")
            statPill("Range –")
        }
    }

    private func statPill(_ text: String) -> some View {
        BrightText(text, size: .body4)
            .padding(.horizontal, .spacing2x)
            .frame(height: 30)
            .modifier(GlassEffect(shape: .capsule, interactive: false))
    }
}

#Preview {
    VaultDatapointDetailSheet(metric: VaultDemoData.metric(forIndex: 0))
}
