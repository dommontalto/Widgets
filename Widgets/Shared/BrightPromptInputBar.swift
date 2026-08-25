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

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing0x) {
            field
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            HStack(alignment: .center, spacing: .spacing2x) {
                if showsModelPicker {
                    modelPicker
                }

                Spacer(minLength: .spacing0x)

                sendOrStopButton
            }
            .animation(.brightBouncy, value: isBusy)
        }
        .padding(.spacing3x)
        .frame(maxWidth: .infinity)
        .frame(height: Constants.barHeight, alignment: .bottom)
        .contentShape(.rect)
        .onTapGesture { isFocused.wrappedValue = true }
        .modifier(GlassEffect(shape: .unevenRoundedRect(
            top: Constants.topCorner,
            bottom: Constants.bottomCorner
        )))
    }

    private var field: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                BrightText("What would you like me to do?", size: .subheading2, color: .lightTextColor)
                    .allowsHitTesting(false)
            }

            TextField("", text: $text, axis: .vertical)
                .font(.standard(size: .subheading2, weight: .light))
                .foregroundStyle(Color.textColor)
                .lineLimit(1 ... 3)
                .focused(isFocused)
                .submitLabel(.send)
                .brightWiggle(trigger: nudge)
                .onSubmit(send)
        }
    }

    private var sendOrStopButton: some View {
        BrightRoundButton(
            systemImage: isBusy ? "stop.fill" : "arrow.up",
            size: .large
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

// Outside the struct: a generic type cannot hold static stored properties.
private enum Constants {
    static let barHeight: CGFloat = 120
    static let topCorner: CGFloat = 36
    static let bottomCorner: CGFloat = 44
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
