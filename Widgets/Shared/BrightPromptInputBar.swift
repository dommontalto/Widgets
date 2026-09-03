//
//  BrightPromptInputBar.swift
//  Widgets
//
//  Created by Dom Montalto on 24/8/2026.
//

import SwiftUI

struct BrightPromptInputBar<ModelPicker: View>: View {
    @Binding var text: String
    let isBusy: Bool
    var isFocused: FocusState<Bool>.Binding
    var showsModelPicker: Bool
    var onSend: () -> Void
    var onStop: () -> Void
    @ViewBuilder var modelPicker: ModelPicker

    @State private var nudge = 0

    init(
        text: Binding<String>,
        isBusy: Bool,
        isFocused: FocusState<Bool>.Binding,
        showsModelPicker: Bool,
        onSend: @escaping () -> Void,
        onStop: @escaping () -> Void,
        @ViewBuilder modelPicker: () -> ModelPicker
    ) {
        _text = text
        self.isBusy = isBusy
        self.isFocused = isFocused
        self.showsModelPicker = showsModelPicker
        self.onSend = onSend
        self.onStop = onStop
        self.modelPicker = modelPicker()
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: .spacing2x) {
            if showsModelPicker {
                modelPicker
                    .frame(height: BrightButtonSizes.large.rawValue)
            }

            field
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: BrightButtonSizes.large.rawValue)

            sendOrStopButton
        }
        .animation(.brightBouncy, value: isBusy)
        .padding(.spacing2x)
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .onTapGesture { isFocused.wrappedValue = true }
        .modifier(GlassEffect(shape: .roundedRect, cornerRadius: Constants.cornerRadius))
        .geometryGroup()
    }

    private var field: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                BrightText("Ask Lighthouse", size: .subheading2, color: .lightTextColor)
                    .lineLimit(1)
                    .allowsHitTesting(false)
            }

            TextField("", text: $text, axis: .vertical)
                .font(.standard(size: .subheading2, weight: .light))
                .foregroundStyle(Color.textColor)
                .lineLimit(1 ... Constants.maxLines)
                .focused(isFocused)
                .submitLabel(.return)
                .brightWiggle(trigger: nudge)
        }
        .padding(.vertical, .spacing105x)
        .padding(.leading, .spacing1x)
    }

    private var sendOrStopButton: some View {
        BrightRoundButton(
            systemImage: isBusy ? "stop.fill" : "arrow.up",
            size: .large,
            color: .textColor,
            imageColor: .defaultBlackWhite
        ) {
            if isBusy {
                onStop()
            } else {
                send()
            }
        }
        .contentTransition(.symbolEffect(.replace.upUp))
    }

    private func send() {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            nudge += 1
            return
        }

        onSend()
    }
}

private enum Constants {
    static let cornerRadius: CGFloat = (BrightButtonSizes.large.rawValue + .spacing2x * 2) / 2
    static let maxLines = 8
}

extension BrightPromptInputBar where ModelPicker == EmptyView {
    init(
        text: Binding<String>,
        isBusy: Bool,
        isFocused: FocusState<Bool>.Binding,
        showsModelPicker: Bool = false,
        onSend: @escaping () -> Void,
        onStop: @escaping () -> Void
    ) {
        self.init(
            text: text,
            isBusy: isBusy,
            isFocused: isFocused,
            showsModelPicker: showsModelPicker,
            onSend: onSend,
            onStop: onStop
        ) {
            EmptyView()
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    @Previewable @FocusState var isFocused: Bool

    BrightPromptInputBar(
        text: $text,
        isBusy: false,
        isFocused: $isFocused,
        onSend: {},
        onStop: {}
    )
    .padding(.spacing3x)
    .frame(maxHeight: .infinity, alignment: .bottom)
    .background(Color.defaultBackground.ignoresSafeArea())
}
