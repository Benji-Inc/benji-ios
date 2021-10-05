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
    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView, didConfirm sendable: Sendable)
//    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView, didConfirmReply reply: Sendable)
}

class SwipeableInputAccessoryView: View, AttachmentViewControllerDelegate, UIGestureRecognizerDelegate {

    static let preferredHeight: CGFloat = 54.0
    static let maxHeight: CGFloat = 200.0

    var alertAnimator: UIViewPropertyAnimator?
    var selectionFeedback = UIImpactFeedbackGenerator(style: .rigid)
    var borderColor: CGColor? {
        didSet {
            self.inputContainerView.layer.borderColor = self.borderColor ?? Color.purple.color.cgColor
        }
    }

    let inputContainerView = View()
    let attachmentView = AttachmentView()
    /// A blue view placed behind the text input field.
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
    /// Text view for users to input their message.
    lazy var textView = InputTextView(with: self)
    let animationView = AnimationView.with(animation: .loading)
    let plusAnimationView = AnimationView.with(animation: .plusToX)
    let overlayButton = UIButton()
    var cancellables = Set<AnyCancellable>()

    var currentContext: MessageContext = .passive {
        didSet {
            self.borderColor = self.currentContext.color.color.cgColor
        }
    }
    
    var editableMessage: Messageable?
    var currentMessageKind: MessageKind = .text(String())
    private var sendableObject: SendableObject?

    private(set) var inputLeadingContstaint: NSLayoutConstraint?
    private(set) var attachmentHeightAnchor: NSLayoutConstraint?

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: ConversationInputAccessoryView.preferredHeight)
    }

    override var intrinsicContentSize: CGSize {
        var newSize = self.bounds.size

        if self.textView.bounds.size.height > 0.0 {
            newSize.height = self.textView.bounds.size.height + 20.0
        }

        if let constraint = self.attachmentHeightAnchor, constraint.constant > 0 {
            newSize.height += self.attachmentView.height + 10
        }

        if newSize.height < ConversationInputAccessoryView.preferredHeight || newSize.height > 120.0 {
            newSize.height = ConversationInputAccessoryView.preferredHeight
        }

        if newSize.height > ConversationInputAccessoryView.maxHeight {
            newSize.height = ConversationInputAccessoryView.maxHeight
        }

        return newSize
    }

    unowned let delegate: SwipeableInputAccessoryViewDelegate

    init(with delegate: SwipeableInputAccessoryViewDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .clear)

        self.addSubview(self.plusAnimationView)
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.loopMode = .autoReverse

        self.addSubview(self.inputContainerView)
        self.inputContainerView.set(backgroundColor: .clear)

        self.inputContainerView.addSubview(self.blurView)

        self.inputContainerView.addSubview(self.animationView)
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.loopMode = .loop

        self.inputContainerView.addSubview(self.textView)
        self.inputContainerView.addSubview(self.attachmentView)
        self.inputContainerView.addSubview(self.overlayButton)

        self.inputContainerView.layer.masksToBounds = true
        self.inputContainerView.layer.borderWidth = Theme.borderWidth
        self.inputContainerView.layer.maskedCorners = [.layerMinXMaxYCorner,
                                                       .layerMaxXMinYCorner,
                                                       .layerMinXMinYCorner]
        self.inputContainerView.layer.cornerRadius = Theme.cornerRadius

        self.setupConstraints()
        self.setupGestures()
        self.setupHandlers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.blurView.expandToSuperviewSize()
        self.overlayButton.expandToSuperviewSize()

        self.animationView.size = CGSize(width: 18, height: 18)
        self.animationView.match(.right, to: .right, of: self.inputContainerView, offset: Theme.contentOffset)
        self.animationView.centerOnY()
    }

    // MARK: PRIVATE

    private func setupConstraints() {
        self.translatesAutoresizingMaskIntoConstraints = false

        let guide = self.layoutMarginsGuide

        self.plusAnimationView.translatesAutoresizingMaskIntoConstraints = false
        self.plusAnimationView.bottomAnchor.constraint(equalTo: self.textView.bottomAnchor).isActive = true
        self.plusAnimationView.heightAnchor.constraint(equalToConstant: 43).isActive = true
        self.plusAnimationView.widthAnchor.constraint(equalToConstant: 43).isActive = true
        self.plusAnimationView.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true

        self.inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        self.inputContainerView.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
        self.inputContainerView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -10).isActive = true

        let leadingConstant: CGFloat = self.shouldShowPlusButton() ? 53 : 0
        self.inputLeadingContstaint = self.inputContainerView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: leadingConstant)
        self.inputLeadingContstaint?.isActive = true
        self.inputContainerView.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true

        self.attachmentView.leadingAnchor.constraint(equalTo: self.inputContainerView.leadingAnchor).isActive = true
        self.attachmentView.trailingAnchor.constraint(equalTo: self.inputContainerView.trailingAnchor).isActive = true
        self.attachmentView.topAnchor.constraint(equalTo: self.inputContainerView.topAnchor).isActive = true
        self.attachmentHeightAnchor = NSLayoutConstraint(item: self.attachmentView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100)
        self.attachmentHeightAnchor?.isActive = true

        self.textView.leadingAnchor.constraint(equalTo: self.inputContainerView.leadingAnchor).isActive = true
        self.textView.trailingAnchor.constraint(equalTo: self.inputContainerView.trailingAnchor).isActive = true
        self.textView.topAnchor.constraint(equalTo: self.attachmentView.bottomAnchor).isActive = true
        self.textView.bottomAnchor.constraint(equalTo: self.inputContainerView.bottomAnchor).isActive = true
        self.textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }

    private func setupHandlers() {
        KeyboardManager.shared.$currentEvent
            .mainSink { event in
            switch event {
            case .didHide(_):
                self.textView.updateInputView(type: .keyboard, becomeFirstResponder: false)
                self.plusAnimationView.play(toProgress: 0.0)
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

        self.textView.textDidUpdate = { [unowned self] text in
            self.handleTextChange(text)
        }

        self.overlayButton.didSelect { [unowned self] in
            if !self.textView.isFirstResponder {
                if UserDefaultsManager.getValue(for: .hasShownKeyboardInstructions) {
                    self.textView.updateInputView(type: .keyboard, becomeFirstResponder: true)
                } else {
                    self.textView.updateInputView(type: .demo, becomeFirstResponder: true)

                }
            }
        }

        self.plusAnimationView.didSelect { [unowned self] in
            self.updateInputType()
        }

        self.textView.confirmationView.button.didSelect { [unowned self] in
            self.didPressAlertCancel()
        }

        self.attachmentView.$messageKind.mainSink { (kind) in
            self.attachentViewDidUpdate(kind: kind)
        }.store(in: &self.cancellables)
    }

    // MARK: OVERRIDES

    func shouldShowPlusButton() -> Bool {
        return true
    }

    func setupGestures() {
        let panRecognizer = UIPanGestureRecognizer { [unowned self] (recognizer) in
            self.handle(pan: recognizer)
        }
        panRecognizer.delegate = self
        self.overlayButton.addGestureRecognizer(panRecognizer)
    }

    func attachentViewDidUpdate(kind: MessageKind?) {
        self.attachmentHeightAnchor?.constant = kind.isNil ? 0 : 100
        self.layoutNow()
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
        self.attachmentView.alpha = 1
        self.attachmentView.configure(with: nil)
        self.attachmentView.messageKind = nil
        self.textView.countView.isHidden = true
    }

    func attachmentView(_ controller: AttachmentViewController, didSelect attachment: Attachment) {}

    // MARK: - Pan Gesture Handling

    private var previewView: PreviewMessageView?
    private var initialPreviewOrigin: CGPoint?

    func handle(pan: UIPanGestureRecognizer) {
        guard self.shouldHandlePan() else { return }

        // How far the preview view can be dragged left or right.
        let maxXOffset: CGFloat = 100
        // How far the preview view can be dragged vertically
        let maxYOffset: CGFloat = SwipeableInputAccessoryView.maxHeight.half
        let panOffset = pan.translation(in: nil)
        // The percentage of the max y offset that the preview view has been dragged.
        let progress = clamp(-panOffset.y/maxYOffset, 0, 1)

        switch pan.state {
        case .possible:
            break
        case .began:
            self.handlePanBegan()
        case .changed:
            self.handlePanChanged(withOffset: panOffset, maxXOffset: maxXOffset, maxYOffset: maxYOffset)
        case .ended:
            self.handlePanEnded(withProgress: progress)
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
        self.sendableObject = object

        self.attachmentView.alpha = 0
        self.textView.alpha = 0

        // Initialize the preview view for the user to drag up the screen.
        self.previewView = PreviewMessageView()
        self.previewView?.frame = self.inputContainerView.frame
        self.previewView?.set(backgroundColor: self.currentContext.color)
        self.previewView?.messageKind = self.currentMessageKind
        self.addSubview(self.previewView!)

        self.initialPreviewOrigin = self.previewView?.origin
    }

    private func handlePanChanged(withOffset offset: CGPoint, maxXOffset: CGFloat, maxYOffset: CGFloat) {
        guard let initialPosition = self.initialPreviewOrigin else { return }

        let offsetX = clamp(offset.x, -maxXOffset, maxXOffset)
        let offsetY = clamp(offset.y, -maxYOffset, 0)
        self.previewView?.origin = initialPosition + CGPoint(x: offsetX, y: offsetY)
    }

    private func handlePanEnded(withProgress progress: CGFloat) {
        let didFinish = progress > 0.5

        if didFinish {
            self.selectionFeedback.impactOccurred()
            self.previewView?.removeFromSuperview()

            if let object = self.sendableObject {
                self.delegate.swipeableInputAccessory(self, didConfirm: object)
                self.resetInputViews()
            }
        } else {
            guard let initialOrigin = self.initialPreviewOrigin else { return }

            // If the user didn't swipe far enough to send a message, then animate the preview view back
            // to where it started, then reveal the text view to allow input again.
            UIView.animate(withDuration: Theme.animationDuration) {
                if !didFinish {
                    self.previewView?.origin = initialOrigin
                    self.previewView?.set(backgroundColor: .clear)
                }
            } completion: { completed in
                self.textView.alpha = 1
                self.attachmentView.alpha = 1
                self.previewView?.removeFromSuperview()
            }
        }
    }

    private func handlePanFailed() {
        self.textView.alpha = 1
        self.attachmentView.alpha = 1
        self.previewView?.removeFromSuperview()
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

