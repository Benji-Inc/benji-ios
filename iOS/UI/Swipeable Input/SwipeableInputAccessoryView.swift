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

class SwipeableInputAccessoryView: View, UIGestureRecognizerDelegate {

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

    @IBOutlet var activityBar: InputActivityBar!
    @IBOutlet var inputContainerView: SpeechBubbleView!
    /// Text view for users to input their message.
    @IBOutlet var textView: InputTextView!
    /// A button to handle taps and pan gestures.
    @IBOutlet var overlayButton: UIButton!
    /// A blur view placed behind the text input field.
    @IBOutlet var blurView: UIVisualEffectView!

    let animationView = AnimationView.with(animation: .loading)

    var cancellables = Set<AnyCancellable>()

    var currentContext: MessageContext = .passive
    
    var editableMessage: Messageable?
    var currentMessageKind: MessageKind = .text(String())
    private var sendable: SendableObject?

    weak var delegate: SwipeableInputAccessoryViewDelegate?

    // MARK: View Setup and Layout

    // Override intrinsic content size so that height is adjusted for safe areas and text input.
    // https://stackoverflow.com/questions/46282987/iphone-x-how-to-handle-view-controller-inputaccessoryview
    override var intrinsicContentSize: CGSize {
        return .zero
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        // Use flexible height autoresizing mask to account for changes in text input.
        self.autoresizingMask = .flexibleHeight

        self.inputContainerView.borderColor = .lightGray

        self.blurView.roundCorners()

        self.insertSubview(self.animationView, belowSubview: self.inputContainerView)
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.loopMode = .loop

        self.setupGestures()
        self.setupHandlers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

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
                case .didHide:
                    self.textView.updateInputView(type: .keyboard, becomeFirstResponder: false)
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

        self.delegate?.swipeableInputAccessoryDidBeginSwipe(self)
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
                self.delegate?.swipeableInputAccessory(self,
                                                      didPrepare: sendable,
                                                      at: newSendPosition)
            } else {
                self.delegate?.swipeableInputAccessoryDidUnprepareSendable(self)
            }
        }
    }

    private func handlePanEnded(withOffset panOffset: CGPoint) {
        // Only attempt to send a message if we have a valid swipe position.
        if let swipePosition = self.getSendPosition(forPanOffset: panOffset),
           let sendable = self.sendable {

            self.selectionFeedback.impactOccurred()
            self.delegate?.swipeableInputAccessory(self, didConfirm: sendable, at: swipePosition)

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
        self.delegate?.swipeableInputAccessoryDidFinishSwipe(self)
    }

    private func handlePanFailed() {
        self.textView.alpha = 1
        self.previewView?.removeFromSuperview()
        self.delegate?.swipeableInputAccessoryDidFinishSwipe(self)
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
