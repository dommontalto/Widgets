//
//  VaultDatapointDetailSheet.swift
//  Widgets
//
//  Created by Dom Montalto on 13/7/2026.
//

import SwiftUI

struct VaultDatapointDetailSheet: View {
    let title: String

    @State private var selectedRange = "W"
    @State private var rangeFrames: [String: CGRect] = [:]
    @Namespace private var rangePill

    private static let ranges = ["W", "M", "3M", "1Y"]

    var body: some View {
        BrightPageSheetViewV5(title: title, showBackButton: true) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: .spacing4x) {
                    noDataBanner

                    rangeSelector

                    BrightGraphV5()
                        .frame(height: 250)

                    statPills
                }
                .padding(.top, .spacing2x)
                .padding(.bottom, .spacing4x)
            }
            .scrollClipDisabled()
        }
    }

    // MARK: - No data

    private var noDataBanner: some View {
        VStack(alignment: .leading, spacing: .spacing1x) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 26))
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.defaultBlue, Color.defaultBlue.opacity(.minimalOpacity))

            BrightText("No data found for this datapoint.", size: .body2, color: .defaultBlue)
        }
        .padding(.spacing2x + .spacing05x)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: .cardCornerRadius, style: .continuous)
                .fill(Color.defaultBlue.opacity(.finalBossLowOpacity))
        )
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
                                .modifier(BrightGlassEffectV5(shape: .capsule))
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
        .brightHapticV5(.light, trigger: selectedRange)
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
            .modifier(BrightGlassEffectV5(shape: .capsule, interactive: false))
    }
}

#Preview {
    VaultDatapointDetailSheet(title: "Hemoglobin")
}
