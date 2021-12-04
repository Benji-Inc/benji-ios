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
import UIKit

protocol SwipeableInputAccessoryViewDelegate: AnyObject {
    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView, swipeIsEnabled isEnabled: Bool)

    /// The accessory has begun a swipe interaction.
    func swipeableInputAccessoryDidBeginSwipe(_ view: SwipeableInputAccessoryView)
    /// The accessory view updated the position of the sendable's preview view's position.
    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didUpdate sendable: Sendable,
                                 withPreviewFrame frame: CGRect)
    /// The accessory view wants to send the sendable with the preview with the specified frame.
    /// The delegate should return true if the sendable was sent.
    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 triggeredSendFor sendable: Sendable,
                                 withPreviewFrame frame: CGRect) -> Bool
    /// The accessory view finished its swipe interaction.
    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didFinishSwipeSendingSendable didSend: Bool)
    /// The accessory view's text view has updated its frame.
    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView, updatedFrameOf textView: InputTextView)
}

class SwipeableInputAccessoryView: View, UIGestureRecognizerDelegate, ActiveConversationable {

    weak var delegate: SwipeableInputAccessoryViewDelegate?

    // MARK: - Drag and Drop Properties

    /// The rough area that we need to drag and drop messages to send them.
    var dropZoneFrame: CGRect = .zero

    /// An object to give the user touch feedback when performing certain actions.
    var impactFeedback = UIImpactFeedbackGenerator(style: .rigid)

    // MARK:  - Views

    @IBOutlet var activityBar: InputActivityBar!
    @IBOutlet var inputContainerView: SpeechBubbleView!
    /// Text view for users to input their message.
    @IBOutlet var textView: InputTextView!
    /// A button to handle taps and pan gestures.
    @IBOutlet var overlayButton: UIButton!

    @IBOutlet var inputTypeContainer: UIView!
    @IBOutlet var inputTypeHeightConstraint: NSLayoutConstraint!

    lazy var inputManager = InputTypeManager.init(with: CollectionView(layout: InputTypeCollectionViewLayout()))

    static var inputTypeMaxHeight: CGFloat = 40

    // MARK: - Message State

    var currentContext: MessageContext = .passive

    var editableMessage: Messageable?
    var currentMessageKind: MessageKind = .text(String())
    private var sendable: SendableObject?

    var cancellables = Set<AnyCancellable>()

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

        self.inputContainerView.showShadow(withOffset: 8)

        self.inputTypeContainer.addSubview(self.inputManager.collectionView)

        self.inputManager.collectionView.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = self.inputManager.collectionView.topAnchor.constraint(equalTo: self.inputTypeContainer.topAnchor)
        let bottomConstraint = self.inputManager.collectionView.bottomAnchor.constraint(equalTo: self.inputTypeContainer.bottomAnchor)
        let leadingConstraint = self.inputManager.collectionView.leadingAnchor.constraint(equalTo: self.inputTypeContainer.leadingAnchor)
        let trailingConstraint = self.inputManager.collectionView.trailingAnchor.constraint(equalTo: self.inputTypeContainer.trailingAnchor)
        self.inputTypeContainer.addConstraints([topConstraint, bottomConstraint, leadingConstraint, trailingConstraint])

        self.setupGestures()
        self.setupHandlers()
    }

    // MARK: PRIVATE

    private func setupHandlers() {

        self.inputManager
            .$selectedItems
            .removeDuplicates()
            .mainSink { items in
                guard let first = items.first else { return }
                if let ip = self.inputManager.dataSource.indexPath(for: first) {
                    self.inputManager.collectionView.scrollToItem(at: ip, at: .centeredHorizontally, animated: true)
                }

                self.updateInputType(with: first)
            }.store(in: &self.cancellables)

        KeyboardManager.shared.$willKeyboardShow
            .filter({ willShow in
                if let view = KeyboardManager.shared.inputAccessoryView as? SwipeableInputAccessoryView {
                    return view.textView.restorationIdentifier == self.textView.restorationIdentifier
                }
                return KeyboardManager.shared.inputAccessoryView === self
            })
            .mainSink { willShow in
                let shouldShow = willShow && self.textView.numberOfLines == 2
                self.showInputTypes(shouldShow: shouldShow)

        }.store(in: &self.cancellables)

        KeyboardManager.shared.$currentEvent
            .mainSink { [weak self] event in
                guard let `self` = self else { return }
                switch event {
                case .didHide:
                    self.textView.updateInputView(type: .keyboard, becomeFirstResponder: false)
                default:
                    break
                }
            }.store(in: &self.cancellables)

        self.textView.$inputText.mainSink { [unowned self] text in
            self.handleTextChange(text)
            // numberOfLines has an initial value of 2 for some reason
            let shouldShow = self.textView.numberOfLines == 2 && KeyboardManager.shared.isKeyboardShowing && KeyboardManager.shared.inputAccessoryView === self 
            self.showInputTypes(shouldShow: shouldShow)
        }.store(in: &self.cancellables)

        self.overlayButton.didSelect { [unowned self] in
            if !self.textView.isFirstResponder {
                self.textView.updateInputView(type: .keyboard, becomeFirstResponder: true)
            }
        }

        self.textView.confirmationView.button.didSelect { [unowned self] in
            self.didPressAlertCancel()
        }

        // Listen for changes to the textview bounds and update the delegate as needed.
        self.textView.publisher(for: \.bounds, options: [.new])
            .mainSink { [unowned self] bounds in
                self.delegate?.swipeableInputAccessory(self, updatedFrameOf: self.textView)
            }.store(in: &self.cancellables)
    }

    func showInputTypes(shouldShow: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.inputTypeHeightConstraint.constant = shouldShow ? SwipeableInputAccessoryView.inputTypeMaxHeight : 1
            self.inputManager.collectionView.alpha = shouldShow ? 1 : 0
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

        self.delegate?.swipeableInputAccessory(self, swipeIsEnabled: !text.isEmpty)
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

    func updateInputType(with type: InputType) {
        self.textView.updateInputView(type: type)
    }

    func animateInputViews(with text: String) {}

    func resetInputViews() {
        self.textView.reset()
        self.inputContainerView.alpha = 1
        self.textView.countView.isHidden = true
    }

    // MARK: - Pan Gesture Handling

    private var previewView: PreviewMessageView?
    /// The origin of the preview view when the pan started.
    private var initialPreviewOrigin: CGPoint?
    /// How far the preview view can be dragged left or right.
    private let maxXOffset: CGFloat = 40
    /// How far the preview view can be dragged up.
    private var maxYOffset: CGFloat {
        let additionalSpace = self.textView.height.half
        return -(self.inputContainerView.top - self.dropZoneFrame.top + additionalSpace)
    }

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

    private func shouldHandlePan() -> Bool {
        // Only handle pans if the user has input a sendable message.
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

        // Hide the input area. The preview view will take its place during the pan.
        self.inputContainerView.alpha = 0

        // Initialize the preview view for the user to drag up the screen.
        self.previewView = PreviewMessageView(orientation: .down,
                                              bubbleColor: self.currentContext.color.color,
                                              borderColor: self.currentContext.color.color)
        self.previewView?.frame = self.inputContainerView.frame
        self.previewView?.messageKind = self.currentMessageKind
        self.previewView?.showShadow(withOffset: 8)
        self.addSubview(self.previewView!)

        self.initialPreviewOrigin = self.previewView?.origin

        self.delegate?.swipeableInputAccessoryDidBeginSwipe(self)
    }

    private func handlePanChanged(withOffset panOffset: CGPoint) {
        self.updatePreviewViewPosition(withOffset: panOffset)

        guard let sendable = self.sendable, let previewView = self.previewView else { return }

        self.delegate?.swipeableInputAccessory(self,
                                               didUpdate: sendable,
                                               withPreviewFrame: previewView.frame)
    }

    private func handlePanEnded(withOffset panOffset: CGPoint) {
        self.updatePreviewViewPosition(withOffset: panOffset)

        var sendableWillBeSent = false

        if let sendable = self.sendable,
           let previewView = self.previewView,
           let delegate = self.delegate {

            sendableWillBeSent = delegate.swipeableInputAccessory(self,
                                                                  triggeredSendFor: sendable,
                                                                  withPreviewFrame: previewView.frame)
        }

        self.resetPreviewAndInputViews(didSend: sendableWillBeSent)

        self.delegate?.swipeableInputAccessory(self, didFinishSwipeSendingSendable: sendableWillBeSent)
    }

    private func handlePanFailed() {
        self.inputContainerView.alpha = 1
        self.previewView?.removeFromSuperview()
        self.delegate?.swipeableInputAccessory(self, didFinishSwipeSendingSendable: false)
    }

    /// Updates the position of the preview view based on the provided pan gesture offset. This function ensures that preview view's origin
    /// is kept within bounds defined by max X and Y offset.
    private func updatePreviewViewPosition(withOffset panOffset: CGPoint) {
        guard let initialPosition = self.initialPreviewOrigin,
              let previewView = self.previewView else { return }

        let offsetX = clamp(panOffset.x, -self.maxXOffset, self.maxXOffset)
        let offsetY = clamp(panOffset.y, self.maxYOffset, 0)
        previewView.origin = initialPosition + CGPoint(x: offsetX, y: offsetY)
    }

    private func resetPreviewAndInputViews(didSend: Bool) {
        if didSend {
            self.impactFeedback.impactOccurred()
            self.previewView?.removeFromSuperview()
            self.resetInputViews()
        } else {
            // If the user didn't swipe far enough to send a message, animate the preview view back
            // to where it started, then reveal the text view to allow for input again.
            UIView.animate(withDuration: Theme.animationDurationStandard) {
                guard let initialOrigin = self.initialPreviewOrigin else { return }
                self.previewView?.origin = initialOrigin
            } completion: { completed in
                self.inputContainerView.alpha = 1
                self.previewView?.removeFromSuperview()
            }
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
