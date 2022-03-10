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
    @IBOutlet var avatarView: BorderedPersoniew!

    /// A view that contains delivery type and emotion selection views.
    @IBOutlet var inputTypeContainer: UIView!
    let emotionView = old_EmotionView()
    let deliveryTypeView = DeliveryTypeView()

    // MARK: - Height Accessors

    static var inputContainerCollapsedHeight: CGFloat = 76

    // MARK: - Layout/Animation Properties

    override var intrinsicContentSize: CGSize {
        return .zero
    }

    @IBOutlet var inputContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var avatarHeightConstraint: NSLayoutConstraint!
    @IBOutlet var textViewCollapsedVerticalCenterConstraint: NSLayoutConstraint!
    @IBOutlet var textViewCollapsedMaxHeightConstraint: NSLayoutConstraint!
    @IBOutlet var textViewExpandedTopPinConstraint: NSLayoutConstraint!
    @IBOutlet var textViewExpandedBottomPinConstraint: NSLayoutConstraint!

    // MARK: BaseView Setup and Layout

    override func initializeSubviews() {
        super.initializeSubviews()

        // This allows the accessory view's container to respect its intrinsic content size.
        self.translatesAutoresizingMaskIntoConstraints = false
        self.autoresizingMask = [.flexibleHeight]

        self.inputContainerView.showShadow(withOffset: 8)
        self.inputContainerView.setBubbleColor(ThemeColor.B1.color, animated: false)

        self.inputTypeContainer.addSubview(self.emotionView)
        self.emotionView.alpha = 0
        
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

            newInputHeight = SwipeableInputAccessoryView.inputContainerCollapsedHeight
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

            self.window?.layoutNow()
        }
    }
    
    func updateInputType(with type: InputType) {
        self.textView.updateInputView(type: type)
    }
}
