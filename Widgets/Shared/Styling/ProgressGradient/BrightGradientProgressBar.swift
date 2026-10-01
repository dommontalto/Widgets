//
//  BrightGradientProgressBar.swift
//  Widgets
//
//  Created by Gangajaliya Sandeep on 14/8/2024.
//

import CoreGraphics
import Foundation
import QuartzCore
import SwiftUI
import UIKit

// Protocol for managing a progress bar, as defined by `UIProgressView` from Apple.
// To provide the same interface with `BrightGradientProgressBar`, we're gonna make both classes conform to this
// protocol.
//
// - SeeAlso: [Apple documentation for `UIProgressView`](https://apple.co/2HjwstS)
protocol BrightUIProgressHandling {
    // The current progress shown by the receiver (between 0.0 and 1.0, inclusive).
    var progress: Float { get set }

    // Adjusts the current progress shown by the receiver, optionally animating the change.
    //
    // - Parameters:
    //   - progress: The new progress value (between 0.0 and 1.0, inclusive).
    //   - animated: `true` if the change should be animated, `false` if the change should happen immediately.
    func setProgress(_ progress: Float, animated: Bool)
}

extension UIProgressView: BrightUIProgressHandling {}

// A customizable gradient progress view.
@IBDesignable
open class BrightGradientProgressBar: UIView {
    // MARK: - Public properties

    // Gradient colors for the progress view.
    public var gradientColors: [UIColor] {
        get { gradientLayerViewModel.gradientColors }
        set { gradientLayerViewModel.gradientColors = newValue }
    }

    // Animation duration for calls to `setProgress(x, animated: true)`.
    public var animationDuration: TimeInterval {
        get { maskLayerViewModel.animationDuration }
        set { maskLayerViewModel.animationDuration = newValue }
    }

    // Animation timing function for calls to `setProgress(x, animated: true)`.
    public var timingFunction: CAMediaTimingFunction {
        get { maskLayerViewModel.timingFunction }
        set { maskLayerViewModel.timingFunction = newValue }
    }

    // Layer containing the gradient.
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.anchorPoint = .zero
        layer.startPoint = .zero
        layer.endPoint = CGPoint(x: 1, y: 0)

        return layer
    }()

    // Alpha mask for showing only the visible "progress"-part of the gradient layer.
    public let maskLayer: CALayer = {
        let maskLayer = CALayer()
        maskLayer.backgroundColor = UIColor.white.cgColor

        return maskLayer
    }()

    // MARK: - Private properties

    // View-model containing all logic related to the gradient-layer.
    private let gradientLayerViewModel = BrightGradientLayerViewModel()

    // View-model containing all logic related to the mask-layer.
    private let maskLayerViewModel = BrightMaskLayerViewModel()

    // MARK: - Instance Lifecycle

    override public init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    // MARK: - Public methods

    override open func layoutSubviews() {
        super.layoutSubviews()

        // Unfortunately `CALayer` is not affected by autolayout, so any change in the size of the view will not change
        // the gradient layer.
        // That's why we'll have to update the frame here manually.
        gradientLayer.frame = bounds

        // Inform the view-model about the changed bounds, so it can calculate a new frame for the mask-layer, based on
        // the current progress value.
        maskLayerViewModel.bounds = bounds
    }

    // MARK: - Private methods

    private func commonInit() {
        setupProgressView()
        bindViewModelsToView()
    }

    private func setupProgressView() {
        backgroundColor = UIColor.BrightGradientProgressBar.backgroundColor

        // Apply the mask to the gradient layer, in order to show only the current progress of the gradient.
        gradientLayer.mask = maskLayer
        layer.insertSublayer(gradientLayer, at: 0)
    }

    private func bindViewModelsToView() {
        gradientLayerViewModel.onGradientLayerColorsChanged = { [weak self] gradientLayerColors in
            self?.gradientLayer.colors = gradientLayerColors
        }

        maskLayerViewModel.onMaskLayerFrameAnimationChanged = { [weak self] maskLayerFrameAnimation in
            self?.animateMaskLayer(
                frame: maskLayerFrameAnimation.frame,
                duration: maskLayerFrameAnimation.duration,
                timingFunction: maskLayerFrameAnimation.timingFunction
            )
        }
    }

    private func animateMaskLayer(frame: CGRect, duration: TimeInterval, timingFunction: CAMediaTimingFunction) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(timingFunction)

        maskLayer.frame = frame

        CATransaction.commit()
    }
}

// MARK: - `BrightUIProgressHandling` conformance

extension BrightGradientProgressBar: BrightUIProgressHandling {
    // MARK: - Public properties

    @IBInspectable
    open var progress: Float {
        get { maskLayerViewModel.progress }
        set { maskLayerViewModel.progress = newValue }
    }

    // MARK: - Public methods

    public func setProgress(_ progress: Float, animated: Bool) {
        maskLayerViewModel.setProgress(progress, animated: animated)
    }
}

extension UIColor {
    // Default colors for components.
    public enum BrightGradientProgressBar {
        // Default background color for the progress view in light mode.
        static let backgroundColorForLightMode = #colorLiteral(red: 0.8980392157, green: 0.9137254902, blue: 0.9215686275, alpha: 1)

        // Default background color for the progress view in dark mode.
        static let backgroundColorForDarkMode = #colorLiteral(red: 0.1725490196, green: 0.1882352941, blue: 0.1843137255, alpha: 1)

        // Default background color for the progress view.
        static let backgroundColor = UIColor {
            $0.userInterfaceStyle == .dark ? backgroundColorForDarkMode : backgroundColorForLightMode
        }

        // The default color palette for the gradient colors.
        //
        public static let gradientColors = [
            #colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1), #colorLiteral(red: 0.3529411765, green: 0.7843137255, blue: 0.9803921569, alpha: 1), #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1), #colorLiteral(red: 0.2039215686, green: 0.6666666667, blue: 0.862745098, alpha: 1), #colorLiteral(red: 0.3450980392, green: 0.337254902, blue: 0.8392156863, alpha: 1), #colorLiteral(red: 1, green: 0.1764705882, blue: 0.3333333333, alpha: 1),
        ]
    }
}

extension TimeInterval {
    // Numeric default values.
    public enum BrightGradientProgressBar {
        // Default animation duration for calls to `setProgress(x, animated: true)`.
        //
        // - Note: Equals to `CALayer` default animation duration (https://apple.co/2PVTCsB).
        static let progressAnimationDuration = 0.25
    }
}

extension CAMediaTimingFunction {
    // Default animation timing functions.
    public enum BrightGradientProgressBar {
        // Default animation timing function for calls to `setProgress(x, animated: true)`.
        static let progressAnimationFunction = CAMediaTimingFunction(name: .default)
    }
}

// This view model keeps track of the gradient-colors and updates the `gradientLayer` accordingly.
final class BrightGradientLayerViewModel {
    // MARK: - Public properties

    // Callback for when gradient layer colors change (of type `CGColor`).
    var onGradientLayerColorsChanged: (([CGColor]) -> Void)?

    // Color array used for the gradient progress bar (of type `UIColor`).
    var gradientColors: [UIColor] = UIColor.BrightGradientProgressBar.gradientColors {
        didSet {
            onGradientLayerColorsChanged?(gradientColors.map(\.cgColor))
        }
    }
}

// This view model keeps track of the progress-value and updates the `maskLayer` accordingly.
final class BrightMaskLayerViewModel {
    // MARK: - Public properties

    // Callback for frame-animation changes on the mask layer.
    var onMaskLayerFrameAnimationChanged: ((FrameAnimation) -> Void)?

    // The current bounds of the progress view.
    var bounds: CGRect = .zero {
        didSet {
            // Update mask-layer frame accordingly.
            let animation = makeMaskLayerFrameAnimation(animated: false)
            onMaskLayerFrameAnimationChanged?(animation)
        }
    }

    // The current progress.
    var progress: Float {
        get { _progress }
        set {
            _progress = newValue.clamped(to: 0 ... 1)
            let animation = makeMaskLayerFrameAnimation(animated: false)
            onMaskLayerFrameAnimationChanged?(animation)
        }
    }

    // Animation duration for an animated progress change.
    var animationDuration = TimeInterval.BrightGradientProgressBar.progressAnimationDuration

    // Animation timing function for an animated progress change.
    var timingFunction = CAMediaTimingFunction.BrightGradientProgressBar.progressAnimationFunction

    // MARK: - Private properties

    // The actual storage for our progress.
    //
    // We store the value on a separate properties for two reasons:
    // - This makes sure the progress stays between zero and one.
    // - The setter of `progress` can set a progress and always update the frame of the layer without an animation.
    //   The method `setProgress(_:animated:)` can set a progress and afterwards update the frame with a possible
    // animation.
    private var _progress: Float = 0.5

    // MARK: - Public methods

    // Adjusts the current progress, optionally animating the change.
    func setProgress(_ progress: Float, animated: Bool = false) {
        _progress = progress.clamped(to: 0 ... 1)
        let animation = makeMaskLayerFrameAnimation(animated: animated)
        onMaskLayerFrameAnimationChanged?(animation)
    }

    // MARK: - Private methods

    private func makeMaskLayerFrameAnimation(animated: Bool) -> FrameAnimation {
        var maskLayerFrame = bounds
        maskLayerFrame.size.width *= CGFloat(progress)

        let animationDuration: TimeInterval = if animated {
            self.animationDuration
        } else {
            0
        }

        return FrameAnimation(
            frame: maskLayerFrame,
            duration: animationDuration,
            timingFunction: timingFunction
        )
    }
}

// MARK: - Supporting Types

extension BrightMaskLayerViewModel {
    // Combines all properties for an animated update of a frame.
    struct FrameAnimation: Equatable {
        // Initializes the struct with all values set to zero / default.
        static let zero = Self(
            frame: .zero,
            duration: 0,
            timingFunction: CAMediaTimingFunction(name: .default)
        )

        // The new rect for the frame.
        let frame: CGRect

        // The animation duration to update the frame with.
        let duration: TimeInterval

        // The timing function to update the frame with (e.g. `easeInOut`).
        let timingFunction: CAMediaTimingFunction
    }
}

// MARK: - Helper

extension Comparable {
    // Clamps the current value to the boundaries of the given `limits`.
    //
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

public struct BrightGradientProgressBarViewStyle: ProgressViewStyle {
    // MARK: - Config

    public enum Config {
        public static let defaultBackgroundColor = Color(UIColor.BrightGradientProgressBar.backgroundColor)
        public static let defaultGradientColors = UIColor.BrightGradientProgressBar.gradientColors.map(Color.init)
        public static let defaultCornerRadius: Double = 2
    }

    // MARK: - Public properties

    let backgroundColor: Color
    let gradientColors: [Color]
    let cornerRadius: Double

    // MARK: - Public methods

    public func makeBody(configuration: Configuration) -> some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)

                LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                    .mask(alignment: .leading) {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .frame(width: (configuration.fractionCompleted ?? 0) * proxy.size.width)
                    }
            }
        }
    }
}

// MARK: - Helper

extension ProgressViewStyle where Self == BrightGradientProgressBarViewStyle {
    // Syntactic sugar for returning an instance of the `BrightGradientProgressBarViewStyle`
    // with the **default parameters**.
    public static var gradientProgressBar: Self {
        gradientProgressBar()
    }

    // Syntactic sugar for returning an instance of the `BrightGradientProgressBarViewStyle`.
    //
    // - Parameters:
    //  - backgroundColor: The background-color shown behind the gradient (clipped by a possible `cornerRadius`).
    //  - gradientColors: The colors used for the gradient.
    //  - cornerRadius: The corner-radius used on the background and the progress bar.
    public static func gradientProgressBar(
        backgroundColor: Color = BrightGradientProgressBarViewStyle.Config
            .defaultBackgroundColor,
        gradientColors: [Color] = BrightGradientProgressBarViewStyle.Config
            .defaultGradientColors,
        cornerRadius: Double = BrightGradientProgressBarViewStyle.Config
            .defaultCornerRadius
    ) -> Self {
        BrightGradientProgressBarViewStyle(
            backgroundColor: backgroundColor,
            gradientColors: gradientColors,
            cornerRadius: cornerRadius
        )
    }
}
