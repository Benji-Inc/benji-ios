//
//  SwipeableInputAccessoryView.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/13/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie
import TMROLocalization
import Combine

protocol SwipeableInputAccessoryViewDelegate: AnyObject {
    /// The accessory has begun a swipe interaction.
    func swipeableInputAccessoryDidBeginSwipe(_ view: SwipeableInputAccessoryView)
    /// The accessory is ready to confirm a sendable, but has not yet done so.
    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didPrepare sendable: Sendable,
                                 at position: SwipeableInputAccessoryView.SendPosition)
    /// The accessory has moved from being prepared to confirm a sendable, to not being prepared.
    func swipeableInputAccessoryDidUnprepareSendable(_ view: SwipeableInputAccessoryView)
    /// The accesory  has is intending to send a sendable. The swipe is at the specified position.
    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didConfirm sendable: Sendable,
                                 at position: SwipeableInputAccessoryView.SendPosition)
    /// The accessory finished a swipe interaction. This occurs regardless of whether a message was sent.
    func swipeableInputAccessoryDidFinishSwipe(_ view: SwipeableInputAccessoryView)
}

class SwipeableInputAccessoryView: View, AttachmentViewControllerDelegate, UIGestureRecognizerDelegate {

    // TODO: Restore
    func attachmentView(_ controller: AttachmentViewController, didSelect attachment: Attachment) {

    }

    /// The location on the screen that a send action was triggered.
    enum SendPosition {
        case left
        case middle
        case right
    }

    /// The maximum height we should allow this view to expand to.
    static let maxHeight: CGFloat = 500.0
    static let bottomPadding: CGFloat = 8

    var alertAnimator: UIViewPropertyAnimator?
    var selectionFeedback = UIImpactFeedbackGenerator(style: .rigid)

    let activityBar = InputActivityBar()
    let inputContainerView = SpeechBubbleView(orientation: .down,
                                              bubbleColor: nil,
                                              borderColor: Color.white.color)
    /// A blue view placed behind the text input field.
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
    /// Text view for users to input their message.
    lazy var textView = InputTextView(with: self)
    let animationView = AnimationView.with(animation: .loading)
    let overlayButton = UIButton()
    var cancellables = Set<AnyCancellable>()

    var currentContext: MessageContext = .passive
    
    var editableMessage: Messageable?
    var currentMessageKind: MessageKind = .text(String())
    private var sendable: SendableObject?

    unowned let delegate: SwipeableInputAccessoryViewDelegate

    init(with delegate: SwipeableInputAccessoryViewDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Setup and Layout

    override func initializeSubviews() {
        super.initializeSubviews()

        self.backgroundColor = .red

        self.addSubview(self.activityBar)
        self.addSubview(self.inputContainerView)

        self.inputContainerView.contentView.addSubview(self.blurView)

        self.textView.backgroundColor = .purple
        self.inputContainerView.contentView.addSubview(self.textView)

        self.inputContainerView.contentView.addSubview(self.animationView)
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.loopMode = .loop

        self.inputContainerView.contentView.addSubview(self.overlayButton)

        self.setupGestures()
        self.setupHandlers()
    }

    private var heightConstraint: NSLayoutConstraint?

    override func didMoveToWindow() {
        super.didMoveToWindow()

        // Get a reference to the height constraint so we can expand this view for text input
        self.heightConstraint = self.constraints.first(where: { constraint in
            return constraint.firstAttribute == .height
        })
        self.heightConstraint?.constant = self.getContentHeight()
    }

    private func getContentHeight() -> CGFloat {
        // Calculate intrinsicContentSize that will fit all the text
        var textViewHeight = self.textView.sizeThatFits(CGSize(width: self.width - Theme.contentOffset.doubled,
                                                               height: .greatestFiniteMagnitude)).height
        if textViewHeight == 0 {
            textViewHeight = 33
        }

        let contentHeight = textViewHeight + InputActivityBar.height + self.inputContainerView.tailLength
        + SwipeableInputAccessoryView.bottomPadding

        return contentHeight
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        logDebug("current height is \(self.frame.height)")

        let horizontalOffset: CGFloat = Theme.contentOffset

        self.activityBar.pin(.left, padding: horizontalOffset)
        self.activityBar.pin(.top)
        self.activityBar.expand(.right, padding: horizontalOffset)
        self.activityBar.height = InputActivityBar.height

        self.inputContainerView.pin(.left, padding: horizontalOffset)
        self.inputContainerView.match(.top, to: .bottom, of: self.activityBar)
        self.inputContainerView.expand(.right, padding: horizontalOffset)
        self.inputContainerView.expand(.bottom, padding: SwipeableInputAccessoryView.bottomPadding)

        // TODO: Find a more elegant solution than manually calling layout now.
        self.inputContainerView.layoutNow()

        self.textView.expandToSuperviewSize()

        self.blurView.expandToSuperviewSize()
        self.blurView.roundCorners()

        self.overlayButton.expandToSuperviewSize()

        self.animationView.size = CGSize(width: 18, height: 18)
        self.animationView.match(.right,
                                 to: .right,
                                 of: self.inputContainerView,
                                 offset: Theme.contentOffset)
        self.animationView.centerOnY()
    }

    // MARK: PRIVATE

    private func setupHandlers() {
        KeyboardManager.shared.$currentEvent
            .mainSink { event in
                switch event {
                case .didHide(_):
                    self.textView.updateInputView(type: .keyboard, becomeFirstResponder: false)
                case .didShow(_):
                    break
                default:
                    break
                }
            }.store(in: &self.cancellables)

        self.textView.demoVC.exitButton.didSelect { [unowned self] in
            UserDefaultsManager.update(key: .hasShownKeyboardInstructions, with: true)
            self.textView.updateInputView(type: .keyboard)
        }

        self.textView.$inputText.mainSink { text in
            self.handleTextChange(text)
        }.store(in: &self.cancellables)

        self.overlayButton.didSelect { [unowned self] in
            if !self.textView.isFirstResponder {
                if UserDefaultsManager.getValue(for: .hasShownKeyboardInstructions) {
                    self.textView.updateInputView(type: .keyboard, becomeFirstResponder: true)
                } else {
                    self.textView.updateInputView(type: .demo, becomeFirstResponder: true)

                }
            }
        }

        self.textView.confirmationView.button.didSelect { [unowned self] in
            self.didPressAlertCancel()
        }
    }

    // MARK: OVERRIDES

    func setupGestures() {
        let panRecognizer = UIPanGestureRecognizer { [unowned self] (recognizer) in
            self.handle(pan: recognizer)
        }
        panRecognizer.delegate = self
        self.overlayButton.addGestureRecognizer(panRecognizer)
    }

    func didPressAlertCancel() {}

    func handleTextChange(_ text: String) {
        self.animateInputViews(with: text)

        switch self.currentMessageKind {
        case .text(_):
            if let types = self.getDataTypes(from: text), let first = types.first, let url = first.url {
                self.currentMessageKind = .link(url)
            } else {
                self.currentMessageKind = .text(text)
            }
        case .photo(photo: let photo, _):
            self.currentMessageKind = .photo(photo: photo, body: text)
        case .video(video: let video, _):
            self.currentMessageKind = .video(video: video, body: text)
        default:
            break
        }

        // Update the height of the view to account for the new text.
        self.heightConstraint?.constant = self.getContentHeight()
    }

    func getDataTypes(from text: String) -> [NSTextCheckingResult]? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingAllTypes) else { return nil }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)

        var results: [NSTextCheckingResult] = []

        detector.enumerateMatches(in: text,
                                  options: [],
                                  range: range) { (match, flags, _) in
            guard let match = match else {
                return
            }

            results.append(match)
        }

        return results
    }

    func updateInputType() {}

    func animateInputViews(with text: String) {}

    func resetInputViews() {
        self.textView.reset()
        self.textView.alpha = 1
        self.textView.countView.isHidden = true
    }

    // MARK: - Pan Gesture Handling

    private var previewView: PreviewMessageView?
    private var initialPreviewOrigin: CGPoint?
    private var currentSendPosition: SendPosition?
    /// How far the preview view can be dragged left or right.
    private let maxXOffset: CGFloat = 40
    /// How far the preview view can be dragged vertically
    private let maxYOffset: CGFloat = SwipeableInputAccessoryView.maxHeight.half

    func handle(pan: UIPanGestureRecognizer) {
        guard self.shouldHandlePan() else { return }

        let panOffset = pan.translation(in: nil)

        switch pan.state {
        case .possible:
            break
        case .began:
            self.handlePanBegan()
        case .changed:
            self.handlePanChanged(withOffset: panOffset)
        case .ended:
            self.handlePanEnded(withOffset: panOffset)
        case .cancelled, .failed:
            self.handlePanFailed()
        @unknown default:
            break
        }
    }

    func shouldHandlePan() -> Bool {
        let object = SendableObject(kind: self.currentMessageKind,
                                    context: self.currentContext,
                                    previousMessage: self.editableMessage)

        return object.isSendable
    }

    private func handlePanBegan() {
        let object = SendableObject(kind: self.currentMessageKind,
                                    context: self.currentContext,
                                    previousMessage: self.editableMessage)
        self.sendable = object

        self.textView.alpha = 0

        // Initialize the preview view for the user to drag up the screen.
        self.previewView = PreviewMessageView(orientation: .down,
                                              bubbleColor: self.currentContext.color.color)
        self.previewView?.frame = self.inputContainerView.frame
        self.previewView?.messageKind = self.currentMessageKind
        self.addSubview(self.previewView!)

        self.initialPreviewOrigin = self.previewView?.origin
        self.currentSendPosition = nil

        self.delegate.swipeableInputAccessoryDidBeginSwipe(self)
    }

    private func handlePanChanged(withOffset panOffset: CGPoint) {
        guard let initialPosition = self.initialPreviewOrigin else { return }

        let offsetX = clamp(panOffset.x, -self.maxXOffset, self.maxXOffset)
        let offsetY = clamp(panOffset.y, -self.maxYOffset, 0)
        self.previewView?.origin = initialPosition + CGPoint(x: offsetX, y: offsetY)

        guard let sendable = self.sendable else { return }

        let newSendPosition = self.getSendPosition(forPanOffset: panOffset)

        // Detect if the send position has changed. If so, let the delegate know so it can prepare
        // for a send or cancel the current send.
        if newSendPosition != self.currentSendPosition {
            self.currentSendPosition = newSendPosition

            if let newSendPosition = newSendPosition {
                self.delegate.swipeableInputAccessory(self,
                                                      didPrepare: sendable,
                                                      at: newSendPosition)
            } else {
                self.delegate.swipeableInputAccessoryDidUnprepareSendable(self)
            }
        }
    }

    private func handlePanEnded(withOffset panOffset: CGPoint) {
        // Only attempt to send a message if we have a valid swipe position.
        if let swipePosition = self.getSendPosition(forPanOffset: panOffset),
           let sendable = self.sendable {

            self.selectionFeedback.impactOccurred()
            self.delegate.swipeableInputAccessory(self, didConfirm: sendable, at: swipePosition)

            self.previewView?.removeFromSuperview()
            self.resetInputViews()
        } else {
            // If the user didn't swipe far enough to send a message, animate the preview view back
            // to where it started, then reveal the text view to allow for input again.
            UIView.animate(withDuration: Theme.animationDuration) {
                guard let initialOrigin = self.initialPreviewOrigin else { return }
                self.previewView?.origin = initialOrigin
                self.previewView?.bubbleColor = .clear
            } completion: { completed in
                self.textView.alpha = 1
                self.previewView?.removeFromSuperview()
            }
        }
        self.delegate.swipeableInputAccessoryDidFinishSwipe(self)
    }

    private func handlePanFailed() {
        self.textView.alpha = 1
        self.previewView?.removeFromSuperview()
        self.delegate.swipeableInputAccessoryDidFinishSwipe(self)
    }

    /// Gets the send position for the given panOffset. If the pan offset doesn't correspond to a valid send position, nil is returned.
    private func getSendPosition(forPanOffset panOffset: CGPoint) -> SendPosition? {
        // The percentage of the max y offset that the preview view has been dragged up.
        let progress = clamp(-panOffset.y/self.maxYOffset, 0, 1)

        // Make sure the user has dragged up far enough, otherwise this isn't a valid send position.
        guard progress > 0.5 else { return nil }

        switch panOffset.x {
        case -CGFloat.greatestFiniteMagnitude ... -self.maxXOffset.half:
            return .left
        case self.maxXOffset.half ... CGFloat.greatestFiniteMagnitude:
            return .right
        default:
            return .middle
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UILongPressGestureRecognizer {
            return self.textView.isFirstResponder
        }

        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        if gestureRecognizer is UIPanGestureRecognizer {
            return false
        }

        return true
    }
}
