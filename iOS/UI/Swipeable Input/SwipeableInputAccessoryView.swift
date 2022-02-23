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

protocol SwipeableInputAccessoryViewDelegate: AnyObject {

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView, swipeIsEnabled isEnabled: Bool)
    /// The accessory has begun a swipe interaction.
    func swipeableInputAccessoryDidBeginSwipe(_ view: SwipeableInputAccessoryView)
    /// The accessory view updated the position of the sendable's preview view's position.
    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didUpdatePreviewFrame frame: CGRect,
                                 for sendable: Sendable)
    /// The accessory view wants to send the sendable with the preview with the specified frame.
    /// The delegate should return true if the sendable was sent.
    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 triggeredSendFor sendable: Sendable,
                                 withPreviewFrame frame: CGRect) -> Bool
    /// The accessory view finished its swipe interaction.
    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didFinishSwipeSendingSendable didSend: Bool)
    
    /// The avatar view in the accessory was tapped.
    func swipeableInputAccessoryDidTapAvatar(_ view: SwipeableInputAccessoryView)
}

class SwipeableInputAccessoryView: BaseView {

    weak var delegate: SwipeableInputAccessoryViewDelegate?

    enum InputState {
        /// The input field is fit to the current input. Swipe to send is enabled.
        case collapsed
        /// The input field is expanded and can be tapped to edit/copy/paste. Swipe to send is disabled.
        case expanded
    }

    // MARK: - Drag and Drop Properties

    /// The rough area that we need to drag and drop messages to send them.
    var dropZoneFrame: CGRect = .zero

    // MARK:  - Views

    /// A view that contains and provides a background for the input view.
    @IBOutlet var inputContainerView: SpeechBubbleView!
    /// Height constraint for the input container view.
    @IBOutlet var inputHeightConstraint: NSLayoutConstraint!
    /// Text view for users to input their message.
    @IBOutlet var textView: InputTextView!
    /// An invisible button to handle taps and pan gestures.
    @IBOutlet var gestureButton: UIButton!
    @IBOutlet var countView: CharacterCountView!
    @IBOutlet var avatarView: BorderedAvatarView!

    @IBOutlet var inputTypeContainer: UIView!
    @IBOutlet var inputTypeHeightConstraint: NSLayoutConstraint!

    private lazy var panGestureHandler = SwipeInputPanGestureHandler(inputView: self)

    static var minHeight: CGFloat = 76
    static var inputTypeMaxHeight: CGFloat = 25
    static var inputTypeAvatarHeight: CGFloat = 56

    /// The current input state of the accessory view.
    @Published private var inputState: InputState = .collapsed

    // MARK: - Message State

    var currentContext: MessageContext = .respectful {
        didSet {
            self.deliveryTypeView.configure(for: self.currentContext)
        }
    }
    
    var currentEmotion: Emotion? 

    var editableMessage: Messageable?
    var currentMessageKind: MessageKind = .text(String())
    var sendable: SendableObject?
    let deliveryTypeView = DeliveryTypeView()
    let emotionView = old_EmotionView()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Layout/Animation Properties

    @IBOutlet var textViewCollapsedVerticalCenterConstraint: NSLayoutConstraint!
    @IBOutlet var textViewCollapsedMaxHeightConstraint: NSLayoutConstraint!
    @IBOutlet var textViewExpandedTopPinConstraint: NSLayoutConstraint!
    @IBOutlet var textViewExpandedBottomPinConstraint: NSLayoutConstraint!

    private lazy var hintAnimator = SwipeInputHintAnimator(swipeInputView: self)

    // MARK: BaseView Setup and Layout

    // Override intrinsic content size so that height is adjusted for safe areas and text input.
    // https://stackoverflow.com/questions/46282987/iphone-x-how-to-handle-view-controller-inputaccessoryview
    override var intrinsicContentSize: CGSize {
        return .zero
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        // Use flexible height autoresizing mask to account for changes in text input.
        self.autoresizingMask = .flexibleHeight

        self.inputContainerView.showShadow(withOffset: 8)
        self.inputContainerView.setBubbleColor(ThemeColor.B1.color, animated: false)

        self.inputTypeContainer.addSubview(self.emotionView)
        self.emotionView.alpha = 0
        self.emotionView.configure(for: self.currentEmotion)
        self.emotionView.didSelectEmotion = { [unowned self] emotion in
            self.currentEmotion = emotion
        }
        
        self.inputTypeContainer.addSubview(self.deliveryTypeView)
        self.deliveryTypeView.alpha = 0
        self.deliveryTypeView.configure(for: self.currentContext)
        self.deliveryTypeView.didSelectContext = { [unowned self] context in
            self.currentContext = context
        }
                
        self.avatarView.set(avatar: User.current()!)
        
        self.avatarView.didSelect { [unowned self] in
            self.delegate?.swipeableInputAccessoryDidTapAvatar(self)
        }

        self.setupGestures()
        self.setupHandlers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.emotionView.pin(.left)
        self.deliveryTypeView.pin(.right)
    }

        private lazy var panRecognizer
    = SwipeGestureRecognizer(textView: self.textView) { [unowned self] (recognizer) in
        self.panGestureHandler.handle(pan: recognizer)
    }
    private lazy var tapRecognizer = TapGestureRecognizer(taps: 1) { [unowned self] recognizer in
        self.handleTap()
    }

    func setupGestures() {
        self.panRecognizer.touchesDidBegin = { [unowned self] in
            // Stop playing animations when the user interacts with the view.
            self.hintAnimator.updateSwipeHint(shouldPlay: false)
        }
        self.gestureButton.addGestureRecognizer(self.panRecognizer)

        self.gestureButton.addGestureRecognizer(self.tapRecognizer)
    }

    private func handleTap() {
        if self.textView.isFirstResponder {
            guard !self.textView.text.isEmpty else { return }
            self.inputState = .expanded
        } else {
            self.textView.updateInputView(type: .keyboard, becomeFirstResponder: true)
        }
    }

    private func setupHandlers() {
        self.updateInputType(with: .keyboard)
        
        KeyboardManager.shared
            .$currentEvent
            .mainSink { [unowned self] currentEvent in
                switch currentEvent {
                case .willShow:
                    self.showDetail(shouldShow: true)
                    self.hintAnimator.updateSwipeHint(shouldPlay: false)
                case .willHide:
                    self.showDetail(shouldShow: false)
                    self.hintAnimator.updateSwipeHint(shouldPlay: false)
                case .didHide:
                    self.textView.updateInputView(type: .keyboard, becomeFirstResponder: false)
                    self.inputState = .collapsed
                default:
                    break
                }
            }.store(in: &self.cancellables)
        
        self.textView.$inputText.mainSink { [unowned self] text in
            self.handleTextChange(text)
            self.updateInputState(with: self.textView.numberOfLines)
            self.countView.update(with: text.count, max: self.textView.maxLength)
        }.store(in: &self.cancellables)

        self.textView.$isEditing.mainSink { [unowned self] isEditing in
            // If we're not editing, it takes 1 tap to start.
            // If we are editing, a double tap should trigger the expanded state.
            self.tapRecognizer.numberOfTapsRequired = isEditing ? 2 : 1
        }.store(in: &self.cancellables)

        self.$inputState
            .removeDuplicates()
            .mainSink { [unowned self] inputState in
                self.updateLayout(for: inputState)
            }.store(in: &self.cancellables)
    }

    // MARK: - State Updates

    private func updateInputState(with numberOfLines: Int) {
        // When the text hits 3 lines, transition to the expanded state.
        // However don't automatically go back to the collapsed state when the line count is less than 3.
        guard numberOfLines > 2 else { return }
        self.inputState = .expanded
    }

    private func updateLayout(for inputState: InputState) {
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

            newInputHeight = SwipeableInputAccessoryView.minHeight
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

            newInputHeight = self.window!.height - KeyboardManager.shared.cachedKeyboardEndFrame.height
        }

        // There's no need to animate the height if it hasn't changed.
        guard newInputHeight != self.inputHeightConstraint.constant else { return }

        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.inputHeightConstraint.constant = newInputHeight
            self.layoutNow()
        }
    }

    private func showDetail(shouldShow: Bool) {
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.inputTypeHeightConstraint.constant
            = shouldShow ? SwipeableInputAccessoryView.inputTypeMaxHeight : SwipeableInputAccessoryView.inputTypeAvatarHeight
            
            self.emotionView.alpha = shouldShow ? 1.0 : 0.0
            self.deliveryTypeView.alpha = shouldShow ? 1.0 : 0.0
            self.avatarView.alpha = shouldShow ? 0.0 : 1.0
            
            if shouldShow {
                self.countView.update(with: self.textView.text.count, max: self.textView.maxLength)
            } else {
                self.countView.alpha = 0.0
            }
        }
    }

    func updateSwipeHint(shouldPlay: Bool) {
        self.hintAnimator.updateSwipeHint(shouldPlay: shouldPlay)
    }

    private func handleTextChange(_ text: String) {
        switch self.currentMessageKind {
        case .text(_):
            self.currentMessageKind = .text(text)
        case .photo(photo: let photo, _):
            self.currentMessageKind = .photo(photo: photo, body: text)
        case .video(video: let video, _):
            self.currentMessageKind = .video(video: video, body: text)
        default:
            break
        }

        // After the user enters text, the swipe hint can play to show them how to send it.
        let shouldPlay = !text.isEmpty && self.inputState == .collapsed
        self.hintAnimator.updateSwipeHint(shouldPlay: shouldPlay)

        self.delegate?.swipeableInputAccessory(self, swipeIsEnabled: !text.isEmpty)
    }

    func updateInputType(with type: InputType) {
        self.textView.updateInputView(type: type)
    }

    func resetInputViews() {
        self.inputState = .collapsed
        self.currentContext = .respectful
        self.textView.reset()
        self.inputContainerView.alpha = 1
        self.countView.alpha = 0.0
    }
}
