//
//  ExerciseProgramPromptInputBar.swift
//  Widgets
//
//  Created by Dom Montalto on 24/8/2026.
//

import SwiftUI

struct ExerciseProgramPromptInputBar<ModelPicker: View>: View {
    @Binding var text: String
    let isBusy: Bool
    var isFocused: FocusState<Bool>.Binding
    var showsModelPicker: Bool
    var onSend: () -> Void
    var onStop: () -> Void
    var onAttach: () -> Void
    // Reported in the chat's input coordinate space, so a sent bubble can be
    // laid over the field it flies out of.
    var fieldFrame: Binding<CGRect>
    var sendTint: Color?
    var placeholder: String
    @ViewBuilder var modelPicker: ModelPicker

    @State private var nudge = 0
    @State private var dictation = BrightDictation()

    init(
        text: Binding<String>,
        isBusy: Bool,
        isFocused: FocusState<Bool>.Binding,
        showsModelPicker: Bool,
        onSend: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onAttach: @escaping () -> Void = {},
        fieldFrame: Binding<CGRect> = .constant(.zero),
        sendTint: Color? = nil,
        placeholder: String = "Ask Lighthouse",
        @ViewBuilder modelPicker: () -> ModelPicker
    ) {
        _text = text
        self.isBusy = isBusy
        self.isFocused = isFocused
        self.showsModelPicker = showsModelPicker
        self.onSend = onSend
        self.onStop = onStop
        self.onAttach = onAttach
        self.fieldFrame = fieldFrame
        self.sendTint = sendTint
        self.placeholder = placeholder
        self.modelPicker = modelPicker()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            field
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .center, spacing: .spacing1x) {
                if showsModelPicker {
                    modelPicker
                        .frame(height: BrightButtonSizes.large.rawValue)
                }

                Spacer(minLength: .spacing2x)

                glyphButton("plus", action: onAttach)

                actionButton
            }
        }
        .animation(.brightBouncy, value: isBusy)
        .animation(.brightSnappy, value: action)
        .onDisappear { dictation.stop() }
        .padding(.spacing2x)
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .onTapGesture { isFocused.wrappedValue = true }
        .modifier(GlassEffect(shape: .unevenRoundedRect(top: Constants.topCorner, bottom: bottomCorner)))
        .animation(.brightSnappy, value: bottomCorner)
        .geometryGroup()
    }

    // Riding above the keyboard the card is a shape in its own right, so it
    // rounds evenly; sat on the bottom of the screen the lower corners open out
    // to follow the display's own curve.
    private var bottomCorner: CGFloat {
        isFocused.wrappedValue ? Constants.topCorner : Constants.bottomCorner
    }

    private var field: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                BrightText(placeholder, size: .subheading2, color: .lightTextColor)
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
        .onGeometryChange(for: CGRect.self) {
            $0.frame(in: .named(BrightChatSpace.input))
        } action: { fieldFrame.wrappedValue = $0 }
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

    private enum Action {
        case stop
        case dictating
        case send
        case dictate

        var symbol: String {
            switch self {
            case .stop: "stop.fill"
            case .dictating: "waveform"
            case .send: "arrow.up"
            case .dictate: "mic.fill"
            }
        }

        var color: Color? {
            self == .send ? .textColor : nil
        }

        var imageColor: Color? {
            switch self {
            case .send: .defaultBlackWhite
            case .dictating, .stop: .defaultRed
            case .dictate: nil
            }
        }
    }

    private var action: Action {
        if isBusy {
            .stop
        } else if dictation.isListening {
            .dictating
        } else if hasContent {
            .send
        } else {
            .dictate
        }
    }

    private var hasContent: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var actionButton: some View {
        BrightRoundButton(
            systemImage: action.symbol,
            size: .medium,
            color: action == .send ? sendTint ?? action.color : action.color,
            imageColor: action == .send && sendTint != nil ? .white : action.imageColor
        ) {
            switch action {
            case .stop: onStop()
            case .dictating, .dictate: dictation.toggle($text)
            case .send: send()
            }
        }
        .symbolEffect(.variableColor.iterative, isActive: action == .dictating)
        .contentTransition(.symbolEffect(.replace.upUp))
        .brightHaptic(.light, trigger: dictation.isListening)
    }

    private func send() {
        guard hasContent else {
            nudge += 1
            return
        }

        dictation.stop()
        onSend()
    }
}

private enum Constants {
    static let topCorner: CGFloat = .cornerRadius36
    static let bottomCorner: CGFloat = .cornerRadius44
    static let maxLines = 8
}

extension ExerciseProgramPromptInputBar where ModelPicker == EmptyView {
    init(
        text: Binding<String>,
        isBusy: Bool,
        isFocused: FocusState<Bool>.Binding,
        showsModelPicker: Bool = false,
        onSend: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onAttach: @escaping () -> Void = {},
        fieldFrame: Binding<CGRect> = .constant(.zero)
    ) {
        self.init(
            text: text,
            isBusy: isBusy,
            isFocused: isFocused,
            showsModelPicker: showsModelPicker,
            onSend: onSend,
            onStop: onStop,
            onAttach: onAttach,
            fieldFrame: fieldFrame
        ) {
            EmptyView()
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    @Previewable @FocusState var isFocused: Bool

    ExerciseProgramPromptInputBar(
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
