//
//  GenomeOrderStatusWidget.swift
//  Widgets
//
//  Created by Dom Montalto on 1/7/2026.
//

import SwiftUI

struct GenomeOrderStatusWidget: View {
    private let status = GenomeOrderStatusDemoData.status
    private let eta = GenomeOrderStatusDemoData.eta
    private let totalSteps = GenomeOrderStatusDemoData.totalSteps
    private let completedSteps = GenomeOrderStatusDemoData.completedSteps

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            headerRow
            statusSection
            progressBar
                .padding(.bottom, .spacing1x)
        }
        .padding(.spacing3x)
        .modifier(CardModifier())
    }

    // MARK: Header

    private var headerRow: some View {
        HStack {
            HStack(spacing: .spacing2x) {
                Image(ImageNames.genomeDnaV5)
                
                BrightText("Genome test", size: .body1)
            }
            Spacer()
            
            HStack(spacing: .spacing1x) {
                Image(ImageNames.genomeClockV5)

                BrightText(eta, size: .body3, color: Color.lightTextColor)
            }
        }
    }

    // MARK: Status

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: .spacing05x) {
            BrightText("Status", size: .body3, color: Color.lightTextColor)
            BrightText(status, size: .heading, color: Color.defaultSkyBlue)
        }
    }

    // MARK: Progress Bar

    private var progressBar: some View {
        HStack(spacing: .spacing1x) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i < completedSteps ? Color.defaultSkyBlue : Color.defaultSkyBlue.opacity(.minimalOpacity))
                    .frame(height: 9)
            }
        }
    }
}

#Preview {
    GenomeOrderStatusWidget()
        .padding(.spacing3x)
        .background(Color.bG.ignoresSafeArea())
}
