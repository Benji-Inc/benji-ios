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

class SwipeableInputAccessoryView: BaseView, UIGestureRecognizerDelegate, ActiveConversationable {

    weak var delegate: SwipeableInputAccessoryViewDelegate?

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
    private let deliveryTypeView = DeliveryTypeView()
    private let emotionView = old_EmotionView()

    private var cancellables = Set<AnyCancellable>()

    // MARK: BaseView Setup and Layout

    // Override intrinsic content size so that height is adjusted for safe areas and text input.
    // https://stackoverflow.com/questions/46282987/iphone-x-how-to-handle-view-controller-inputaccessoryview
    override var intrinsicContentSize: CGSize {
        return .zero
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        #warning("Remove")
//        self.textView.backgroundColor = .red

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

    // MARK: PRIVATE

    private func setupHandlers() {
        self.updateInputType(with: .keyboard)
        
        KeyboardManager.shared
            .$currentEvent
            .mainSink { [unowned self] currentEvent in
                switch currentEvent {
                case .willShow:
                    self.showDetail(shouldShow: true)
                    self.updateSwipeHint(shouldPlay: false)
                case .willHide:
                    self.showDetail(shouldShow: false)
                    self.updateSwipeHint(shouldPlay: false)
                case .didHide:
                    self.textView.updateInputView(type: .keyboard, becomeFirstResponder: false)
                default:
                    break
                }
            }.store(in: &self.cancellables)
        
        self.textView.$inputText.mainSink { [unowned self] text in
            self.handleTextChange(text)
            self.updateHeight(with: self.textView.numberOfLines)
            self.countView.update(with: text.count, max: self.textView.maxLength)
        }.store(in: &self.cancellables)
        
        self.gestureButton.didSelect { [unowned self] in
            // No need to become first responder if we already are.
            guard !self.textView.isFirstResponder else { return }
            self.textView.updateInputView(type: .keyboard, becomeFirstResponder: true)
        }
    }
    
    private func updateHeight(with numberOfLines: Int) {
        var newHeight: CGFloat = SwipeableInputAccessoryView.minHeight

        if numberOfLines > 2 || self.inputHeightConstraint.constant == 400 {
            #warning("Make this dynamic")
            newHeight = 400
            self.textView.textAlignment = .left
            self.gestureButton.isVisible = false
        } else {
            self.textView.textAlignment = .center
            self.gestureButton.isVisible = true
        }

        // There's no need to animate the height if it hasn't changed.
        guard newHeight != self.inputHeightConstraint.constant else { return }

        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.inputHeightConstraint.constant = newHeight
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

    // MARK: OVERRIDES

    func setupGestures() {
        let panRecognizer = SwipeGestureRecognizer(textView: self.textView) { [unowned self] (recognizer) in
            self.panGestureHandler.handle(pan: recognizer)
        }
        
        panRecognizer.touchesDidBegin = { [unowned self] in
            // Stop playing animations when the user interacts with the view.
            self.updateSwipeHint(shouldPlay: false)
        }
        
        panRecognizer.delegate = self
        self.gestureButton.addGestureRecognizer(panRecognizer)
    }

    func handleTextChange(_ text: String) {
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
        self.updateSwipeHint(shouldPlay: !text.isEmpty)

        self.delegate?.swipeableInputAccessory(self, swipeIsEnabled: !text.isEmpty)
    }

    var swipeHintTask: Task<Void, Never>?
    func updateSwipeHint(shouldPlay: Bool) {
        // Cancel any currently running swipe hint tasks so we don't trigger the animation multiple times.
        self.swipeHintTask?.cancel()

        self.inputContainerView.transform = .identity
        self.emotionView.alpha = 1.0
        self.deliveryTypeView.alpha = 1.0
        
        guard shouldPlay else { return }

        self.swipeHintTask = Task {
            // Wait a bit before playing the hint
            await Task.snooze(seconds: 3)

            guard !Task.isCancelled else { return }

            await UIView.awaitAnimation(with: .standard, animations: {
                self.emotionView.alpha = 0
                self.deliveryTypeView.alpha = 0
            })

            guard !Task.isCancelled else { return }

            await UIView.awaitSpringAnimation(with: .slow,
                                              damping: 0.2,
                                              options: [.curveEaseInOut, .allowUserInteraction]) {
                self.inputContainerView.transform = CGAffineTransform(translationX: 0.0, y: -4.0)
            }

            guard !Task.isCancelled else { return }

            await UIView.awaitSpringAnimation(with: .slow, options: [.curveEaseInOut, .allowUserInteraction]) {
                self.inputContainerView.transform = .identity
            }

            guard !Task.isCancelled else { return }

            await UIView.awaitSpringAnimation(with: .slow,
                                              damping: 0.2,
                                              options: [.curveEaseInOut, .allowUserInteraction]) {
                self.inputContainerView.transform = CGAffineTransform(translationX: 0.0, y: -4.0)
            }

            guard !Task.isCancelled else { return }

            await UIView.awaitSpringAnimation(with: .slow, options: [.curveEaseInOut, .allowUserInteraction]) {
                self.inputContainerView.transform = .identity
            }

            guard !Task.isCancelled else { return }

            await UIView.awaitAnimation(with: .standard, animations: {
                self.emotionView.alpha = 1.0
                self.deliveryTypeView.alpha = 1.0
            })
        }
    }

    func updateInputType(with type: InputType) {
        self.textView.updateInputView(type: type)
    }

    func resetInputViews() {
        self.currentContext = .respectful
        self.textView.reset()
        self.inputContainerView.alpha = 1
        self.countView.alpha = 0.0
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        #warning("Use an identity check instead of a type check")
        // The pan gesture should cancel other gestures.
        if gestureRecognizer is UIPanGestureRecognizer {
            return false
        }

        return true
    }
}
