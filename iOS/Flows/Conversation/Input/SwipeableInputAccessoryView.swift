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
    @IBOutlet var addView: AddMediaView!
    @IBOutlet var doneButton: ThemeButton!
        
    /// An invisible button to handle taps and pan gestures.
    @IBOutlet var gestureButton: UIButton!
    @IBOutlet var characterCountView: CharacterCountView!
    @IBOutlet var avatarView: BorderedPersonView!

    /// A view that contains delivery type and emotion selection views.
    @IBOutlet var inputTypeContainer: UIView!
    @IBOutlet var expressionView: ExpressionView!
    
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
    @IBOutlet var avatarTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var textViewCollapsedVerticalHeightContstraint: NSLayoutConstraint!
    @IBOutlet var textViewCollapsedVerticalCenterConstraint: NSLayoutConstraint!
    @IBOutlet var textViewExpandedTopPinConstraint: NSLayoutConstraint!
    @IBOutlet var textViewExpandedBottomPinConstraint: NSLayoutConstraint!
    @IBOutlet var textViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var textViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet var addViewHeightContstrain: NSLayoutConstraint!
    @IBOutlet var addViewWidthContstrain: NSLayoutConstraint!
    
    let unreadMessagesView = UnreadMessagesCounter()
    let typingIndicatorView = TypingIndicatorView()
    
    // MARK: BaseView Setup and Layout

    override func initializeSubviews() {
        super.initializeSubviews()

        // A flexible height autoresizing mask allows our superview to resize in response to
        // changes to our internal content's height.
        self.translatesAutoresizingMaskIntoConstraints = false
        self.autoresizingMask = .flexibleHeight

        self.inputContainerView.showShadow(withOffset: 8)
        self.inputContainerView.setBubbleColor(ThemeColor.B1.color, animated: false)
                
        self.avatarView.set(person: User.current()!)
        
        self.addSubview(self.typingIndicatorView)
        self.addSubview(self.unreadMessagesView)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.expressionView.configure(for: nil)
        self.doneButton.set(style: .custom(color: .white, textColor: .B0, text: "Done"))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.unreadMessagesView.pin(.right, offset: .custom(26))
        self.unreadMessagesView.bottom = 0
        
        self.typingIndicatorView.width = self.width - 48
        self.typingIndicatorView.height = 16
        self.typingIndicatorView.bottom = 0
        self.typingIndicatorView.centerOnX()
    }

    // MARK: - State Updates

    func updateLayout(for inputState: InputState) {
        let newInputHeight: CGFloat
        var textViewPadding: CGFloat = Theme.ContentOffset.short.value
        var newAddViewSize: CGFloat = 0
        var avatarTop: CGFloat = Theme.ContentOffset.long.value
        switch inputState {
        case .collapsed:
            NSLayoutConstraint.deactivate([self.textViewExpandedTopPinConstraint,
                                           self.textViewExpandedBottomPinConstraint])
            NSLayoutConstraint.activate([self.textViewCollapsedVerticalCenterConstraint,
                                         self.textViewCollapsedVerticalHeightContstraint])
            
            if !self.textView.text.isEmpty || self.textView.isFirstResponder {
                textViewPadding = self.addView.left + AddMediaView.collapsedHeight
            }

            self.textView.textContainer.lineBreakMode = .byTruncatingTail
            self.textView.isScrollEnabled = false
            self.textView.textAlignment = .left

            self.gestureButton.isVisible = true
            self.doneButton.isVisible = false

            var proposedHeight = SwipeableInputAccessoryView.inputContainerCollapsedHeight
            if self.textView.numberOfLines > 2, let lineHeight = self.textView.font?.lineHeight {
                let multiplier: CGFloat = clamp(CGFloat(self.textView.numberOfLines) - 2, 0, 2)
                proposedHeight += lineHeight * multiplier
                if proposedHeight > self.inputContainerHeightConstraint.constant - MessageContentView.textViewPadding {
                    proposedHeight = (lineHeight * CGFloat(self.textView.numberOfLines)) + MessageContentView.textViewPadding
                }
            }
            
            newAddViewSize = AddMediaView.collapsedHeight
            newInputHeight = proposedHeight
        case .expanded:
            if !self.textView.isFirstResponder {
                self.textView.becomeFirstResponder()
            }
            
            NSLayoutConstraint.deactivate([self.textViewCollapsedVerticalCenterConstraint,
                                           self.textViewCollapsedVerticalHeightContstraint])
            NSLayoutConstraint.activate([self.textViewExpandedTopPinConstraint,
                                         self.textViewExpandedBottomPinConstraint])

            self.textView.textContainer.lineBreakMode = .byWordWrapping
            self.textView.isScrollEnabled = true
            self.textView.textAlignment = .left

            // Disable swipe gestures when expanded
            self.gestureButton.isVisible = false
            self.doneButton.isVisible = true

            newAddViewSize = self.addView.hasMedia ? AddMediaView.expandedHeight : AddMediaView.collapsedHeight
            newInputHeight = self.window!.height - KeyboardManager.shared.cachedKeyboardEndFrame.height
            
            avatarTop = 34
        }
        
        self.unreadMessagesView.updateVisibility(for: inputState)

        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.addViewWidthContstrain.constant = newAddViewSize
            self.addViewHeightContstrain.constant = newAddViewSize
            self.inputContainerHeightConstraint.constant = newInputHeight
            self.textViewLeadingConstraint.constant = textViewPadding
            self.textViewTrailingConstraint.constant = textViewPadding
            self.avatarTopConstraint.constant = avatarTop
            // Layout the window so that our container view also animates
            self.window?.layoutNow()
        }
    }

    func setShowMessageDetailOptions(shouldShowDetail: Bool, showAvatar: Bool) {
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.expressionView.alpha = shouldShowDetail ? 1.0 : 0.0
            self.avatarView.alpha = showAvatar ? 1.0 : 0.0
            self.avatarHeightConstraint.constant = showAvatar ? 44 : 0
                                    
            if shouldShowDetail {
                self.characterCountView.update(with: self.textView.text.count, max: self.textView.maxLength)
            } else {
                self.characterCountView.alpha = 0.0
            }
            
            // Layout the window so that our container view also animates
            self.window?.layoutNow()
        }
    }
    
    func updateInputType(with type: InputType) {
        self.textView.updateInputView(type: type)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if self.unreadMessagesView.frame.contains(point) || self.typingIndicatorView.frame.contains(point) {
            return true
        }
        return super.point(inside: point, with: event)
    }
}
