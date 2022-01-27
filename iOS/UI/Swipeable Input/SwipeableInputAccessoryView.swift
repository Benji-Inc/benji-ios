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

    /// An object to give the user touch feedback when performing certain actions.
    var impactFeedback = UIImpactFeedbackGenerator(style: .rigid)

    // MARK:  - Views

    @IBOutlet var inputContainerView: SpeechBubbleView!
    @IBOutlet var inputHeightConstraint: NSLayoutConstraint!
    /// Text view for users to input their message.
    @IBOutlet var textView: InputTextView!
    /// A button to handle taps and pan gestures.
    @IBOutlet var overlayButton: UIButton!
    @IBOutlet var countView: CharacterCountView!
    @IBOutlet var avatarView: BorderedAvatarView!

    @IBOutlet var inputTypeContainer: UIView!
    @IBOutlet var inputTypeHeightConstraint: NSLayoutConstraint!

    private var swipeHintView = AnimationView.with(animation: .arrowUpBlack)

    static var minHeight: CGFloat = 76
    static var inputTypeMaxHeight: CGFloat = 25
    static var inputTypeAvatarHeight: CGFloat = 56

    // MARK: - Message State

    var currentContext: MessageContext = .passive {
        didSet {
            self.deliveryTypeView.configure(for: self.currentContext)
        }
    }
    
    var currentEmotion: Emotion = .calm

    var editableMessage: Messageable?
    var currentMessageKind: MessageKind = .text(String())
    private var sendable: SendableObject?
    private let deliveryTypeView = DeliveryTypeView()
    private let emotionView = EmotionView()

    var cancellables = Set<AnyCancellable>()

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
        
        self.inputContainerView.addSubview(self.countView)
        self.countView.isHidden = true
        
        self.avatarView.set(avatar: User.current()!)
        
        self.avatarView.didSelect { [unowned self] in
            self.delegate?.swipeableInputAccessoryDidTapAvatar(self)
        }

        self.swipeHintView.backgroundColor = .red
        self.swipeHintView.loopMode = .loop
        self.swipeHintView.play()
        self.inputContainerView.addSubview(self.swipeHintView)

        self.setupGestures()
        self.setupHandlers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.emotionView.pin(.left)
        self.deliveryTypeView.pin(.right)

        self.swipeHintView.size = CGSize(width: 32, height: 32)
        self.swipeHintView.pin(.right)
        self.swipeHintView.centerOnY()
    }

    // MARK: PRIVATE

    private func setupHandlers() {
        self.updateInputType(with: .keyboard)
        
        KeyboardManager.shared
            .$currentEvent
            .mainSink { [weak self] currentEvent in
                guard let `self` = self else { return }
                
                switch currentEvent {
                case .willShow:
                    let shouldShow = self.textView.numberOfLines == 1
                    self.showDetail(shouldShow: shouldShow)
                case .willHide:
                    self.showDetail(shouldShow: false)
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
        
        self.overlayButton.didSelect { [unowned self] in
            if !self.textView.isFirstResponder {
                self.textView.updateInputView(type: .keyboard, becomeFirstResponder: true)
            }
        }
        
        self.textView.confirmationView.button.didSelect { [unowned self] in
            self.didPressAlertCancel()
        }
    }
    
    func updateHeight(with numberOfLines: Int) {
        var new: CGFloat = SwipeableInputAccessoryView.minHeight
        
        if numberOfLines > 3 {
            new = self.textView.height + self.inputTypeContainer.height
        }
        
        guard new != self.inputHeightConstraint.constant else { return }
                
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.inputHeightConstraint.constant = new
            self.setNeedsLayout()
        }
    }

    func showDetail(shouldShow: Bool) {
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.inputTypeHeightConstraint.constant = shouldShow ? SwipeableInputAccessoryView.inputTypeMaxHeight : SwipeableInputAccessoryView.inputTypeAvatarHeight
            
            self.emotionView.alpha = shouldShow ? 1.0 : 0.0
            self.deliveryTypeView.alpha = shouldShow ? 1.0 : 0.0
            self.avatarView.alpha = shouldShow ? 0.0 : 1.0
        }
    }

    // MARK: OVERRIDES

    func setupGestures() {
        let panRecognizer = PanGestureRecognizer { [unowned self] (recognizer) in
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
        self.currentContext = .passive
        self.textView.reset()
        self.inputContainerView.alpha = 1
        self.countView.isHidden = true
    }

    // MARK: - Pan Gesture Handling

    private var previewView: PreviewMessageView?
    /// The center point of the preview view when the pan started.
    private var initialPreviewCenter: CGPoint?
    /// How far the preview view can be dragged left or right.
    private let maxXOffset: CGFloat = 40
    /// If true, the preview view is currently in the drop zone.
    private var isPreviewInDropZone = false

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
                                    emotion: self.currentEmotion,
                                    previousMessage: self.editableMessage)
        return object.isSendable
    }

    private func handlePanBegan() {
        let object = SendableObject(kind: self.currentMessageKind,
                                    context: self.currentContext,
                                    emotion: self.currentEmotion,
                                    previousMessage: self.editableMessage)
        self.sendable = object

        // Hide the input area. The preview view will take its place during the pan.
        self.inputContainerView.alpha = 0

        // Initialize the preview view for the user to drag up the screen.
        self.previewView = PreviewMessageView(orientation: .down,
                                              bubbleColor: self.currentContext.color.color)
        self.previewView?.frame = self.inputContainerView.frame
        self.previewView?.messageKind = self.currentMessageKind
        self.previewView?.showShadow(withOffset: 8)
        self.addSubview(self.previewView!)

        self.initialPreviewCenter = self.previewView?.center

        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.deliveryTypeView.alpha = 0.0
            self.emotionView.alpha = 0.0
        }
        self.delegate?.swipeableInputAccessoryDidBeginSwipe(self)
    }

    private func handlePanChanged(withOffset panOffset: CGPoint) {
        self.updatePreviewViewPosition(withOffset: panOffset)

        guard let sendable = self.sendable, let previewView = self.previewView else { return }

        self.delegate?.swipeableInputAccessory(self,
                                               didUpdatePreviewFrame: previewView.frame,
                                               for: sendable)
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
        guard let initialCenter = self.initialPreviewCenter,
              let previewView = self.previewView else { return }

        let offsetX = clamp(panOffset.x, -self.maxXOffset, self.maxXOffset)

        var previewCenter = initialCenter + CGPoint(x: offsetX, y: panOffset.y)

        // As the user drags further up, gravitate the preview view toward the drop zone.
        let dropZoneCenter = self.dropZoneFrame.center
        let xGravityRange: CGFloat = 30
        // Range along y axis from the drop zone center within which we start gravitating the preview
        let yGravityRange: CGFloat = self.dropZoneFrame.height

        // Vector pointing from the current preview center to the drop zone center.
        var gravityVector = CGVector(startPoint: previewCenter, endPoint: dropZoneCenter)

        // The closer to the drop zone, the stronger the gravity should be.
        let gravityFactorX = lerpClamped(abs(previewCenter.x - dropZoneCenter.x)/xGravityRange,
                                         keyPoints: [1, 0.95, 0.85, 0.5, 0])
        let gravityFactorY = lerpClamped(abs(previewCenter.y - dropZoneCenter.y)/yGravityRange,
                                        keyPoints: [1, 0.95, 0.85, 0.7, 0])
        gravityVector = CGVector(dx: gravityVector.dx * gravityFactorX,
                                 dy: gravityVector.dy * gravityFactorY)

        // Adjust the preview's center with the gravity vector.
        previewCenter = CGPoint(x: previewCenter.x + gravityVector.dx,
                                y: previewCenter.y + gravityVector.dy)

        previewView.center = previewCenter

        // Provide haptic feedback when the message is ready to send.
        let distanceToDropZone = CGVector(startPoint: previewCenter, endPoint: dropZoneCenter).magnitude
        if distanceToDropZone < self.dropZoneFrame.height * 0.5 {
            if !self.isPreviewInDropZone {
                previewView.setBubbleColor(ThemeColor.D1.color, animated: true)
                self.impactFeedback.impactOccurred()
            }
            self.isPreviewInDropZone = true
        } else {
            if self.isPreviewInDropZone {
                previewView.setBubbleColor(ThemeColor.B1.color, animated: true)
            }
            self.isPreviewInDropZone = false
        }
    }

    private func resetPreviewAndInputViews(didSend: Bool) {
        if didSend {
            self.impactFeedback.impactOccurred()
            UIView.animate(withDuration: Theme.animationDurationStandard) {
                self.previewView?.alpha = 0
            } completion: { completed in
                self.previewView?.removeFromSuperview()
            }

            self.resetInputViews()
        } else {
            // If the user didn't swipe far enough to send a message, animate the preview view back
            // to where it started, then reveal the text view to allow for input again.
            UIView.animate(withDuration: Theme.animationDurationStandard) {
                guard let initialOrigin = self.initialPreviewCenter else { return }
                self.previewView?.center = initialOrigin
            } completion: { completed in
                self.inputContainerView.alpha = 1
                self.previewView?.removeFromSuperview()
            }
        }
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.deliveryTypeView.alpha = 1.0
            self.emotionView.alpha = 1.0
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
