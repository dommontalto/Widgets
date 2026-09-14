//
//  BrightPromptInputBar.swift
//  Widgets
//
//  Created by Dom Montalto on 24/8/2026.
//

import SwiftUI
import UIKit

// An image waiting in the input card to go with the next message.
nonisolated struct BrightChatAttachment: Identifiable, Equatable {
    let id = UUID()
    let image: UIImage

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

// Where the "+" can pull an attachment from.
enum BrightChatAttachmentSource: CaseIterable, Identifiable {
    case camera
    case photos
    case files

    var id: Self { self }

    var title: String {
        switch self {
        case .camera: "Camera"
        case .photos: "Photos"
        case .files: "Files"
        }
    }

    var symbol: String {
        switch self {
        case .camera: "camera"
        case .photos: "photo.on.rectangle"
        case .files: "folder"
        }
    }

    // The simulator has no camera, so the option only shows where it works.
    var isAvailable: Bool {
        switch self {
        case .camera: UIImagePickerController.isSourceTypeAvailable(.camera)
        case .photos, .files: true
        }
    }
}

struct BrightPromptInputBar<ModelPicker: View>: View {
    @Binding var text: String
    @Binding var attachments: [BrightChatAttachment]
    let isBusy: Bool
    var isFocused: FocusState<Bool>.Binding
    var showsModelPicker: Bool
    var onSend: () -> Void
    var onStop: () -> Void
    var onAttach: (BrightChatAttachmentSource) -> Void
    // Pass the caller's own so it can watch the mic — Lighthouse shows the
    // orb listening — otherwise the bar keeps one to itself.
    var sharedDictation: BrightDictation?
    @ViewBuilder var modelPicker: ModelPicker

    @State private var nudge = 0
    @State private var ownDictation = BrightDictation()

    private var dictation: BrightDictation {
        sharedDictation ?? ownDictation
    }

    init(
        text: Binding<String>,
        attachments: Binding<[BrightChatAttachment]> = .constant([]),
        isBusy: Bool,
        isFocused: FocusState<Bool>.Binding,
        showsModelPicker: Bool,
        onSend: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onAttach: @escaping (BrightChatAttachmentSource) -> Void = { _ in },
        dictation: BrightDictation? = nil,
        @ViewBuilder modelPicker: () -> ModelPicker
    ) {
        _text = text
        _attachments = attachments
        self.isBusy = isBusy
        self.isFocused = isFocused
        self.showsModelPicker = showsModelPicker
        self.onSend = onSend
        self.onStop = onStop
        self.onAttach = onAttach
        self.sharedDictation = dictation
        self.modelPicker = modelPicker()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing2x) {
            if !attachments.isEmpty {
                attachmentStrip
                    .transition(.scale(scale: 0.9, anchor: .bottomLeading).combined(with: .opacity))
            }

            field
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .center, spacing: .spacing1x) {
                if showsModelPicker {
                    modelPicker
                        .frame(height: BrightButtonSizes.large.rawValue)
                }

                Spacer(minLength: .spacing2x)

                attachMenu

                actionButton
            }
        }
        .animation(.brightBouncy, value: isBusy)
        .animation(.brightSnappy, value: attachments)
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

    private var attachmentStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacing2x) {
                ForEach(attachments) { attachment in
                    thumbnail(attachment)
                }
            }
            .padding(.top, .spacing1x)
            .padding(.horizontal, .spacing1x)
        }
        .scrollClipDisabled()
    }

    private func thumbnail(_ attachment: BrightChatAttachment) -> some View {
        Image(uiImage: attachment.image)
            .resizable()
            .scaledToFill()
            .frame(width: Constants.thumbnailSize, height: Constants.thumbnailSize)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Button {
                    attachments.removeAll { $0.id == attachment.id }
                } label: {
                    Image(systemName: "xmark")
                        .font(.standard(size: .body5, weight: .medium))
                        .foregroundStyle(Color.white)
                        .frame(width: Constants.removeSize, height: Constants.removeSize)
                        .background(Color.black.opacity(.lowOpacity), in: .circle)
                        .contentShape(Circle())
                }
                .padding(.spacing05x)
            }
    }

    // Each source the "+" can draw from; the caller presents the picker.
    // The bar sits at the foot of the screen, so the menu opens upward and
    // iOS stacks its items from the button up — reversed here so the first
    // source reads at the top.
    private var attachMenu: some View {
        Menu {
            ForEach(BrightChatAttachmentSource.allCases.filter(\.isAvailable).reversed()) { source in
                Button {
                    onAttach(source)
                } label: {
                    Label(source.title, systemImage: source.symbol)
                }
            }
        } label: {
            glyph("plus")
        }
    }

    // A bare glyph rather than a BrightRoundButton: inside the card's own glass
    // a second glass circle reads as a chip.
    private func glyph(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.standard(size: .subheading1, weight: .regular))
            .foregroundStyle(Color.textColor)
            // Narrower than it is tall so the two glyphs sit close together
            // while each keeps a 44pt-tall tap target.
            .frame(width: BrightButtonSizes.medium.rawValue, height: BrightButtonSizes.large.rawValue)
            .contentShape(Rectangle())
    }

    // What the round button does right now: with nothing to send it listens,
    // and it morphs into the send arrow as soon as there's something typed.
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
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty
    }

    private var actionButton: some View {
        BrightRoundButton(
            systemImage: action.symbol,
            size: .large,
            imageColor: action == .dictating ? .defaultRed : nil
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
    static let thumbnailSize: CGFloat = .spacing10x
    static let removeSize: CGFloat = .spacing3x
}

extension BrightPromptInputBar where ModelPicker == EmptyView {
    init(
        text: Binding<String>,
        attachments: Binding<[BrightChatAttachment]> = .constant([]),
        isBusy: Bool,
        isFocused: FocusState<Bool>.Binding,
        showsModelPicker: Bool = false,
        onSend: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onAttach: @escaping (BrightChatAttachmentSource) -> Void = { _ in },
        dictation: BrightDictation? = nil
    ) {
        self.init(
            text: text,
            attachments: attachments,
            isBusy: isBusy,
            isFocused: isFocused,
            showsModelPicker: showsModelPicker,
            onSend: onSend,
            onStop: onStop,
            onAttach: onAttach,
            dictation: dictation
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
