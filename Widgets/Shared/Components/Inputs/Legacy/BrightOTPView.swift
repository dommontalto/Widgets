//
//  BrightOTPView.swift
//  Widgets
//
//  Created by Gangajaliya Sandeep on 13/10/2024.
//

import SwiftUI

public struct BrightOTPView: View {
    // MARK: - PROPERTIES

    //
    // A Boolean value that used to help the `BrightOTPView` supporting Clear OTP
    @State private var flag = false
    // A Binding String value of the OTP
    @Binding private var text: String
    // An Intger value to set the number of the slots of the `BrightOTPView`
    private let slotsCount: Int
    // A CGFloat value to set a custom width to the `BrightOTPView`
    private let width: CGFloat?
    // A CGFloat value to set a custom height to the `BrightOTPView`
    private let height: CGFloat
    // The default character placed in the text field slots
    private let otpDefaultCharacter: String
    // The default background color of the text field slots before entering a character
    private let otpBackgroundColor: UIColor
    // The default background color of the text field slots after entering a character
    private let otpFilledBackgroundColor: UIColor
    // The default corner raduis of the text field slots
    private let otpCornerRaduis: CGFloat
    // The default border color of the text field slots before entering a character
    private let otpDefaultBorderColor: UIColor
    // The border color of the text field slots after entering a character
    private let otpFilledBorderColor: UIColor
    // The default border width of the text field slots before entering a character
    private let otpDefaultBorderWidth: CGFloat
    // The border width of the text field slots after entering a character
    private let otpFilledBorderWidth: CGFloat
    // The default text color of the text
    private let otpTextColor: UIColor
    // The default font size of the text
    private let otpFontSize: CGFloat
    // The default font of the text
    private let otpFont: UIFont
    // A Boolean value that indicates whether the text object disables text copying and, in some cases, hides the text
    // that the user enters.
    private let isSecureTextEntry: Bool
    // A Boolean value that used to allow the `BrightOTPView` clear the OTP and set the `BrightOTPView` to the default
    // state when you set the OTP Text with Empty Value
    private let enableClearOTP: Bool
    // A Closure that fires when the OTP returned
    private var onCommit: (() -> Void)?

    // MARK: - INIT

    //
    // The Initializer of the `BrightOTPTextView`
    // - Parameters:
    //   - text: The OTP text that entered into BrightOTPView
    //   - slotsCount: The number of OTP slots in the BrightOTPView
    //   - width: The default width of the BrightOTPView
    //   - height: The default height of the BrightOTPView
    //   - otpDefaultCharacter: The default character placed in the text field slots
    //   - otpBackgroundColor: The default background color of the text field slots before entering a character
    //   - otpFilledBackgroundColor: The default background color of the text field slots after entering a character
    //   - otpCornerRaduis: The default corner raduis of the text field slots
    //   - otpDefaultBorderColor: The default border color of the text field slots before entering a character
    //   - otpFilledBorderColor: The border color of the text field slots after entering a character
    //   - otpDefaultBorderWidth: The default border width of the text field slots before entering a character
    //   - otpFilledBorderWidth: The border width of the text field slots after entering a character
    //   - otpTextColor: The default text color of the text
    //   - otpFontSize: The default font size of the text
    //   - otpFont: The default font of the text
    //   - isSecureTextEntry: A Boolean value that indicates whether the text object disables text copying and, in some
    // cases, hides the text that the user enters.
    //   - enableClearOTP: A Boolean value that used to allow the `BrightOTPView` clear the OTP and set the
    // `BrightOTPView` to the default state when you set the OTP Text with Empty Value
    //   - onCommit: A Closure that fires when the OTP returned
    public init(
        text: Binding<String>,
        slotsCount: Int = 6,
        width: CGFloat? = nil,
        height: CGFloat = 40,
        otpDefaultCharacter: String = "",
        otpBackgroundColor: UIColor = UIColor(red: 0.949, green: 0.949, blue: 0.949, alpha: 1),
        otpFilledBackgroundColor: UIColor = UIColor(red: 0.949, green: 0.949, blue: 0.949, alpha: 1),
        otpCornerRaduis: CGFloat = 10,
        otpDefaultBorderColor: UIColor = .clear,
        otpFilledBorderColor: UIColor = .darkGray,
        otpDefaultBorderWidth: CGFloat = 0,
        otpFilledBorderWidth: CGFloat = 1,
        otpTextColor: UIColor = .black,
        otpFontSize: CGFloat = 27,
        otpFont: UIFont = UIFont.systemFont(ofSize: 27, weight: .light),
        isSecureTextEntry: Bool = false,
        enableClearOTP: Bool = false,
        onCommit: (() -> Void)? = nil
    ) {
        _text = text
        self.slotsCount = slotsCount
        self.width = width
        self.height = height
        self.otpDefaultCharacter = otpDefaultCharacter
        self.otpBackgroundColor = otpBackgroundColor
        self.otpFilledBackgroundColor = otpFilledBackgroundColor
        self.otpCornerRaduis = otpCornerRaduis
        self.otpDefaultBorderColor = otpDefaultBorderColor
        self.otpFilledBorderColor = otpFilledBorderColor
        self.otpDefaultBorderWidth = otpDefaultBorderWidth
        self.otpFilledBorderWidth = otpFilledBorderWidth
        self.otpTextColor = otpTextColor
        self.otpFontSize = otpFontSize
        self.otpFont = otpFont
        self.isSecureTextEntry = isSecureTextEntry
        self.enableClearOTP = enableClearOTP
        self.onCommit = onCommit
    }

    // MARK: - BODY

    //
    public var body: some View {
        ZStack {
            if flag {
                otpView
            } else {
                otpView
            }
        } //: ZStack
        // Without a width it takes 80% of its container.
        .containerRelativeFrame(.horizontal) { length, _ in width ?? length * 0.8 }
        .frame(height: height)
        .onChange(of: text) { _, newValue in
            guard enableClearOTP else { return }
            if newValue.isEmpty {
                flag.toggle()
            } //: condition
        } //: onChange
    } //: body

    // MARK: - VIEWS

    //
    var otpView: some View {
        BrightOTPViewRepresentable(
            text: $text,
            slotsCount: slotsCount,
            otpDefaultCharacter: otpDefaultCharacter,
            otpBackgroundColor: otpBackgroundColor,
            otpFilledBackgroundColor: otpFilledBackgroundColor,
            otpCornerRaduis: otpCornerRaduis,
            otpDefaultBorderColor: otpDefaultBorderColor,
            otpFilledBorderColor: otpFilledBorderColor,
            otpDefaultBorderWidth: otpDefaultBorderWidth,
            otpFilledBorderWidth: otpFilledBorderWidth,
            otpTextColor: otpTextColor,
            otpFontSize: otpFontSize,
            otpFont: otpFont,
            isSecureTextEntry: isSecureTextEntry,
            onCommit: onCommit
        )
    } //: otpView
}

struct BrightOTPViewRepresentable: UIViewRepresentable {
    @Binding private var text: String
    private let slotsCount: Int
    private let otpDefaultCharacter: String
    private let otpBackgroundColor: UIColor
    private let otpFilledBackgroundColor: UIColor
    private let otpCornerRaduis: CGFloat
    private let otpDefaultBorderColor: UIColor
    private let otpFilledBorderColor: UIColor
    private let otpDefaultBorderWidth: CGFloat
    private let otpFilledBorderWidth: CGFloat
    private let otpTextColor: UIColor
    private let otpFontSize: CGFloat
    private let otpFont: UIFont
    private let isSecureTextEntry: Bool
    private let onCommit: (() -> Void)?
    private let textField: BrightOTPTextFieldSwiftUI

    init(
        text: Binding<String>,
        slotsCount: Int = 6,
        otpDefaultCharacter: String = "",
        otpBackgroundColor: UIColor = UIColor(red: 0.949, green: 0.949, blue: 0.949, alpha: 1),
        otpFilledBackgroundColor: UIColor = UIColor(red: 0.949, green: 0.949, blue: 0.949, alpha: 1),
        otpCornerRaduis: CGFloat = 10,
        otpDefaultBorderColor: UIColor = .clear,
        otpFilledBorderColor: UIColor = .darkGray,
        otpDefaultBorderWidth: CGFloat = 0,
        otpFilledBorderWidth: CGFloat = 1,
        otpTextColor: UIColor = .black,
        otpFontSize: CGFloat = 14,
        otpFont: UIFont = UIFont.systemFont(ofSize: 14),
        isSecureTextEntry: Bool = false,
        onCommit: (() -> Void)? = nil
    ) {
        _text = text
        self.slotsCount = slotsCount
        self.otpDefaultCharacter = otpDefaultCharacter
        self.otpBackgroundColor = otpBackgroundColor
        self.otpFilledBackgroundColor = otpFilledBackgroundColor
        self.otpCornerRaduis = otpCornerRaduis
        self.otpDefaultBorderColor = otpDefaultBorderColor
        self.otpFilledBorderColor = otpFilledBorderColor
        self.otpDefaultBorderWidth = otpDefaultBorderWidth
        self.otpFilledBorderWidth = otpFilledBorderWidth
        self.otpTextColor = otpTextColor
        self.otpFontSize = otpFontSize
        self.otpFont = otpFont
        self.isSecureTextEntry = isSecureTextEntry
        self.onCommit = onCommit

        textField = BrightOTPTextFieldSwiftUI(
            slotsCount: slotsCount,
            otpDefaultCharacter: otpDefaultCharacter,
            otpBackgroundColor: otpBackgroundColor,
            otpFilledBackgroundColor: otpFilledBackgroundColor,
            otpCornerRaduis: otpCornerRaduis,
            otpDefaultBorderColor: otpDefaultBorderColor,
            otpFilledBorderColor: otpFilledBorderColor,
            otpDefaultBorderWidth: otpDefaultBorderWidth,
            otpFilledBorderWidth: otpFilledBorderWidth,
            otpTextColor: otpTextColor,
            otpFontSize: otpFontSize,
            otpFont: otpFont,
            isSecureTextEntry: isSecureTextEntry
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, slotsCount: slotsCount, onCommit: onCommit)
    }

    func makeUIView(context: Context) -> BrightOTPTextFieldSwiftUI {
        textField.delegate = context.coordinator
        return textField
    }

    func updateUIView(_ uiView: BrightOTPTextFieldSwiftUI, context: Context) {}

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding private var text: String

        private let slotsCount: Int
        private let onCommit: (() -> Void)?

        init(
            text: Binding<String>,
            slotsCount: Int,
            onCommit: (() -> Void)?
        ) {
            _text = text
            self.slotsCount = slotsCount
            self.onCommit = onCommit

            super.init()
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""

            if textField.text?.count == slotsCount {
                onCommit?()
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            guard let characterCount = textField.text?.count else { return false }
            return characterCount < slotsCount || string.isEmpty
        }
    }
}

class BrightOTPTextFieldSwiftUI: BrightOTPTextField {
    init(
        slotsCount: Int,
        otpDefaultCharacter: String,
        otpBackgroundColor: UIColor,
        otpFilledBackgroundColor: UIColor,
        otpCornerRaduis: CGFloat,
        otpDefaultBorderColor: UIColor,
        otpFilledBorderColor: UIColor,
        otpDefaultBorderWidth: CGFloat,
        otpFilledBorderWidth: CGFloat,
        otpTextColor: UIColor,
        otpFontSize: CGFloat,
        otpFont: UIFont,
        isSecureTextEntry: Bool
    ) {
        super.init(frame: .zero)

        self.otpDefaultCharacter = otpDefaultCharacter
        self.otpBackgroundColor = otpBackgroundColor
        self.otpFilledBackgroundColor = otpFilledBackgroundColor
        self.otpCornerRaduis = otpCornerRaduis
        self.otpDefaultBorderColor = otpDefaultBorderColor
        self.otpFilledBorderColor = otpFilledBorderColor
        self.otpDefaultBorderWidth = otpDefaultBorderWidth
        self.otpFilledBorderWidth = otpFilledBorderWidth
        self.otpTextColor = otpTextColor
        self.otpFontSize = otpFontSize
        self.otpFont = otpFont
        self.isSecureTextEntry = isSecureTextEntry

        configure(with: slotsCount)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class BrightOTPTextField: UITextField {
    // MARK: - PROPERTIES

    //
    // The default character placed in the text field slots
    public var otpDefaultCharacter = ""
    // The default background color of the text field slots before entering a character
    public var otpBackgroundColor = UIColor(red: 0.949, green: 0.949, blue: 0.949, alpha: 1)
    // The default background color of the text field slots after entering a character
    public var otpFilledBackgroundColor = UIColor(red: 0.949, green: 0.949, blue: 0.949, alpha: 1)
    // The default corner raduis of the text field slots
    public var otpCornerRaduis: CGFloat = 10
    // The default border color of the text field slots before entering a character
    public var otpDefaultBorderColor: UIColor = .clear
    // The border color of the text field slots after entering a character
    public var otpFilledBorderColor: UIColor = .darkGray
    // The default border width of the text field slots before entering a character
    public var otpDefaultBorderWidth: CGFloat = 0
    // The border width of the text field slots after entering a character
    public var otpFilledBorderWidth: CGFloat = 1
    // The default text color of the text
    public var otpTextColor: UIColor = .black
    // The default font size of the text
    public var otpFontSize: CGFloat = 14
    // The default font of the text
    public var otpFont = UIFont.systemFont(ofSize: 14)
    // The delegate of the BrightOTPTextFieldDelegate protocol
    public weak var otpDelegate: BrightOTPTextFieldDelegate?

    private var implementation = BrightOTPTextFieldImplementation()
    private var isConfigured = false
    private var digitLabels = [UILabel]()
    private lazy var tapRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer()
        recognizer.addTarget(self, action: #selector(becomeFirstResponder))
        return recognizer
    }()

    // MARK: - METHODS

    //
    // This func is used to configure the `BrightOTPTextField`, Usually you need to call this method into
    // `viewDidLoad()`
    // - Parameter slotCount: the number of OTP slots in the TextField
    public func configure(with slotCount: Int = 6) {
        guard isConfigured == false else { return }
        isConfigured.toggle()
        configureTextField()

        let labelsStackView = createLabelsStackView(with: slotCount)
        addSubview(labelsStackView)
        addGestureRecognizer(tapRecognizer)
        NSLayoutConstraint.activate([
            labelsStackView.topAnchor.constraint(equalTo: topAnchor),
            labelsStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            labelsStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            labelsStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // Use this func if you need to clear the `OTP` text and reset the `BrightOTPTextField` to the default state
    public func clearOTP() {
        text = nil
        for currentLabel in digitLabels {
            currentLabel.text = otpDefaultCharacter
            currentLabel.textColor = otpTextColor.withAlphaComponent(0.3)
            currentLabel.layer.borderWidth = otpDefaultBorderWidth
            currentLabel.layer.borderColor = otpDefaultBorderColor.cgColor
            currentLabel.backgroundColor = otpBackgroundColor
        }
    }
    // Use this func to set the text in the code
    public func setText(_ text: String) {
        let characters = Array(text)
        for i in 0 ..< characters.count {
            if digitLabels.indices.contains(i) {
                digitLabels[i].text = String(characters[i])
            }
        }
    }
}

// MARK: - PRIVATE METHODS

//
extension BrightOTPTextField {
    private func configureTextField() {
        tintColor = .clear
        textColor = .clear
        keyboardType = .numberPad
        textContentType = .oneTimeCode
        borderStyle = .none
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        delegate = implementation
        implementation.implementationDelegate = self
        becomeFirstResponder()
        font = Font.standardUIFont(size: .standout1, weight: .light)
    }

    private func createLabelsStackView(with count: Int) -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        for _ in 1 ... count {
            let label = createLabel()
            stackView.addArrangedSubview(label)
            digitLabels.append(label)
        }
        return stackView
    }

    private func createLabel() -> UILabel {
        let label = UILabel()
        label.backgroundColor = otpBackgroundColor
        label.layer.cornerRadius = otpCornerRaduis
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = otpTextColor
        label.font = Font.standardUIFont(size: .standout1, weight: .light)
        // label.font = otpFont
        label.isUserInteractionEnabled = true
        label.layer.masksToBounds = true
        label.text = otpDefaultCharacter
        label.textColor = otpTextColor.withAlphaComponent(0.3)
        return label
    }

    @objc
    private func textDidChange() {
        guard let text, text.count <= digitLabels.count else { return }
        for labelIndex in 0 ..< digitLabels.count {
            let currentLabel = digitLabels[labelIndex]
            if labelIndex < text.count {
                let index = text.index(text.startIndex, offsetBy: labelIndex)
                currentLabel.text = isSecureTextEntry ? "✱" : String(text[index])
                currentLabel.textColor = otpTextColor
                currentLabel.layer.borderWidth = otpFilledBorderWidth
                currentLabel.layer.borderColor = otpFilledBorderColor.cgColor
                currentLabel.backgroundColor = otpFilledBackgroundColor
            } else {
                currentLabel.text = otpDefaultCharacter
                currentLabel.textColor = otpTextColor.withAlphaComponent(0.3)
                currentLabel.layer.borderWidth = otpDefaultBorderWidth
                currentLabel.layer.borderColor = otpDefaultBorderColor.cgColor
                currentLabel.backgroundColor = otpBackgroundColor
            }
        }

        if text.count == digitLabels.count {
            otpDelegate?.didUserFinishEnter(the: text)
        }
    }
}

// MARK: - BrightOTPTextFieldImplementationProtocol Delegate

//
extension BrightOTPTextField: BrightOTPTextFieldImplementationProtocol {
    var digitalLabelsCount: Int {
        digitLabels.count
    }
}

public protocol BrightOTPTextFieldDelegate: AnyObject {
    func didUserFinishEnter(the code: String)
}

class BrightOTPTextFieldImplementation: NSObject, UITextFieldDelegate {
    weak var implementationDelegate: BrightOTPTextFieldImplementationProtocol?

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let characterCount = textField.text?.count else { return false }
        return characterCount < implementationDelegate?.digitalLabelsCount ?? 0 || string == ""
    }
}

protocol BrightOTPTextFieldImplementationProtocol: AnyObject {
    var digitalLabelsCount: Int { get }
}
