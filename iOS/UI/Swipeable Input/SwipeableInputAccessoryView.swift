//
//  SwipeableInputAccessoryView.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/13/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie
import Combine

class SwipeableInputAccessoryView: BaseView {

    typealias InputState = SwipeableInputAccessoryViewController.InputState

    // MARK:  - Views

    /// A view that contains and provides a background for the input view.
    @IBOutlet var inputContainerView: SpeechBubbleView!
    /// Text view for users to input their message.
    @IBOutlet var textView: InputTextView!
    @IBOutlet var animationViewContainer: UIView!
    
    private let animationView = AnimationView.with(animation: .maxToMin)
    
    @IBOutlet var collapseButton: UIButton!
    /// An invisible button to handle taps and pan gestures.
    @IBOutlet var gestureButton: UIButton!
    @IBOutlet var countView: CharacterCountView!
    @IBOutlet var avatarView: BorderedPersonView!

    /// A view that contains delivery type and emotion selection views.
    @IBOutlet var inputTypeContainer: UIView!
    let emotionView = old_EmotionView()
    let deliveryTypeView = DeliveryTypeView()

    // MARK: - Layout/Animation Properties

    static let inputContainerCollapsedHeight: CGFloat = 76

    // Override intrinsic content size so that height is adjusted for safe areas and text input.
    // https://stackoverflow.com/questions/46282987/iphone-x-how-to-handle-view-controller-inputaccessoryview
    override var intrinsicContentSize: CGSize {
        return .zero
    }

    // The input container and avatar height together determine the height of the whole view.
    // When either of these two constraints are changed, the superview will resize to fit the new height.
    @IBOutlet var inputContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var avatarHeightConstraint: NSLayoutConstraint!

    @IBOutlet var textViewCollapsedVerticalCenterConstraint: NSLayoutConstraint!
    @IBOutlet var textViewCollapsedMaxHeightConstraint: NSLayoutConstraint!
    @IBOutlet var textViewExpandedTopPinConstraint: NSLayoutConstraint!
    @IBOutlet var textViewExpandedBottomPinConstraint: NSLayoutConstraint!

    // MARK: BaseView Setup and Layout

    override func initializeSubviews() {
        super.initializeSubviews()

        // A flexible height autoresizing mask allows our superview to resize in response to
        // changes to our internal content's height.
        self.translatesAutoresizingMaskIntoConstraints = false
        self.autoresizingMask = .flexibleHeight

        self.inputContainerView.showShadow(withOffset: 8)
        self.inputContainerView.setBubbleColor(ThemeColor.B1.color, animated: false)

        self.inputTypeContainer.addSubview(self.emotionView)
        self.emotionView.alpha = 0
        self.emotionView.configure(for: nil)
        
        self.inputTypeContainer.addSubview(self.deliveryTypeView)
        self.deliveryTypeView.alpha = 0
                
        self.avatarView.set(person: User.current()!)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.animationViewContainer.addSubview(self.animationView)
        self.animationView.loopMode = .playOnce
        let keypath = AnimationKeypath(keys: ["**", "Color"])
        let colorProvider = ColorValueProvider(ThemeColor.D6.color.lottieColorValue)
        self.animationView.animationSpeed = 0.5

        self.animationView.setValueProvider(colorProvider, keypath: keypath)
        self.animationView.contentMode = .scaleAspectFit
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.emotionView.pin(.left)
        self.deliveryTypeView.pin(.right)
        self.animationView.expandToSuperviewSize()
    }

    // MARK: - State Updates

    func updateLayout(for inputState: InputState) {
        let newInputHeight: CGFloat

        switch inputState {
        case .collapsed:
            NSLayoutConstraint.deactivate([self.textViewExpandedTopPinConstraint,
                                           self.textViewExpandedBottomPinConstraint])
            NSLayoutConstraint.activate([self.textViewCollapsedVerticalCenterConstraint,
                                         self.textViewCollapsedMaxHeightConstraint])

            self.textView.textContainer.lineBreakMode = .byTruncatingTail
            self.textView.isScrollEnabled = false
            self.textView.textAlignment = .center

            self.gestureButton.isVisible = true
            self.collapseButton.isVisible = false
            self.animationView.isVisible = false
            self.animationView.currentProgress = 0

            var proposedHeight = SwipeableInputAccessoryView.inputContainerCollapsedHeight
            if self.textView.numberOfLines > 2, let lineHeight = self.textView.font?.lineHeight {
                let multiplier: CGFloat = CGFloat(self.textView.numberOfLines) - 2
                proposedHeight += lineHeight * multiplier
            }
            newInputHeight = proposedHeight
        case .expanded:
            NSLayoutConstraint.deactivate([self.textViewCollapsedVerticalCenterConstraint,
                                           self.textViewCollapsedMaxHeightConstraint])
            NSLayoutConstraint.activate([self.textViewExpandedTopPinConstraint,
                                         self.textViewExpandedBottomPinConstraint])

            self.textView.textContainer.lineBreakMode = .byWordWrapping
            self.textView.isScrollEnabled = true
            self.textView.textAlignment = .left

            // Disable swipe gestures when expanded
            self.gestureButton.isVisible = false
            self.collapseButton.isVisible = true
            self.animationView.isVisible = true
            Task.onMainActorAsync {
                await Task.sleep(seconds: 0.5)
                self.animationView.play(fromFrame: 20, toFrame: 30, loopMode: .playOnce, completion: nil)
            }

            newInputHeight = self.window!.height - KeyboardManager.shared.cachedKeyboardEndFrame.height
        }

        // There's no need to animate the height if it hasn't changed.
        guard self.inputContainerHeightConstraint.constant != newInputHeight else { return }

        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.inputContainerHeightConstraint.constant = newInputHeight
            // Layout the window so that our container view also animates
            self.window?.layoutNow()
        }
    }

    func setShowMessageDetailOptions(_ shouldShow: Bool) {
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.emotionView.alpha = shouldShow ? 1.0 : 0.0
            self.deliveryTypeView.alpha = shouldShow ? 1.0 : 0.0
            self.avatarView.alpha = shouldShow ? 0.0 : 1.0
            self.avatarHeightConstraint.constant = shouldShow ? 0 : 44
            
            if shouldShow {
                self.countView.update(with: self.textView.text.count, max: self.textView.maxLength)
            } else {
                self.countView.alpha = 0.0
            }

            // Layout the window so that our container view also animates
            self.window?.layoutNow()
        }
    }
    
    func updateInputType(with type: InputType) {
        self.textView.updateInputView(type: type)
    }
}
