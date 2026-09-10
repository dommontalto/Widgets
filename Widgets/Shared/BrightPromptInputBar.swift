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
    var onAttach: () -> Void
    var onDictate: () -> Void
    @ViewBuilder var modelPicker: ModelPicker

    @State private var nudge = 0

    init(
        text: Binding<String>,
        isBusy: Bool,
        isFocused: FocusState<Bool>.Binding,
        showsModelPicker: Bool,
        onSend: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onAttach: @escaping () -> Void = {},
        onDictate: @escaping () -> Void = {},
        @ViewBuilder modelPicker: () -> ModelPicker
    ) {
        _text = text
        self.isBusy = isBusy
        self.isFocused = isFocused
        self.showsModelPicker = showsModelPicker
        self.onSend = onSend
        self.onStop = onStop
        self.onAttach = onAttach
        self.onDictate = onDictate
        self.modelPicker = modelPicker()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            field
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .center, spacing: .spacing2x) {
                if showsModelPicker {
                    modelPicker
                        .frame(height: BrightButtonSizes.large.rawValue)
                }

                Spacer(minLength: .spacing2x)

                HStack(spacing: .spacing0x) {
                    glyphButton("plus", action: onAttach)
                    glyphButton("mic.fill", action: onDictate)
                }

                sendOrStopButton
            }
        }
        .animation(.brightBouncy, value: isBusy)
        .padding(.spacing2x)
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .onTapGesture { isFocused.wrappedValue = true }
        .modifier(GlassEffect(shape: .unevenRoundedRect(top: Constants.topCorner, bottom: Constants.bottomCorner)))
        .geometryGroup()
    }

    private var field: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                BrightText("Ask Lighthouse", size: .subheading2, color: .lightTextColor)
                    .lineLimit(1)
                    .allowsHitTesting(false)
                    .brightWiggle(trigger: nudge)
            }

            TextField("", text: $text, axis: .vertical)
                .font(.standard(size: .subheading2, weight: .light))
                .foregroundStyle(Color.textColor)
                .lineLimit(1 ... Constants.maxLines)
                .focused(isFocused)
                .submitLabel(.return)
        }
        .padding(.top, .spacing105x)
        .padding(.horizontal, .spacing1x)
    }

    // A bare glyph rather than a BrightRoundButton: inside the card's own glass
    // a second glass circle reads as a chip.
    private func glyphButton(_ systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.standard(size: .subheading1, weight: .regular))
                .foregroundStyle(Color.textColor)
                // Narrower than it is tall so the two glyphs sit close together
                // while each keeps a 44pt-tall tap target.
                .frame(width: BrightButtonSizes.medium.rawValue, height: BrightButtonSizes.large.rawValue)
                .contentShape(Rectangle())
        }
    }

    private var sendOrStopButton: some View {
        BrightRoundButton(systemImage: isBusy ? "stop.fill" : "arrow.up", size: .large) {
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
    static let topCorner: CGFloat = .cornerRadius36
    static let bottomCorner: CGFloat = .cornerRadius44
    static let maxLines = 8
}

extension BrightPromptInputBar where ModelPicker == EmptyView {
    init(
        text: Binding<String>,
        isBusy: Bool,
        isFocused: FocusState<Bool>.Binding,
        showsModelPicker: Bool = false,
        onSend: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onAttach: @escaping () -> Void = {},
        onDictate: @escaping () -> Void = {}
    ) {
        self.init(
            text: text,
            isBusy: isBusy,
            isFocused: isFocused,
            showsModelPicker: showsModelPicker,
            onSend: onSend,
            onStop: onStop,
            onAttach: onAttach,
            onDictate: onDictate
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
